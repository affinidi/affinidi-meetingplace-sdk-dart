import 'dart:async';

import 'mediator_session.dart';
import 'step_up.dart';
import 'step_up_approval_operation.dart';

enum VtaStepUpApprovalStatus { skipped, approved, rejected }

class VtaStepUpApprovalDecision {
  const VtaStepUpApprovalDecision({required this.approved, this.reason});

  final bool approved;
  final String? reason;
}

class VtaStepUpApprovalEvent {
  const VtaStepUpApprovalEvent({
    required this.status,
    required this.message,
    this.approveRequest,
    this.approvalResult,
    this.reason,
  });

  final VtaStepUpApprovalStatus status;
  final VtaDidCommMessage message;
  final Map<String, dynamic>? approveRequest;
  final VtaStepUpApprovalResult? approvalResult;
  final String? reason;
}

typedef VtaStepUpApproveRequestHandler =
    Future<VtaStepUpApprovalDecision> Function(
      Map<String, dynamic> approveRequest,
      VtaDidCommMessage message,
    );

class VtaStepUpApprovalCoordinator {
  VtaStepUpApprovalCoordinator({
    required this._mediatorSession,
    required this._onApproveRequest,
    this._approvalOperation,
  });

  final VtaMediatorSession _mediatorSession;
  final VtaStepUpApproveRequestHandler _onApproveRequest;
  final VtaStepUpApprovalOperation? _approvalOperation;

  final StreamController<VtaStepUpApprovalEvent> _events =
      StreamController<VtaStepUpApprovalEvent>.broadcast();

  Stream<VtaStepUpApprovalEvent> get events => _events.stream;

  bool _running = false;
  Future<void>? _loopTask;

  Future<void> start({
    Duration pollTimeout = const Duration(seconds: 30),
  }) async {
    if (_running) {
      return;
    }
    _running = true;
    _loopTask = _loop(pollTimeout: pollTimeout);
  }

  Future<void> stop() async {
    _running = false;
    await _loopTask;
    _loopTask = null;
  }

  Future<VtaStepUpApprovalEvent?> processOnce({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final message = await _mediatorSession.receiveNext(timeout: timeout);
    if (message == null) {
      return null;
    }

    final approveRequest = VtaDidCommStepUp.extractApproveRequestFromMessage(
      message.toJson(),
    );
    if (approveRequest == null) {
      final skipped = VtaStepUpApprovalEvent(
        status: VtaStepUpApprovalStatus.skipped,
        message: message,
      );
      _events.add(skipped);
      return skipped;
    }

    final decision = await _onApproveRequest(approveRequest, message);
    VtaStepUpApprovalResult? approvalResult;
    var status = decision.approved
        ? VtaStepUpApprovalStatus.approved
        : VtaStepUpApprovalStatus.rejected;
    var reason = decision.reason;

    if (decision.approved && _approvalOperation == null) {
      status = VtaStepUpApprovalStatus.rejected;
      reason =
          reason ??
          'No step-up approval operation is configured for trusted submit.';
    } else if (decision.approved) {
      approvalResult = await _approvalOperation!.approve(
        approveRequest: approveRequest,
      );
    }

    final event = VtaStepUpApprovalEvent(
      status: status,
      message: message,
      approveRequest: approveRequest,
      approvalResult: approvalResult,
      reason: reason,
    );
    _events.add(event);
    return event;
  }

  Future<void> dispose() async {
    await stop();
    await _events.close();
  }

  Future<void> _loop({required Duration pollTimeout}) async {
    while (_running) {
      await processOnce(timeout: pollTimeout);
    }
  }
}

import 'dart:async';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import 'model/vrc_issuance.dart';
import 'model/vrc_request.dart';
import 'parser/vrc_parser.dart';

/// Manages typed VRC receive streams sourced from routed VDIP messages.
class VrcVdipStreamManager {
  /// Creates a [VrcVdipStreamManager] that subscribes to
  /// [incomingVdipMessages] and routes VRC messages to the appropriate streams.
  VrcVdipStreamManager({
    required Stream<PlainTextMessage> incomingVdipMessages,
    required VrcParser parser,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _parser = parser,
       _logger = logger {
    _requestController = StreamController<VrcRequest>.broadcast();
    _receivedVrcController = StreamController<VrcIssuance>.broadcast();
    _requests = _requestController.stream;
    _receivedVrcs = _receivedVrcController.stream;
    _subscription = incomingVdipMessages.listen(
      (message) => unawaited(_handleMessage(message)),
      onError: _handleError,
    );
  }

  final VrcParser _parser;
  final MeetingPlaceCoreSDKLogger _logger;
  late final StreamController<VrcRequest> _requestController;
  late final StreamController<VrcIssuance> _receivedVrcController;
  late final StreamSubscription<PlainTextMessage> _subscription;
  late final Stream<VrcRequest> _requests;
  late final Stream<VrcIssuance> _receivedVrcs;
  bool _isClosed = false;

  // Pending caches: events dispatched before any listener was attached are
  // stored here so a late-subscribing chat session can replay them.
  final Map<String, VrcRequest> _pendingRequests = {};
  final Map<String, VrcIssuance> _pendingVrcs = {};

  /// Emits incoming VRC requests routed from VDIP request-issuance messages.
  Stream<VrcRequest> get requests => _requests;

  /// Emits incoming, parsed VRC issuances routed from VDIP issued credentials.
  Stream<VrcIssuance> get receivedVrcs => _receivedVrcs;

  /// Returns and removes the cached VRC request from [senderDid], or null.
  VrcRequest? consumePendingRequest(String senderDid) =>
      _pendingRequests.remove(senderDid);

  /// Returns and removes the cached received VRC from [senderDid], or null.
  VrcIssuance? consumePendingVrc(String senderDid) =>
      _pendingVrcs.remove(senderDid);

  /// Cancels the internal subscription and closes both VRC output streams.
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _subscription.cancel();
    await _requestController.close();
    await _receivedVrcController.close();
  }

  /// Routes each VDIP message to the VRC request or issuance flow.
  Future<void> _handleMessage(PlainTextMessage message) async {
    final senderDid = message.from;
    if (senderDid == null || senderDid.isEmpty) {
      _logger.warning('Skipping VRC message without sender DID');
      return;
    }

    if (message.type == VdipRequestIssuanceMessage.messageType) {
      final request = _toReceivedVrcRequest(message, senderDid);
      if (request != null) {
        _pendingRequests[senderDid] = request;
        if (!_isClosed) _requestController.add(request);
      }
      return;
    }

    if (message.type == VdipIssuedCredentialMessage.messageType) {
      final receivedVrc = await _toReceivedVrc(message, senderDid);
      if (receivedVrc != null) {
        _pendingVrcs[senderDid] = receivedVrc;
        if (!_isClosed) _receivedVrcController.add(receivedVrc);
      }
    }
  }

  /// Builds a typed VRC request from a request-issuance message.
  VrcRequest? _toReceivedVrcRequest(
    PlainTextMessage message,
    String senderDid,
  ) {
    final body = message.body;
    if (body is! Map) {
      _logger.warning('Skipping VRC request with invalid body payload');
      return null;
    }

    final bodyMap = Map<String, dynamic>.from(body as Map);
    final credentialMeta = bodyMap['credential_meta'];
    final credentialMetaMap = credentialMeta is Map
        ? Map<String, dynamic>.from(credentialMeta)
        : const <String, dynamic>{};
    final credentialMetaData = _extractCredentialMetaData(credentialMetaMap);
    final proposalId = bodyMap['proposal_id'];

    return VrcRequest(
      senderDid: senderDid,
      proposalId: proposalId is String ? proposalId : null,
      credentialMeta: credentialMetaMap,
      credentialMetaData: credentialMetaData,
    );
  }

  /// Builds a typed VRC issuance from an issued-credential message.
  Future<VrcIssuance?> _toReceivedVrc(
    PlainTextMessage message,
    String senderDid,
  ) async {
    final body = message.body;
    if (body is! Map) {
      _logger.warning('Skipping issued VRC with invalid body payload');
      return null;
    }

    final bodyMap = Map<String, dynamic>.from(body as Map);
    final vcBlob = bodyMap['credential'];
    if (vcBlob is! String || vcBlob.isEmpty) {
      _logger.warning('Skipping issued VRC with missing credential blob');
      return null;
    }

    final parsedCredential = await _parser.parse(vcBlob: vcBlob);
    if (parsedCredential == null) {
      return null;
    }

    final credentialFormat =
        bodyMap['credential_format'] ?? bodyMap['credentialFormat'];
    return VrcIssuance(
      senderDid: senderDid,
      vcBlob: vcBlob,
      parsedCredential: parsedCredential,
      credentialFormat: credentialFormat is String ? credentialFormat : null,
    );
  }

  /// Extracts the request metadata payload from the credential meta block.
  Map<String, dynamic> _extractCredentialMetaData(
    Map<String, dynamic> credentialMeta,
  ) {
    final data = credentialMeta['data'];
    if (data is! Map) return const <String, dynamic>{};
    return Map<String, dynamic>.from(data);
  }

  /// Forwards upstream stream errors to both VRC output streams.
  void _handleError(Object error, StackTrace stackTrace) {
    if (_isClosed) return;
    _requestController.addError(error, stackTrace);
    _receivedVrcController.addError(error, stackTrace);
  }
}

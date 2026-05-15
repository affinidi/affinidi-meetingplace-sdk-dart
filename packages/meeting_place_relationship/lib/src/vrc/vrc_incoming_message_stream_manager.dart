import 'dart:async';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import 'model/received_vrc.dart';
import 'model/received_vrc_request.dart';
import 'parser/vrc_parser.dart';

/// Manages typed VRC receive streams sourced from the VDIP incoming messages
/// stream of a [MeetingPlaceCoreSDK] instance.
class VrcIncomingMessageStreamManager {
  VrcIncomingMessageStreamManager({
    required Stream<PlainTextMessage> incomingMessages,
    required VrcParser parser,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _parser = parser,
       _logger = logger {
    _requestController = StreamController<ReceivedVrcRequest>.broadcast();
    _receivedVrcController = StreamController<ReceivedVrc>.broadcast();
    _requests = _requestController.stream;
    _receivedVrcs = _receivedVrcController.stream;
    _subscription = incomingMessages.listen(
      (message) => unawaited(_handleMessage(message)),
      onError: _handleError,
    );
  }

  final VrcParser _parser;
  final MeetingPlaceCoreSDKLogger _logger;
  late final StreamController<ReceivedVrcRequest> _requestController;
  late final StreamController<ReceivedVrc> _receivedVrcController;
  late final StreamSubscription<PlainTextMessage> _subscription;
  late final Stream<ReceivedVrcRequest> _requests;
  late final Stream<ReceivedVrc> _receivedVrcs;

  // Pending caches: events dispatched before any listener was attached are
  // stored here so a late-subscribing chat session can replay them.
  final Map<String, ReceivedVrcRequest> _pendingRequests = {};
  final Map<String, ReceivedVrc> _pendingVrcs = {};

  Stream<ReceivedVrcRequest> get requests => _requests;

  Stream<ReceivedVrc> get receivedVrcs => _receivedVrcs;

  /// Returns and removes the cached VRC request from [senderDid], or null.
  ReceivedVrcRequest? consumePendingRequest(String senderDid) =>
      _pendingRequests.remove(senderDid);

  /// Returns and removes the cached received VRC from [senderDid], or null.
  ReceivedVrc? consumePendingVrc(String senderDid) =>
      _pendingVrcs.remove(senderDid);

  Future<void> close() async {
    await _subscription.cancel();
    await _requestController.close();
    await _receivedVrcController.close();
  }

  Future<void> _handleMessage(PlainTextMessage message) async {
    final senderDid = message.from;
    if (senderDid == null || senderDid.isEmpty) {
      _logger.warning('Skipping VRC message without sender DID');
      return;
    }

    final type = message.type.toString();
    if (type == VdipRequestIssuanceMessage.messageType.toString()) {
      final request = _toReceivedVrcRequest(message, senderDid);
      if (request != null) {
        _pendingRequests[senderDid] = request;
        _requestController.add(request);
      }
      return;
    }

    if (type == VdipIssuedCredentialMessage.messageType.toString()) {
      final receivedVrc = await _toReceivedVrc(message, senderDid);
      if (receivedVrc != null) {
        _pendingVrcs[senderDid] = receivedVrc;
        _receivedVrcController.add(receivedVrc);
      }
    }
  }

  ReceivedVrcRequest? _toReceivedVrcRequest(
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

    return ReceivedVrcRequest(
      senderDid: senderDid,
      proposalId: proposalId is String ? proposalId : null,
      credentialMeta: credentialMetaMap,
      credentialMetaData: credentialMetaData,
    );
  }

  Future<ReceivedVrc?> _toReceivedVrc(
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
    return ReceivedVrc(
      senderDid: senderDid,
      vcBlob: vcBlob,
      parsedCredential: parsedCredential,
      credentialFormat: credentialFormat is String ? credentialFormat : null,
    );
  }

  Map<String, dynamic> _extractCredentialMetaData(
    Map<String, dynamic> credentialMeta,
  ) {
    final data = credentialMeta['data'];
    if (data is! Map) return const <String, dynamic>{};
    return Map<String, dynamic>.from(data);
  }

  void _handleError(Object error, StackTrace stackTrace) {
    _requestController.addError(error, stackTrace);
    _receivedVrcController.addError(error, stackTrace);
  }
}

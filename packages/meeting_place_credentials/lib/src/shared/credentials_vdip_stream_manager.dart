import 'dart:async';
import 'dart:convert';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../rcard/model/r_card_constants.dart';
import '../vrc/model/vrc_constants.dart';
import 'credential_sdk_constants.dart';

enum _CredentialType { rCard, vrc, unknown }

/// Routes raw VDIP messages to the credentials stream managers.
///
/// Request-issuance messages are forwarded to the VRC stream. Issued-
/// credential messages are classified once and then routed to the matching
/// credentials stream.
class CredentialsVdipStreamManager {
  /// Creates a [CredentialsVdipStreamManager] that subscribes to
  /// [incomingVdipMessages] and routes each message to the appropriate stream.
  CredentialsVdipStreamManager({
    required Stream<PlainTextMessage> incomingVdipMessages,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _logger = logger {
    _rCardController = StreamController<PlainTextMessage>.broadcast();
    _vrcController = StreamController<PlainTextMessage>.broadcast();
    _rCardMessages = _rCardController.stream;
    _vrcMessages = _vrcController.stream;
    _subscription = incomingVdipMessages.listen(
      (message) => unawaited(_routeMessage(message)),
      onError: _handleError,
    );
  }

  final MeetingPlaceCoreSDKLogger _logger;
  late final StreamController<PlainTextMessage> _rCardController;
  late final StreamController<PlainTextMessage> _vrcController;
  late final Stream<PlainTextMessage> _rCardMessages;
  late final Stream<PlainTextMessage> _vrcMessages;
  late final StreamSubscription<PlainTextMessage> _subscription;
  var _isClosed = false;

  /// Emits issued-credential messages classified as R-Cards.
  Stream<PlainTextMessage> get rCardMessages => _rCardMessages;

  /// Emits VDIP messages owned by the VRC flow.
  Stream<PlainTextMessage> get vrcMessages => _vrcMessages;

  /// Returns whether [message] is an issued-credential message for R-Cards.
  bool isRCardIssuedCredentialMessage(PlainTextMessage message) {
    if (message.type != VdipIssuedCredentialMessage.messageType) {
      return false;
    }

    final body = message.body;
    if (body is! Map) {
      return false;
    }

    final bodyMap = Map<String, dynamic>.from(body as Map);
    final vcBlob = bodyMap['credential'];
    if (vcBlob is! String || vcBlob.isEmpty) {
      return false;
    }

    return _classifyIssuedCredential(vcBlob) == _CredentialType.rCard;
  }

  /// Cancels the internal subscription and closes both routed output streams.
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;
    await _subscription.cancel();
    await _rCardController.close();
    await _vrcController.close();
  }

  /// Routes each incoming VDIP message to the owning credentials stream.
  Future<void> _routeMessage(PlainTextMessage message) async {
    if (_isClosed) return;

    if (message.type == VdipRequestIssuanceMessage.messageType) {
      _vrcController.add(message);
      return;
    }

    if (message.type != VdipIssuedCredentialMessage.messageType) {
      _logger.info(
        'Skipping VDIP message with unhandled type: ${message.type}',
      );
      return;
    }

    final body = message.body;
    if (body is! Map) {
      _logger.warning('Skipping issued credential with invalid body payload');
      return;
    }

    final bodyMap = Map<String, dynamic>.from(body as Map);
    final vcBlob = bodyMap['credential'];
    if (vcBlob is! String || vcBlob.isEmpty) {
      _logger.warning(
        'Skipping issued credential with missing credential blob',
      );
      return;
    }

    switch (_classifyIssuedCredential(vcBlob)) {
      case _CredentialType.rCard:
        _rCardController.add(message);
      case _CredentialType.vrc:
        _vrcController.add(message);
      case _CredentialType.unknown:
        _logger.info(
          'Skipping issued credential with unsupported credential type',
        );
    }
  }

  /// Classifies an issued credential by VC type and context.
  _CredentialType _classifyIssuedCredential(String vcBlob) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(vcBlob);
    } catch (_) {
      return _CredentialType.unknown;
    }

    if (decoded is! Map<String, dynamic>) {
      return _CredentialType.unknown;
    }

    final types = (decoded['type'] as List?)?.map((e) => e.toString()).toSet();
    final context = decoded['@context'];
    final contextList = context is List
        ? context.map((e) => e.toString()).toSet()
        : <String>{};

    final isVerifiableCredential =
        types?.contains(CredentialsSDKConstants.typeVerifiableCredential) ??
        false;
    if (!isVerifiableCredential) {
      return _CredentialType.unknown;
    }

    if (types!.contains(RCardConstants.typeRCard) &&
        contextList.contains(RCardConstants.contextRCard)) {
      return _CredentialType.rCard;
    }

    if (types.contains(VrcConstants.typeRelationshipCredential) &&
        contextList.contains(VrcConstants.contextVrc)) {
      return _CredentialType.vrc;
    }

    return _CredentialType.unknown;
  }

  /// Forwards upstream stream errors to both routed outputs.
  void _handleError(Object error, StackTrace stackTrace) {
    if (_isClosed) return;
    _rCardController.addError(error, stackTrace);
    _vrcController.addError(error, stackTrace);
  }
}

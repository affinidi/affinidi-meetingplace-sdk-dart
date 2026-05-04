import 'dart:async';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../shared/credential_sdk_constants.dart';
import 'model/r_card.dart';
import 'parser/r_card_parser.dart';

/// Manages the [RCard] broadcast stream sourced from
/// [VdipClient.incomingMessages].
///
/// Filters for [VdipIssuedCredentialMessage] messages, validates the
/// credential format, delegates parsing and signature verification to
/// [RCardParser], and forwards valid results to [stream].
class RCardVdipStreamManager {
  /// Creates an [RCardVdipStreamManager] that subscribes to
  /// [incomingVdipMessages] and forwards valid R-Cards to [stream].
  RCardVdipStreamManager({
    required Stream<PlainTextMessage> incomingVdipMessages,
    required RCardParser parser,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _parser = parser,
       _logger = logger {
    _controller = StreamController.broadcast();
    _stream = _controller.stream;
    _subscription = incomingVdipMessages
        .asyncExpand(_parseVdipMessage)
        .listen(_controller.add, onError: _controller.addError);
  }

  final RCardParser _parser;
  final MeetingPlaceCoreSDKLogger _logger;
  late final StreamController<RCard> _controller;
  late final StreamSubscription<RCard> _subscription;
  late final Stream<RCard> _stream;

  // Pending cache: R-Cards dispatched before any listener was attached are
  // stored here so a late-subscribing chat session can replay them.
  final Map<String, RCard> _pendingRCards = {};

  /// Emits incoming, parsed R-Cards routed from VDIP issued credentials.
  Stream<RCard> get stream => _stream;

  /// Returns and removes the cached R-Card from [senderDid], or null.
  RCard? consumePendingRCard(String senderDid) =>
      _pendingRCards.remove(senderDid);

  /// Cancels the internal subscription and closes the R-Card output stream.
  Future<void> close() async {
    if (_controller.isClosed) return;
    await _subscription.cancel();
    await _controller.close();
  }

  /// Processes a single [message] using the same parse logic as [stream].
  ///
  /// Returns the parsed [RCard] if [message] is a valid
  /// `vdip-issued-credentials` R-Card, or `null` otherwise.
  ///
  /// Used by `MeetingPlaceCredentialsSDK` as a `VdipClient` message
  /// processor to guarantee R-Card persistence regardless of whether
  /// [stream] has an active subscriber at dispatch time.
  Future<RCard?> processMessage(PlainTextMessage message) async {
    await for (final rCard in _parseVdipMessage(message)) {
      return rCard;
    }
    return null;
  }

  /// Parses one VDIP issued-credential message into an [RCard].
  Stream<RCard> _parseVdipMessage(PlainTextMessage message) async* {
    if (message.type != VdipIssuedCredentialMessage.messageType) return;

    final body = message.body;
    if (body == null) {
      _logger.warning('VDIP issued-credential body is missing');
      return;
    }

    final credential = body['credential'];
    if (credential is! String) {
      _logger.warning(
        'VDIP issued-credential body has no String credential field',
      );
      return;
    }

    final rawFormat = body['credential_format'];
    final format = rawFormat is String ? rawFormat : null;
    if (format != null &&
        !CredentialsSDKConstants.supportedFormats.contains(format)) {
      _logger.warning('Unsupported VDIP credential format: $format');
      return;
    }

    final from = message.from;
    if (from == null || from.isEmpty) {
      yield* Stream.error(
        const FormatException(
          'Received VDIP R-Card with missing sender DID (from)',
        ),
      );
      return;
    }

    final rCard = await _parser.parse(vcBlob: credential);
    if (rCard != null) {
      _pendingRCards[from] = rCard;
      yield rCard;
    } else {
      yield* Stream.error(
        const FormatException(
          'Failed to parse VDIP R-Card from credential blob',
        ),
      );
    }
  }
}

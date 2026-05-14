import 'dart:async';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../shared/credential_constants.dart';
import 'model/received_r_card.dart';
import 'parser/r_card_parser.dart';

/// Manages the [ReceivedRCard] broadcast stream sourced from
/// [VdipClient.incomingMessages].
///
/// Filters for [VdipIssuedCredentialMessage] messages, validates the
/// credential format, delegates parsing and signature verification to
/// [RCardParser], and forwards valid results to [stream].
class RCardVdipStreamManager {
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
  late final StreamController<ReceivedRCard> _controller;
  late final StreamSubscription<ReceivedRCard> _subscription;
  late final Stream<ReceivedRCard> _stream;

  /// Emits a [ReceivedRCard] for every valid, signature-verified R-Card
  /// delivered via VDIP issued-credential message.
  Stream<ReceivedRCard> get stream => _stream;

  /// Cancels the internal subscription and closes [stream].
  ///
  /// Safe to call more than once — subsequent calls are no-ops.
  Future<void> close() async {
    if (_controller.isClosed) return;
    await _subscription.cancel();
    await _controller.close();
  }

  Stream<ReceivedRCard> _parseVdipMessage(PlainTextMessage message) async* {
    if (message.type != VdipIssuedCredentialMessage.messageType) return;

    final body = message.body;
    if (body == null) return;

    final credential = body['credential'];
    if (credential is! String) {
      _logger.warning(
        'VDIP issued-credential body has no String credential field',
      );
      return;
    }

    final format = body['credential_format'] as String?;
    if (format != null &&
        !RelationshipCredentialConstants.supportedFormats.contains(format)) {
      _logger.warning('Unsupported VDIP credential format: $format');
      return;
    }

    final from = message.from;
    if (from == null || from.isEmpty) {
      _logger.warning('Skipping VDIP R-Card: missing sender DID (from field)');
      return;
    }

    final rCard = await _parser.parse(
      vcBlob: credential,
      contactChannelDid: from,
    );
    if (rCard != null) yield rCard;
  }
}

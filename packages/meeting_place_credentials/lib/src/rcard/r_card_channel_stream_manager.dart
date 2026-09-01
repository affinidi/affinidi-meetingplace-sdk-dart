import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import 'builder/r_card_didcomm_attachment_builder.dart';
import 'model/channel_r_card_event.dart';
import 'model/r_card_rejection.dart';
import 'parser/r_card_parser.dart';

/// Manages the [ChannelRCardEvent] broadcast stream sourced from
/// [MeetingPlaceCoreSDK.channelAttachments].
///
/// Extracts R-Card VC blobs from incoming DIDComm attachments, delegates
/// parsing and verification to [RCardParser], and forwards valid results to
/// the [stream]. Attachments that fail parsing, verification, or
/// issuer/counterparty binding are surfaced on [rejections] instead.
class RCardChannelStreamManager {
  /// Creates an [RCardChannelStreamManager] that subscribes to
  /// [channelAttachments] and forwards valid R-Cards to [stream].
  RCardChannelStreamManager({
    required Stream<ChannelAttachmentEvent> channelAttachments,
    required RCardParser parser,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _parser = parser,
       _logger = logger {
    _controller = StreamController.broadcast();
    _stream = _controller.stream;
    _rejectionController = StreamController.broadcast();
    _rejectionStream = _rejectionController.stream;
    _subscription = channelAttachments
        .asyncExpand(_parseChannelEvent)
        .listen(_controller.add, onError: _controller.addError);
  }

  final RCardParser _parser;
  final MeetingPlaceCoreSDKLogger _logger;
  late final StreamController<ChannelRCardEvent> _controller;
  late final StreamSubscription<ChannelRCardEvent> _subscription;
  late final Stream<ChannelRCardEvent> _stream;
  late final StreamController<RCardRejection> _rejectionController;
  late final Stream<RCardRejection> _rejectionStream;

  /// Emits a [ChannelRCardEvent] for every valid, signature-verified R-Card
  /// attachment received over any channel.
  ///
  /// The [ChannelRCardEvent.channel] carries context such as
  /// [Channel.permanentChannelDid] and
  /// [Channel.otherPartyPermanentChannelDid] that callers can use to correlate
  /// the R-Card to the originating conversation.
  Stream<ChannelRCardEvent> get stream => _stream;

  /// Emits an [RCardRejection] for every R-Card-shaped attachment that was
  /// received but rejected — malformed payload, failed verification, or an
  /// issuer that did not match the channel counterparty.
  Stream<RCardRejection> get rejections => _rejectionStream;

  /// Cancels the internal subscription and closes [stream] and [rejections].
  ///
  /// Safe to call more than once — subsequent calls are no-ops.
  Future<void> close() async {
    if (_controller.isClosed) return;
    await _subscription.cancel();
    await _controller.close();
    await _rejectionController.close();
  }

  Stream<ChannelRCardEvent> _parseChannelEvent(
    ChannelAttachmentEvent event,
  ) async* {
    final channel = event.channel;
    final attachments = event.attachments;
    final contactChannelDid = channel.otherPartyPermanentChannelDid;
    if (contactChannelDid == null || contactChannelDid.isEmpty) {
      _logger.warning(
        'Skipping R-Card parse: otherPartyPermanentChannelDid is null or empty',
      );
      return;
    }
    for (final attachment in attachments) {
      if (attachment.format != RCardDIDCommAttachmentBuilder.attachmentFormat) {
        continue;
      }
      final vcBlob = _extractVcBlob(attachment);
      if (vcBlob == null) {
        _rejectionController.add(
          RCardRejection(
            reason: RCardRejectionReason.malformedAttachment,
            source: RCardRejectionSource.channel,
          ),
        );
        continue;
      }
      final result = await _parser.parse(vcBlob: vcBlob);
      if (result is! RCardParseSuccess) {
        _rejectionController.add(
          RCardRejection(
            reason: result is RCardParseFailure
                ? result.reason
                : RCardRejectionReason.verificationError,
            source: RCardRejectionSource.channel,
          ),
        );
        _controller.addError(
          FormatException(
            'Failed to parse R-Card from attachment '
            '(vcBlob length=${vcBlob.length})',
          ),
        );
        continue;
      }
      final rCard = result.rCard;
      if (rCard.issuerDid != contactChannelDid) {
        _logger.warning(
          'R-Card issuerDid (${rCard.issuerDid}) does not match channel '
          'counterparty ($contactChannelDid) — discarding to prevent '
          'relay/replay.',
        );
        _rejectionController.add(
          RCardRejection(
            reason: RCardRejectionReason.issuerMismatch,
            source: RCardRejectionSource.channel,
            rCardIssuerDid: rCard.issuerDid,
            expectedDid: contactChannelDid,
          ),
        );
        continue;
      }
      yield ChannelRCardEvent(channel: channel, rCard: rCard);
    }
  }

  static String? _extractVcBlob(Attachment attachment) {
    final rawJson = attachment.data?.json;
    if (rawJson == null) return null;
    try {
      final payload = jsonDecode(rawJson);
      if (payload is! Map) return null;
      final vcBlob = payload['vcBlob'];
      return vcBlob is String ? vcBlob : null;
    } catch (_) {
      return null;
    }
  }
}

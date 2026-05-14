import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import 'builder/r_card_didcomm_attachment_builder.dart';
import 'model/received_r_card.dart';
import 'parser/r_card_parser.dart';

/// Manages the [ReceivedRCard] broadcast stream sourced from
/// [MeetingPlaceCoreSDK.channelAttachments].
///
/// Extracts R-Card VC blobs from incoming DIDComm attachments, delegates
/// parsing and verification to [RCardParser], and forwards valid results to
/// the [stream].
class RCardChannelStreamManager {
  RCardChannelStreamManager({
    required Stream<(Channel, List<Attachment>)> channelAttachments,
    required RCardParser parser,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _parser = parser,
       _logger = logger {
    _controller = StreamController.broadcast();
    _stream = _controller.stream;
    _subscription = channelAttachments
        .asyncExpand(_parseChannelEvent)
        .listen(_controller.add, onError: _controller.addError);
  }

  final RCardParser _parser;
  final MeetingPlaceCoreSDKLogger _logger;
  late final StreamController<ReceivedRCard> _controller;
  late final StreamSubscription<ReceivedRCard> _subscription;
  late final Stream<ReceivedRCard> _stream;

  /// Emits a [ReceivedRCard] for every valid, signature-verified R-Card
  /// attachment received over any channel.
  Stream<ReceivedRCard> get stream => _stream;

  /// Cancels the internal subscription and closes [stream].
  ///
  /// Safe to call more than once — subsequent calls are no-ops.
  Future<void> close() async {
    if (_controller.isClosed) return;
    await _subscription.cancel();
    await _controller.close();
  }

  Stream<ReceivedRCard> _parseChannelEvent(
    (Channel, List<Attachment>) record,
  ) async* {
    final (channel, attachments) = record;
    final contactChannelDid = channel.otherPartyPermanentChannelDid;
    if (contactChannelDid == null || contactChannelDid.isEmpty) {
      _logger.warning(
        'Skipping R-Card parse: otherPartyPermanentChannelDid is null or empty',
      );
      return;
    }
    final localChannelDid = channel.permanentChannelDid;
    for (final attachment in attachments) {
      final vcBlob = _extractVcBlob(attachment);
      if (vcBlob == null) continue;
      final rCard = await _parser.parse(
        vcBlob: vcBlob,
        contactChannelDid: contactChannelDid,
      );
      if (rCard != null) {
        yield (localChannelDid != null && localChannelDid.isNotEmpty)
            ? rCard.copyWith(localChannelDid: localChannelDid)
            : rCard;
      }
    }
  }

  static String? _extractVcBlob(Attachment attachment) {
    if (attachment.format != RCardDIDCommAttachmentBuilder.attachmentFormat) {
      return null;
    }
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

import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import 'builder/r_card_didcomm_attachment_builder.dart';
import 'model/channel_r_card_event.dart';
import 'parser/r_card_parser.dart';

/// Manages the [ChannelRCardEvent] broadcast stream sourced from
/// [MeetingPlaceCoreSDK.channelAttachments].
///
/// Extracts R-Card VC blobs from incoming DIDComm attachments, delegates
/// parsing and verification to [RCardParser], and forwards valid results to
/// the [stream].
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
    _subscription = channelAttachments
        .asyncExpand(_parseChannelEvent)
        .listen(_controller.add, onError: _controller.addError);
  }

  final RCardParser _parser;
  final MeetingPlaceCoreSDKLogger _logger;
  late final StreamController<ChannelRCardEvent> _controller;
  late final StreamSubscription<ChannelRCardEvent> _subscription;
  late final Stream<ChannelRCardEvent> _stream;

  /// Emits a [ChannelRCardEvent] for every valid, signature-verified R-Card
  /// attachment received over any channel.
  ///
  /// The [ChannelRCardEvent.channel] carries context such as
  /// [Channel.permanentChannelDid] and
  /// [Channel.otherPartyPermanentChannelDid] that callers can use to correlate
  /// the R-Card to the originating conversation.
  Stream<ChannelRCardEvent> get stream => _stream;

  /// Cancels the internal subscription and closes [stream].
  ///
  /// Safe to call more than once — subsequent calls are no-ops.
  Future<void> close() async {
    if (_controller.isClosed) return;
    await _subscription.cancel();
    await _controller.close();
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
      final vcBlob = _extractVcBlob(attachment);
      if (vcBlob == null) continue;
      final rCard = await _parser.parse(vcBlob: vcBlob);
      if (rCard != null) {
        yield ChannelRCardEvent(channel: channel, rCard: rCard);
      } else {
        _controller.addError(
          FormatException(
            'Failed to parse R-Card from attachment '
            '(vcBlob length=${vcBlob.length})',
          ),
        );
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

import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';

import 'builder/r_card_didcomm_attachment_builder.dart';
import 'model/r_card.dart';
import 'parser/r_card_parser.dart';

/// Manages the [RCard] broadcast stream sourced from
/// [MeetingPlaceCoreSDK.channelAttachments].
///
/// Extracts R-Card VC blobs from incoming DIDComm attachments, delegates
/// parsing and verification to [RCardParser], and forwards valid results to
/// the [stream].
class RCardChannelStreamManager {
  RCardChannelStreamManager({
    required Stream<(Channel, List<Attachment>)> channelAttachments,
    required RCardParser parser,
  }) : _parser = parser {
    _controller = StreamController.broadcast();
    _stream = _controller.stream;
    _subscription = channelAttachments
        .asyncExpand(_parseChannelEvent)
        .listen(_controller.add, onError: _controller.addError);
  }

  final RCardParser _parser;
  late final StreamController<RCard> _controller;
  late final StreamSubscription<RCard> _subscription;
  late final Stream<RCard> _stream;

  /// Emits a [RCard] for every valid, signature-verified R-Card
  /// attachment received over any channel.
  Stream<RCard> get stream => _stream;

  /// Cancels the internal subscription and closes [stream].
  ///
  /// Safe to call more than once — subsequent calls are no-ops.
  Future<void> close() async {
    if (_controller.isClosed) return;
    await _subscription.cancel();
    await _controller.close();
  }

  Stream<RCard> _parseChannelEvent((Channel, List<Attachment>) record) async* {
    final (_, attachments) = record;
    for (final attachment in attachments) {
      final vcBlob = _extractVcBlob(attachment);
      if (vcBlob == null) continue;
      final rCard = await _parser.parse(vcBlob: vcBlob);
      if (rCard != null) {
        yield rCard;
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

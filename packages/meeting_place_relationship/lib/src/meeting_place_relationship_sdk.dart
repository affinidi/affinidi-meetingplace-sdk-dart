import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'builders/r_card_didcomm_attachment_builder.dart';
import 'models/r_card/received_r_card.dart';
import 'parsers/r_card_attachment_parser.dart';
import 'parsers/vrc_parser.dart';

/// The Meeting Place Relationship SDK.
///
/// Provides typed, high-level access to R-Card and VRC exchange flows on
/// top of `MeetingPlaceCoreSDK`. Constructed once per session and
/// injected wherever relationship features are needed.
///
/// Example:
/// ```dart
/// final coreSDK = await MeetingPlaceCoreSDK.create(...);
/// final relationshipSDK = MeetingPlaceRelationshipSDK(coreSDK: coreSDK);
///
/// relationshipSDK.receivedRCards.listen((rCard) {
///   repository.upsert(rCard);
/// });
/// ```
class MeetingPlaceRelationshipSDK {
  /// Creates a `MeetingPlaceRelationshipSDK` backed by the given [coreSDK].
  ///
  /// The SDK subscribes to [MeetingPlaceCoreSDK.channelAttachments] eagerly
  /// at construction time so no attachment events are missed, regardless of
  /// when consumers first access [receivedRCards].
  MeetingPlaceRelationshipSDK({
    required MeetingPlaceCoreSDK coreSDK,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className) {
    _parser = RCardAttachmentParser(logger: _logger);
    _vrcParser = VrcParser(logger: _logger);
    _receivedRCardsController = StreamController.broadcast();
    _receivedRCards = _receivedRCardsController.stream;
    _channelAttachmentsSubscription = coreSDK.channelAttachments
        .asyncExpand(_parseRCardFromChannelEvent)
        .listen(
          _receivedRCardsController.add,
          onError: _receivedRCardsController.addError,
        );
  }

  static const _className = 'MeetingPlaceRelationshipSDK';

  late final StreamController<ReceivedRCard> _receivedRCardsController;
  late final Stream<ReceivedRCard> _receivedRCards;
  late final StreamSubscription<ReceivedRCard> _channelAttachmentsSubscription;
  late final RCardAttachmentParser _parser;
  late final VrcParser _vrcParser;
  final MeetingPlaceCoreSDKLogger _logger;

  /// A broadcast stream that emits a [ReceivedRCard] whenever a valid
  /// R-Card attachment arrives via connection establishment or chat.
  ///
  /// Only fully valid, signature-verified R-Cards are emitted.
  Stream<ReceivedRCard> get receivedRCards => _receivedRCards;

  /// Cancels the internal subscription and closes the [receivedRCards] stream.
  ///
  /// Call this when the SDK is no longer needed (e.g. on sign-out).
  Future<void> closeRelationshipStreams() async {
    await _channelAttachmentsSubscription.cancel();
    await _receivedRCardsController.close();
  }

  /// Parses the first valid R-Card from a list of DIDComm [attachments].
  ///
  /// Use this when handling R-Cards received as chat message attachments.
  /// Returns `null` if no valid, signature-verified R-Card is found.
  ///
  /// - [attachments] — attachments from an incoming chat message.
  /// - [contactChannelDid] — the other party's permanent channel DID.
  Future<ReceivedRCard?> parseRCardFromAttachments({
    required List<Attachment> attachments,
    required String contactChannelDid,
  }) async {
    for (final attachment in attachments) {
      final vcBlob = _extractRCardVcBlob(attachment);
      if (vcBlob == null) continue;
      final rCard = await _parser.parse(
        vcBlob: vcBlob,
        contactChannelDid: contactChannelDid.isEmpty ? null : contactChannelDid,
      );
      if (rCard != null) return rCard;
    }
    return null;
  }

  /// Parses and validates a VRC from a raw VC blob string.
  ///
  /// Returns `null` if the blob is not a valid, signature-verified VRC.
  ///
  /// - [vcBlob] — the raw serialised VC JSON string.
  Future<ParsedVerifiableCredential?> parseVrc({required String vcBlob}) {
    return _vrcParser.parse(vcBlob: vcBlob);
  }

  Stream<ReceivedRCard> _parseRCardFromChannelEvent(
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
    for (final attachment in attachments) {
      final vcBlob = _extractRCardVcBlob(attachment);
      if (vcBlob == null) continue;
      final rCard = await _parser.parse(
        vcBlob: vcBlob,
        contactChannelDid: contactChannelDid,
      );
      if (rCard != null) yield rCard;
    }
  }

  static String? _extractRCardVcBlob(Attachment attachment) {
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

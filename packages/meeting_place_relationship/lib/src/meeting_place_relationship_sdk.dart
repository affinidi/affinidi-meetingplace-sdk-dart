import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'builders/r_card_didcomm_attachment_builder.dart';
import 'models/r_card/r_card_constants.dart';
import 'models/r_card/received_r_card.dart';
import 'models/vrc/relationship_credential.dart';
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
/// relationshipSDK.incomingRCards.listen((rCard) {
///   repository.upsert(rCard);
/// });
/// ```
class MeetingPlaceRelationshipSDK {
  /// Creates a `MeetingPlaceRelationshipSDK` backed by the given [coreSDK].
  ///
  /// The SDK subscribes to [MeetingPlaceCoreSDK.channelAttachments] eagerly
  /// at construction time so no attachment events are missed, regardless of
  /// when consumers first access [incomingRCards].
  MeetingPlaceRelationshipSDK({
    required MeetingPlaceCoreSDK coreSDK,
    MeetingPlaceCoreSDKLogger? logger,
  }) : _logger =
           logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className) {
    _incomingRCardsController = StreamController.broadcast();
    _incomingRCards = _incomingRCardsController.stream;
    _channelAttachmentsSubscription = coreSDK.channelAttachments
        .asyncExpand(_parseRCardFromChannelEvent)
        .listen(
          _incomingRCardsController.add,
          onError: _incomingRCardsController.addError,
        );
  }

  static const _className = 'MeetingPlaceRelationshipSDK';

  late final StreamController<ReceivedRCard> _incomingRCardsController;
  late final Stream<ReceivedRCard> _incomingRCards;
  late final StreamSubscription<ReceivedRCard> _channelAttachmentsSubscription;
  final MeetingPlaceCoreSDKLogger _logger;

  /// A broadcast stream that emits a [ReceivedRCard] whenever a valid
  /// R-Card attachment arrives via connection establishment or chat.
  ///
  /// Only fully valid, signature-verified R-Cards are emitted.
  Stream<ReceivedRCard> get incomingRCards => _incomingRCards;

  /// Cancels the internal subscription and closes the [incomingRCards] stream.
  ///
  /// Call this when the SDK is no longer needed (e.g. on sign-out).
  Future<void> closeRelationshipStreams() async {
    await _channelAttachmentsSubscription.cancel();
    await _incomingRCardsController.close();
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
    final did = contactChannelDid.isEmpty ? null : contactChannelDid;
    for (final attachment in attachments) {
      final rCard = await _tryParseRCardAttachment(attachment, did);
      if (rCard != null) return rCard;
    }
    return null;
  }

  /// Parses and verifies a raw VRC blob received over VDIP.
  ///
  /// Returns `null` if the blob is not a valid, signature-verified VRC.
  ///
  /// - [vcBlob] — the raw serialised VC string from the VDIP response.
  /// - [channelId] — the channel through which the credential was received.
  Future<RelationshipCredential?> parseVrc({
    required String vcBlob,
    required String channelId,
  }) {
    return VrcParser.parse(vcBlob: vcBlob, channelId: channelId);
  }

  Stream<ReceivedRCard> _parseRCardFromChannelEvent(
    (Channel, List<Attachment>) record,
  ) async* {
    final (channel, attachments) = record;
    final contactChannelDid = channel.otherPartyPermanentChannelDid;
    for (final attachment in attachments) {
      final rCard = await _tryParseRCardAttachment(
        attachment,
        contactChannelDid,
      );
      if (rCard != null) yield rCard;
    }
  }

  Future<ReceivedRCard?> _tryParseRCardAttachment(
    Attachment attachment,
    String? contactChannelDid,
  ) async {
    if (attachment.format != RCardDIDCommAttachmentBuilder.attachmentFormat) {
      return null;
    }
    if (attachment.mediaType != 'application/json') return null;
    final raw = attachment.data?.json;
    if (raw == null) return null;
    try {
      final outer = jsonDecode(raw) as Map<String, dynamic>;
      final vcBlob = outer['vcBlob'] as String?;
      if (vcBlob == null || vcBlob.isEmpty) return null;

      final ParsedVerifiableCredential parsed;
      try {
        parsed = UniversalParser.parse(vcBlob);
      } catch (_) {
        return null;
      }

      final verification = await UniversalVerifier().verify(parsed);
      if (!verification.isValid) return null;

      final vcJson = jsonDecode(vcBlob) as Map<String, dynamic>;
      final issuerRaw = vcJson['issuer'];
      final issuerDid = issuerRaw is String
          ? issuerRaw
          : (issuerRaw is Map && issuerRaw['id'] != null)
          ? issuerRaw['id'].toString()
          : null;
      if (issuerDid == null || issuerDid.isEmpty) return null;

      final subjectRaw = vcJson['credentialSubject'];
      final subjectDid = subjectRaw is Map
          ? (subjectRaw['id'] as String? ?? issuerDid)
          : issuerDid;

      final now = DateTime.now().toUtc();
      return ReceivedRCard(
        subjectDid: subjectDid,
        vcBlob: vcBlob,
        issuerDid: issuerDid,
        version: RCardConstants.receivedRCardVersion,
        issuanceDate: parsed.validFrom?.toUtc() ?? now,
        receivedAt: now,
        contactChannelDid: (contactChannelDid?.isEmpty ?? true)
            ? null
            : contactChannelDid,
      );
    } catch (e, st) {
      _logger.error(
        'Failed to parse R-Card attachment',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }
}

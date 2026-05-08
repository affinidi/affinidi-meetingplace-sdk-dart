import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'models/credential_constants.dart';
import 'models/r_card/received_r_card.dart';
import 'models/vrc/vrc_constants.dart';
import 'parsers/r_card_attachment_parser.dart';

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
    _parser = RCardAttachmentParser(logger: _logger);
    _incomingRCardsController = StreamController.broadcast();
    _incomingRCards = _incomingRCardsController.stream;
    _channelAttachmentsSubscription = coreSDK.channelAttachments
        .asyncExpand(_parseRCard)
        .listen(
          _incomingRCardsController.add,
          onError: _incomingRCardsController.addError,
        );
  }

  static const _className = 'MeetingPlaceRelationshipSDK';

  late final StreamController<ReceivedRCard> _incomingRCardsController;
  late final Stream<ReceivedRCard> _incomingRCards;
  late final StreamSubscription<ReceivedRCard> _channelAttachmentsSubscription;
  late final RCardAttachmentParser _parser;
  final MeetingPlaceCoreSDKLogger _logger;

  /// Cancels the internal subscription and closes the [incomingRCards] stream.
  ///
  /// Call this when the SDK is no longer needed (e.g. on sign-out).
  Future<void> closeRelationshipStreams() async {
    await _channelAttachmentsSubscription.cancel();
    await _incomingRCardsController.close();
  }

  Stream<ReceivedRCard> _parseRCard((Channel, List<Attachment>) record) async* {
    final (channel, attachments) = record;
    final rCard = await _parser.parseFirst(
      attachments: attachments,
      contactChannelDid: channel.otherPartyPermanentChannelDid ?? '',
    );
    if (rCard != null) yield rCard;
  }

  /// A broadcast stream that emits a [ReceivedRCard] whenever a valid
  /// R-Card attachment arrives via connection establishment or chat.
  ///
  /// Only fully valid, signature-verified R-Cards are emitted.
  Stream<ReceivedRCard> get incomingRCards => _incomingRCards;

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
  }) {
    return _parser.parseFirst(
      attachments: attachments,
      contactChannelDid: contactChannelDid,
    );
  }

  /// Parses and validates a VRC from a raw VC blob string.
  ///
  /// Returns `null` if the blob is not a valid, signature-verified VRC.
  ///
  /// - [vcBlob] — the raw serialised VC JSON string.
  /// - [channelId] — the channel through which the VRC was received.
  Future<ParsedVerifiableCredential?> parseVrc({
    required String vcBlob,
    required String channelId,
  }) async {
    if (vcBlob.isEmpty) return null;
    try {
      final decoded = jsonDecode(vcBlob) as Map<String, dynamic>;
      final types = (decoded['type'] as List?)?.cast<String>() ?? [];
      if (!types.contains(VrcConstants.typeRelationshipCredential) ||
          !types.contains(
            RelationshipCredentialConstants.typeVerifiableCredential,
          )) {
        return null;
      }
      if (!decoded.containsKey('proof')) return null;
      final parsed = UniversalParser.parse(vcBlob);
      final verification = await UniversalVerifier().verify(parsed);
      if (!verification.isValid) return null;
      return parsed;
    } catch (e, st) {
      _logger.error('Failed to parse VRC blob', error: e, stackTrace: st);
      return null;
    }
  }
}

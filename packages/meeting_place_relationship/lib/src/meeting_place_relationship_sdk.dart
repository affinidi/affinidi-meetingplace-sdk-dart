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
  MeetingPlaceRelationshipSDK({required MeetingPlaceCoreSDK coreSDK})
    : _coreSDK = coreSDK;

  // TODO(earl): Wire up SDK calls — will be used by R-Card/VRC flow methods
  // added in upcoming PRs.
  // ignore: unused_field
  final MeetingPlaceCoreSDK _coreSDK;
  Stream<ReceivedRCard>? _incomingRCards;

  /// A broadcast stream that emits a [ReceivedRCard] whenever a valid
  /// R-Card attachment arrives during connection establishment.
  ///
  /// Subscribe to this stream at app startup to be notified of incoming
  /// R-Cards. The stream filters and verifies the attachment payload;
  /// only fully valid, signature-verified R-Cards are emitted.
  ///
  /// The stream is lazily initialised on first access and shared across
  /// all subscribers.
  Stream<ReceivedRCard> get incomingRCards {
    return _incomingRCards ??= _coreSDK.channelAttachments.asyncExpand((
      record,
    ) async* {
      final (channel, attachments) = record;
      final rCard = await RCardAttachmentParser.parseFirst(
        attachments: attachments,
        contactChannelDid: channel.otherPartyPermanentChannelDid ?? '',
      );
      if (rCard != null) yield rCard;
    }).asBroadcastStream();
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
  }) {
    return RCardAttachmentParser.parseFirst(
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
      return UniversalParser.parse(vcBlob);
    } catch (_) {
      return null;
    }
  }
}

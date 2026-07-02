import 'dart:convert';
import 'dart:typed_data';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import '../../../matrix_outgoing_message.dart';

import '../matrix_chat_event_type.dart';

/// Sends a group-details-update event with contact cards uploaded as
/// downloadable media files.
///
/// Each member's contact card is uploaded as a JSON file via
/// [MeetingPlaceCoreSDK.sendMediaMessage]. The resulting event IDs are
/// collected into a `contact_card_event_ids` map (keyed by member DID)
/// and included in the main group-details-update event content. Receivers
/// download contact cards from those event IDs.
class GroupDetailsUpdateSender {
  GroupDetailsUpdateSender({required MeetingPlaceCoreSDK coreSDK})
    : _coreSDK = coreSDK;

  final MeetingPlaceCoreSDK _coreSDK;

  static const contactCardEventIdsKey = 'contact_card_event_ids';
  static const memberDidKey = 'mp_member_did';

  Future<void> send({
    required Channel channel,
    required String senderDid,
    required Group group,
  }) async {
    final contactCardEventIds = <String, String>{};

    for (final member in group.members) {
      final cardBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(member.contactCard.toJson())),
      );
      final eventId = await _coreSDK.sendMediaMessage(
        channel,
        cardBytes,
        contentType: 'application/json',
        filename: 'contact-card.json',
        extraContent: {memberDidKey: member.did},
      );
      if (eventId != null) {
        contactCardEventIds[member.did] = eventId;
      }
    }

    final update = ChatGroupDetailsUpdate.fromGroup(
      group,
      senderDid: senderDid,
    );
    final content = update.body.toJson();
    content[contactCardEventIdsKey] = contactCardEventIds;

    await _coreSDK.sendMessage(
      _GroupDetailsUpdateWithAttachments(
        senderDid: senderDid,
        content: content,
      ),
    );
  }
}

class _GroupDetailsUpdateWithAttachments extends MatrixOutgoingMessage {
  _GroupDetailsUpdateWithAttachments({
    required super.senderDid,
    required super.content,
  }) : super(type: MatrixChatEventType.groupDetailsUpdate);
}

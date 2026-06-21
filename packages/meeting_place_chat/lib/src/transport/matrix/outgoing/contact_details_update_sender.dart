import 'dart:convert';
import 'dart:typed_data';

import 'package:meeting_place_core/meeting_place_core.dart';

import '../matrix_chat_event_type.dart';
import 'group_details_update_sender.dart';

/// Sends a contact-details-update event with the contact card uploaded as a
/// downloadable media file.
///
/// The card is uploaded via [MeetingPlaceCoreSDK.sendMediaMessage] and the
/// resulting event ID is included in the main event content under
/// [contactCardEventIdKey]. Receivers download the card from that event ID.
///
/// Falls back to inlining [ContactCard.toJson] in `profileDetails` when the
/// media upload does not return an event ID.
class ContactDetailsUpdateSender {
  ContactDetailsUpdateSender({
    required MeetingPlaceCoreSDK coreSDK,
    required Future<Channel> Function() getChannel,
  }) : _coreSDK = coreSDK,
       _getChannel = getChannel;

  final MeetingPlaceCoreSDK _coreSDK;
  final Future<Channel> Function() _getChannel;

  static const contactCardEventIdKey = 'contact_card_event_id';

  Future<void> send({
    required String senderDid,
    required ContactCard contactCard,
  }) async {
    final channel = await _getChannel();
    final cardBytes = Uint8List.fromList(
      utf8.encode(jsonEncode(contactCard.toJson())),
    );
    final eventId = await _coreSDK.sendMediaMessage(
      channel,
      cardBytes,
      contentType: 'application/json',
      filename: 'contact-card.json',
      extraContent: {GroupDetailsUpdateSender.memberDidKey: senderDid},
    );

    final content =
        eventId != null
            ? {contactCardEventIdKey: eventId}
            : {'profileDetails': contactCard.toJson()};

    await _coreSDK.sendMessage(
      _ContactDetailsUpdateWithAttachment(
        senderDid: senderDid,
        content: content,
      ),
    );
  }
}

class _ContactDetailsUpdateWithAttachment extends MatrixOutgoingMessage {
  _ContactDetailsUpdateWithAttachment({
    required super.senderDid,
    required super.content,
  }) : super(type: MatrixChatEventType.contactDetailsUpdate);
}

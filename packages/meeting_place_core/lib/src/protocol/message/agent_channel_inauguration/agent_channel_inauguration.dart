import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../contact_card/contact_card.dart';
import '../../meeting_place_protocol.dart';
import 'agent_channel_inauguration_body.dart';

class AgentChannelInauguration {
  factory AgentChannelInauguration.create({
    required String from,
    required List<String> to,
    required String otherPartyPermanentChannelDid,
    required String otherPartyNotificationToken,
    required String offerLink,
    required String publishOfferDid,
    ContactCard? contactCard,
  }) {
    return AgentChannelInauguration(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: AgentChannelInaugurationBody(
        permanentChannelDid: otherPartyPermanentChannelDid,
        notificationToken: otherPartyNotificationToken,
        offerLink: offerLink,
        publishOfferDid: publishOfferDid,
        contactCard: contactCard,
      ),
    );
  }

  factory AgentChannelInauguration.fromPlainTextMessage(
    PlainTextMessage message,
  ) {
    return AgentChannelInauguration(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: AgentChannelInaugurationBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  AgentChannelInauguration({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final AgentChannelInaugurationBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(MeetingPlaceProtocol.agentChannelInauguration.value),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}

import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../../entity/channel.dart';
import '../../../protocol/contact_card/contact_card.dart';
import '../../meeting_place_protocol.dart';
import 'agent_create_channel_identity_request_body.dart';

class AgentCreateChannelIdentityRequest {
  factory AgentCreateChannelIdentityRequest.create({
    required String from,
    required List<String> to,
    required String channelDid,
    required String offerLink,
    required String publishOfferDid,
    required ContactCard contactCard,
    required ChannelTransport transport,
    String? contextKey,
  }) {
    return AgentCreateChannelIdentityRequest(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: AgentCreateChannelIdentityRequestBody(
        channelDid: channelDid,
        offerLink: offerLink,
        publishOfferDid: publishOfferDid,
        contactCard: contactCard,
        transport: transport,
        contextKey: contextKey,
      ),
    );
  }

  factory AgentCreateChannelIdentityRequest.fromPlainTextMessage(
    PlainTextMessage message,
  ) {
    return AgentCreateChannelIdentityRequest(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: AgentCreateChannelIdentityRequestBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  AgentCreateChannelIdentityRequest({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final AgentCreateChannelIdentityRequestBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(
        MeetingPlaceProtocol.agentCreateChannelIdentityRequest.value,
      ),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}

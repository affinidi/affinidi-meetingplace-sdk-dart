import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_protocol.dart';
import 'agent_create_channel_identity_response_body.dart';

class AgentCreateChannelIdentityResponse {
  factory AgentCreateChannelIdentityResponse.create({
    required String from,
    required List<String> to,
    required String did,
  }) {
    return AgentCreateChannelIdentityResponse(
      id: const Uuid().v4(),
      from: from,
      to: to,
      body: AgentCreateChannelIdentityResponseBody(did: did),
    );
  }

  factory AgentCreateChannelIdentityResponse.fromPlainTextMessage(
    PlainTextMessage message,
  ) {
    return AgentCreateChannelIdentityResponse(
      id: message.id,
      from: message.from!,
      to: message.to!,
      body: AgentCreateChannelIdentityResponseBody.fromJson(message.body!),
      createdTime: message.createdTime,
    );
  }

  AgentCreateChannelIdentityResponse({
    required this.id,
    required this.from,
    required this.to,
    required this.body,
    DateTime? createdTime,
  }) : createdTime = createdTime ?? DateTime.now().toUtc();

  final String id;
  final String from;
  final List<String> to;
  final AgentCreateChannelIdentityResponseBody body;
  final DateTime createdTime;

  PlainTextMessage toPlainTextMessage() {
    return PlainTextMessage(
      id: id,
      type: Uri.parse(
        MeetingPlaceProtocol.agentCreateChannelIdentityResponse.value,
      ),
      from: from,
      to: to,
      body: body.toJson(),
      createdTime: createdTime,
    );
  }
}

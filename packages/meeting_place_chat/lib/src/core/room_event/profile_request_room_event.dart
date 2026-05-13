import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../protocol/chat_protocol.dart';

class ProfileRequestRoomEvent extends MatrixRoomEvent {
  ProfileRequestRoomEvent({
    required super.senderDid,
    required super.roomId,
    required String profileHash,
  }) : super(
         id: const Uuid().v4(),
         type: ChatProtocol.chatAliasProfileRequest.value,
         content: {'profile_hash': profileHash},
         timestamp: DateTime.now().toUtc(),
       );
}

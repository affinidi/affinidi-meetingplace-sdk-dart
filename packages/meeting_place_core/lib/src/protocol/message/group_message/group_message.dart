import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';
import '../../meeting_place_protocol.dart';
import 'group_message_body.dart';

class GroupMessage extends PlainTextMessage {
  GroupMessage({
    required super.id,
    required super.from,
    required super.to,
    required String ciphertext,
    required String iv,
    required String authenticationTag,
    required String preCapsule,
    required String fromDid,
    required int seqNo,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.groupMessage.value),
          body: GroupMessageBody(
            ciphertext: ciphertext,
            iv: iv,
            authenticationTag: authenticationTag,
            preCapsule: preCapsule,
            fromDid: fromDid,
            seqNo: seqNo,
          ).toJson(),
          createdTime: DateTime.now().toUtc(),
        );

  factory GroupMessage.create({
    required String from,
    required List<String> to,
    required String ciphertext,
    required String iv,
    required String authenticationTag,
    required String preCapsule,
    required String fromDid,
    required int seqNo,
  }) {
    return GroupMessage(
      id: const Uuid().v4(),
      from: from,
      to: to,
      ciphertext: ciphertext,
      iv: iv,
      authenticationTag: authenticationTag,
      preCapsule: preCapsule,
      fromDid: fromDid,
      seqNo: seqNo,
    );
  }
}

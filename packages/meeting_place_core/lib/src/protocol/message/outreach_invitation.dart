import 'package:didcomm/didcomm.dart';
import '../meeting_place_protocol.dart';
import 'package:uuid/uuid.dart';

class OutreachInvitation extends PlainTextMessage {
  OutreachInvitation({
    required super.id,
    required super.from,
    required super.to,
    required String mnemonic,
    required String message,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.outreachInvitation.value),
          body: {'mnemonic': mnemonic, 'message': message},
          createdTime: DateTime.now().toUtc(),
        );

  factory OutreachInvitation.create({
    required String from,
    required List<String> to,
    required String mnemonic,
    required String message,
  }) {
    return OutreachInvitation(
      id: Uuid().v4(),
      from: from,
      to: to,
      mnemonic: mnemonic,
      message: message,
    );
  }
}

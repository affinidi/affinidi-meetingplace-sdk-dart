import 'package:didcomm/didcomm.dart';
import '../mpx_protocol.dart';
import '../v_card/v_card.dart';
import 'package:uuid/uuid.dart';

class ChannelInauguration extends PlainTextMessage {
  ChannelInauguration({
    required super.id,
    required super.from,
    required super.to,
    required String did,
    required String notificationToken,
    VCard? vCard,
  }) : super(
          type: Uri.parse(MeetingPlaceProtocol.channelInauguration.value),
          body: {'notificationToken': notificationToken, did: did},
        );

  factory ChannelInauguration.create({
    required String from,
    required List<String> to,
    required String did,
    required String notificationToken,
  }) {
    return ChannelInauguration(
      id: Uuid().v4(),
      from: from,
      to: to,
      did: did,
      notificationToken: notificationToken,
    );
  }
}

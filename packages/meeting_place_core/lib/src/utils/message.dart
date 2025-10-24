import 'package:didcomm/didcomm.dart';
import '../protocol/protocol.dart';

bool isMessageOfType(PlainTextMessage message, MeetingPlaceProtocol type) =>
    message.type.toString() == type.value;

import '../../entity/chat_item.dart';
import 'chat_event.dart';

class StreamData {
  StreamData({this.event, this.chatItem});

  final ChatEvent? event;
  final ChatItem? chatItem;
}

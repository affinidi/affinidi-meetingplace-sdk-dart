import 'package:meeting_place_core/meeting_place_core.dart';

part 'chat_message_event.dart';
part 'chat_presence_event.dart';
part 'chat_activity_event.dart';
part 'chat_effect_event.dart';
part 'chat_contact_details_update_event.dart';
part 'chat_group_deleted_event.dart';
part 'chat_group_details_update_event.dart';
part 'chat_member_deregistered_event.dart';
part 'unhandled_chat_event.dart';

/// Base class for all events emitted on the chat stream.
///
/// Use a `switch` expression on the concrete subtype to handle each event
/// in a type-safe, exhaustive way.
sealed class ChatEvent {
  const ChatEvent();
}

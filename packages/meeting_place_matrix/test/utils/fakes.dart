import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';

class FakeCoreSDK extends Fake implements MeetingPlaceCoreSDK {}

class FakeChatRepository implements ChatRepository {
  @override
  Future<ChatItem> createMessage(ChatItem message) async => message;

  @override
  Future<ChatItem?> getMessage({
    required String chatId,
    required String messageId,
  }) async => null;

  @override
  Future<List<ChatItem>> listMessages(String chatId) async => [];

  @override
  Future<ChatItem> updateMesssage(ChatItem message) async => message;

  @override
  Future<String?> getSyncMarker(String chatId) async => null;

  @override
  Future<void> updateSyncMarker({
    required String chatId,
    required String eventId,
  }) async {}
}

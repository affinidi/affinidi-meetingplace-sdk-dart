import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';

class MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class MockChatRepository extends Mock implements ChatRepository {}

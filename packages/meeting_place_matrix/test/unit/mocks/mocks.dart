import 'package:dio/dio.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/services/sfu_token_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockMeetingPlaceCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class MockMeetingPlaceMatrixSDK extends Mock implements MeetingPlaceMatrixSDK {}

class MockMeetingPlaceMatrixSDKLogger extends Mock
    implements MeetingPlaceMatrixSDKLogger {}

class MockGroupCallSession extends Mock implements GroupCallSession {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockDidManager extends Mock implements DidManager {}

class MockWebRTCDelegate extends Mock implements matrix.WebRTCDelegate {}

class MockSfuTokenService extends Mock implements SfuTokenService {}

class MockLiveKitCallSession extends Mock implements LiveKitCallSession {}

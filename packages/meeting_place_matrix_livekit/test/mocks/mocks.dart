import 'package:dio/dio.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix_livekit/src/services/sfu_token_service.dart';
import 'package:meeting_place_matrix_livekit/src/sessions/livekit_call_session.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockMeetingPlaceCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class MockMeetingPlaceCoreSDKLogger extends Mock
    implements MeetingPlaceCoreSDKLogger {}

class MockGroupCallSession extends Mock implements GroupCallSession {}

class MockDidManager extends Mock implements DidManager {}

class MockWebRTCDelegate extends Mock implements matrix.WebRTCDelegate {}

class MockSfuTokenService extends Mock implements SfuTokenService {}

class MockLiveKitCallSession extends Mock implements LiveKitCallSession {}

import 'package:dio/dio.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix_livekit/src/services/matrix_call_service.dart';
import 'package:meeting_place_matrix_livekit/src/services/sfu_token_service.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockMeetingPlaceCoreSDK extends Mock implements MatrixMeetingPlaceSDK {}

class MockMatrixCallService extends Mock implements MatrixCallService {}

class MockMatrixService extends Mock implements MatrixService {}

class MockMeetingPlaceCoreSDKLogger extends Mock
    implements MeetingPlaceCoreSDKLogger {}

class MockGroupCallSession extends Mock implements GroupCallSession {}

class MockDidManager extends Mock implements DidManager {}

class MockWebRTCDelegate extends Mock implements matrix.WebRTCDelegate {}

class MockSfuTokenService extends Mock implements SfuTokenService {}

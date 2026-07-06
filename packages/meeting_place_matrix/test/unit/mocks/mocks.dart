import 'package:dio/dio.dart';
import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:meeting_place_matrix/src/services/sfu_token_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../meeting_place_matrix.dart';

class MockDio extends Mock implements Dio {}

class MockMatrixClient extends Mock implements matrix.Client {}

class MockVoIP extends Mock implements matrix.VoIP {}

class MockMeetingPlaceCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class MockMeetingPlaceMatrixSDK extends Mock implements MeetingPlaceMatrixSDK {}

class MockMatrixService extends Mock implements MatrixService {}

class MockMeetingPlaceMatrixSDKLogger extends Mock
    implements MeetingPlaceMatrixSDKLogger {}

class MockGroupCallSession extends Mock implements matrix.GroupCallSession {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockDidManager extends Mock implements DidManager {}

class MockWebRTCDelegate extends Mock implements matrix.WebRTCDelegate {}

class MockSfuTokenService extends Mock implements SfuTokenService {}

class MockLiveKitCallSession extends Mock implements LiveKitCallSession {}

class MockMatrixRoom extends Mock implements matrix.Room {}

class MockCallMembership extends Mock implements matrix.CallMembership {
  MockCallMembership({
    required String callId,
    required String userId,
    required String deviceId,
    bool isExpired = false,
  }) {
    when(() => this.callId).thenReturn(callId);
    when(() => this.userId).thenReturn(userId);
    when(() => this.deviceId).thenReturn(deviceId);
    when(() => this.isExpired).thenReturn(isExpired);
  }
}

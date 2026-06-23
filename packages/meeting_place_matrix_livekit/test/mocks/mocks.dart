import 'package:dio/dio.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

class MockMeetingPlaceCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class MockMeetingPlaceCoreSDKLogger extends Mock
    implements MeetingPlaceCoreSDKLogger {}

class MockGroupCallSession extends Mock implements GroupCallSession {}

class MockDidManager extends Mock implements DidManager {}

class MockWebRTCDelegate extends Mock implements WebRTCDelegate {}

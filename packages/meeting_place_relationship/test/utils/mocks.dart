import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';

class MockMeetingPlaceCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class MockChannel extends Mock implements Channel {}

MockMeetingPlaceCoreSDK mockCoreSDKWithAttachmentStream(
  StreamController<(Channel, List<Attachment>)> ctrl,
) {
  final sdk = MockMeetingPlaceCoreSDK();
  when(() => sdk.channelAttachments).thenAnswer((_) => ctrl.stream);
  return sdk;
}

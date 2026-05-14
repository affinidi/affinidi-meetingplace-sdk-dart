import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:mocktail/mocktail.dart';

class MockMeetingPlaceCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class MockVdipClient extends Mock implements VdipClient {}

class MockChannel extends Mock implements Channel {}

class MockReceivedRCardRepository extends Mock
    implements ReceivedRCardRepository {}

MockMeetingPlaceCoreSDK mockCoreSDKWithAttachmentStream(
  StreamController<(Channel, List<Attachment>)> ctrl,
) {
  final sdk = MockMeetingPlaceCoreSDK();
  final vdip = MockVdipClient();
  when(() => vdip.incomingMessages).thenAnswer((_) => const Stream.empty());
  when(() => sdk.vdip).thenReturn(vdip);
  when(() => sdk.channelAttachments).thenAnswer((_) => ctrl.stream);
  return sdk;
}

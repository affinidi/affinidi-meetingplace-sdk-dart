import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';

class MockMeetingPlaceCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class MockVdipClient extends Mock implements VdipClient {}

class MockChannel extends Mock implements Channel {}

class MockRCardRepository extends Mock implements RCardRepository {}

class MockVerifiableCredential extends Mock implements VerifiableCredential {}

class FakeVcDataModelV2 extends Fake implements VcDataModelV2 {}

class MockVrcRepository extends Mock implements VrcRepository {}

MockMeetingPlaceCoreSDK mockCoreSDKWithStreams(
  StreamController<(Channel, List<Attachment>)> attachmentCtrl,
  StreamController<PlainTextMessage> vdipCtrl,
) {
  final sdk = MockMeetingPlaceCoreSDK();
  final vdipClient = MockVdipClient();

  when(() => sdk.channelAttachments).thenAnswer((_) => attachmentCtrl.stream);
  when(() => sdk.vdip).thenReturn(vdipClient);
  when(() => vdipClient.incomingMessages).thenAnswer((_) => vdipCtrl.stream);
  when(() => vdipClient.registerMessageProcessor(any())).thenReturn(null);
  when(sdk.closeVdipStream).thenAnswer((_) async {});
  return sdk;
}

MockVrcRepository stubbedMockVrcRepository() {
  final mock = MockVrcRepository();
  when(() => mock.upsert(any())).thenAnswer((_) async {});
  when(mock.watchAll).thenReturn(const Stream.empty());
  when(mock.listAll).thenReturn(Future.value(const []));
  when(() => mock.getById(any())).thenAnswer((_) async => null);
  when(() => mock.listByHolderDid(any())).thenAnswer((_) async => const []);
  when(() => mock.countByHolderDid(any())).thenAnswer((_) async => 0);
  when(() => mock.deleteById(any())).thenAnswer((_) async {});
  return mock;
}

import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:meeting_place_credentials/src/vrc/vrc_exchange_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';

class MockMeetingPlaceCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class MockVdipClient extends Mock implements VdipClient {}

class MockChannel extends Mock implements Channel {}

class MockRCardRepository extends Mock implements RCardRepository {}

class MockVerifiableCredential extends Mock implements VerifiableCredential {}

class FakeVcDataModelV2 extends Fake implements VcDataModelV2 {}

class MockVrcRepository extends Mock implements VrcRepository {}

class MockVrcExchangeClient extends Mock implements VrcExchangeClient {}

class MockVrcParser extends Mock implements VrcParser {}

class MockParsedVC extends Mock implements ParsedVerifiableCredential {}

class FakeVdipIssuedCredentialBody extends Fake
    implements VdipIssuedCredentialBody {}

MockMeetingPlaceCoreSDK mockCoreSDKWithStreams(
  StreamController<ChannelAttachmentEvent> attachmentCtrl,
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
  when(mock.watchAll).thenAnswer((_) => const Stream.empty());
  when(mock.listAll).thenAnswer((_) async => const []);
  when(() => mock.getById(any())).thenAnswer((_) async => null);
  when(() => mock.listByHolderDid(any())).thenAnswer((_) async => const []);
  when(() => mock.countByHolderDid(any())).thenAnswer((_) async => 0);
  when(() => mock.deleteById(any())).thenAnswer((_) async {});
  return mock;
}

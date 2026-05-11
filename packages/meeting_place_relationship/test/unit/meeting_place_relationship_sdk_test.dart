import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/r_card_fixture.dart';
import '../fixtures/vrc_fixture.dart';
import '../utils/mocks.dart';

void main() {
  group('MeetingPlaceRelationshipSDK', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late StreamController<(Channel, List<Attachment>)> channelAttachmentsCtrl;

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<(Channel, List<Attachment>)>.broadcast();
      mockCoreSDK = mockCoreSDKWithAttachmentStream(channelAttachmentsCtrl);
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test(
      'receivedRCards returns the same stream instance on repeated access',
      () async {
        final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
        expect(sdk.receivedRCards, same(sdk.receivedRCards));
        await sdk.closeRelationshipStreams();
      },
    );

    test('closeRelationshipStreams() completes without error', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      await expectLater(sdk.closeRelationshipStreams(), completes);
    });

    test('attachments with wrong format do not emit', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');

      final emitted = <ReceivedRCard>[];
      final sub = sdk.receivedRCards.listen(emitted.add);

      channelAttachmentsCtrl.add((
        channel,
        [makeAttachment(format: 'unknown_plugin', dataJson: '{}')],
      ));

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });

    test('empty attachment list does not emit', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');

      final emitted = <ReceivedRCard>[];
      final sub = sdk.receivedRCards.listen(emitted.add);

      channelAttachmentsCtrl.add((channel, []));

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });

    test('invalid R-Card attachment does not emit', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');

      final emitted = <ReceivedRCard>[];
      final sub = sdk.receivedRCards.listen(emitted.add);

      channelAttachmentsCtrl.add((channel, [rCardAttachment()]));

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });
  });

  group('MeetingPlaceRelationshipSDK receivedRCards happy path', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late StreamController<(Channel, List<Attachment>)> channelAttachmentsCtrl;
    late List<Attachment> signedAttachments;
    late MockChannel channel;

    setUpAll(() async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      final didManager = DidKeyManager(
        wallet: wallet,
        store: InMemoryDidStore(),
      );
      final keyPair = await wallet.generateKey();
      await didManager.addVerificationMethod(keyPair.id);
      final didDoc = await didManager.getDidDocument();
      final did = didDoc.id;

      final vc = await CredentialBuilder.buildRCard(
        issuerDid: did,
        subjectDid: did,
        subject: const RCardSubject(firstName: 'Alice'),
        issuerDidManager: didManager,
      );
      signedAttachments = RCardDIDCommAttachmentBuilder.fromVcJson(vc.toJson());
    });

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<(Channel, List<Attachment>)>.broadcast();
      mockCoreSDK = mockCoreSDKWithAttachmentStream(channelAttachmentsCtrl);
      channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test('valid signed R-Card emits on receivedRCards', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final emitted = <ReceivedRCard>[];
      final sub = sdk.receivedRCards.listen(emitted.add);

      channelAttachmentsCtrl.add((channel, signedAttachments));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emitted, hasLength(1));
      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });
  });

  group('MeetingPlaceRelationshipSDK.parseRCard', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late StreamController<(Channel, List<Attachment>)> channelAttachmentsCtrl;

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<(Channel, List<Attachment>)>.broadcast();
      mockCoreSDK = mockCoreSDKWithAttachmentStream(channelAttachmentsCtrl);
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test('returns null for invalid JSON blob', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final result = await sdk.parseRCard(vcBlob: 'not-json');
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });

    test('returns null for R-Card without proof', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final result = await sdk.parseRCard(vcBlob: rCardVcBlob);
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });
  });

  group('MeetingPlaceRelationshipSDK.parseVrc', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late StreamController<(Channel, List<Attachment>)> channelAttachmentsCtrl;

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<(Channel, List<Attachment>)>.broadcast();
      mockCoreSDK = mockCoreSDKWithAttachmentStream(channelAttachmentsCtrl);
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test('returns null for empty string', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final result = await sdk.parseVrc(vcBlob: '');
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });

    test('returns null for non-VRC blob', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final result = await sdk.parseVrc(vcBlob: 'not-json');
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });

    test('returns null for VRC without proof', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final result = await sdk.parseVrc(vcBlob: vrcBlobWithoutProof);
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });
  });
}

import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/r_card_fixture.dart';
import '../fixtures/vrc_fixture.dart';
import '../utils/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(
      RCard(
        subjectDid: 'did:key:fallback',
        vcBlob: '{}',
        issuerDid: 'did:key:fallback',
        version: 1,
        issuanceDate: DateTime.utc(2024),
        receivedAt: DateTime.utc(2024),
      ),
    );
    registerFallbackValue(MockChannel());
    registerFallbackValue(MockVerifiableCredential());
  });

  group('MeetingPlaceRelationshipSDK', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late MockRCardRepository mockRepo;
    late StreamController<(Channel, List<Attachment>)> channelAttachmentsCtrl;

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<(Channel, List<Attachment>)>.broadcast();
      mockCoreSDK = mockCoreSDKWithAttachmentStream(channelAttachmentsCtrl);
      mockRepo = MockRCardRepository();
      when(() => mockRepo.upsert(any())).thenAnswer((_) async {});
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test(
      'receivedRCards returns the same stream instance on repeated access',
      () async {
        final sdk = MeetingPlaceRelationshipSDK(
          coreSDK: mockCoreSDK,
          rCardRepository: mockRepo,
        );
        expect(sdk.receivedRCards, same(sdk.receivedRCards));
        await sdk.closeRelationshipStreams();
      },
    );

    test('closeRelationshipStreams() completes without error', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );
      await expectLater(sdk.closeRelationshipStreams(), completes);
    });

    test('closeRelationshipStreams() is idempotent'
        ' — does not throw on second call', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );
      await sdk.closeRelationshipStreams();
      await expectLater(sdk.closeRelationshipStreams(), completes);
    });

    test('attachments with wrong format do not emit', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );
      final channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');

      final emitted = <RCard>[];
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
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );
      final channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');

      final emitted = <RCard>[];
      final sub = sdk.receivedRCards.listen(emitted.add);

      channelAttachmentsCtrl.add((channel, []));

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });

    test('invalid R-Card attachment does not emit', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );
      final channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');

      final emitted = <RCard>[];
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
    late MockRCardRepository mockRepo;
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
      mockRepo = MockRCardRepository();
      when(() => mockRepo.upsert(any())).thenAnswer((_) async {});
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
      channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test('valid signed R-Card emits on receivedRCards', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );
      final emitted = <RCard>[];
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
    late MockRCardRepository mockRepo;
    late StreamController<(Channel, List<Attachment>)> channelAttachmentsCtrl;

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<(Channel, List<Attachment>)>.broadcast();
      mockCoreSDK = mockCoreSDKWithAttachmentStream(channelAttachmentsCtrl);
      mockRepo = MockRCardRepository();
      when(() => mockRepo.upsert(any())).thenAnswer((_) async {});
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test('returns null for invalid JSON blob', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );
      final result = await sdk.parseRCard(vcBlob: 'not-json');
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });

    test('returns null for R-Card without proof', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );
      final result = await sdk.parseRCard(vcBlob: rCardVcBlob);
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });
  });

  group('MeetingPlaceRelationshipSDK.parseVrc', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late MockRCardRepository mockRepo;
    late StreamController<(Channel, List<Attachment>)> channelAttachmentsCtrl;

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<(Channel, List<Attachment>)>.broadcast();
      mockCoreSDK = mockCoreSDKWithAttachmentStream(channelAttachmentsCtrl);
      mockRepo = MockRCardRepository();
      when(() => mockRepo.upsert(any())).thenAnswer((_) async {});
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test('returns null for empty string', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );
      final result = await sdk.parseVrc(vcBlob: '');
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });

    test('returns null for non-VRC blob', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );
      final result = await sdk.parseVrc(vcBlob: 'not-json');
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });

    test('returns null for VRC without proof', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );
      final result = await sdk.parseVrc(vcBlob: vrcBlobWithoutProof);
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });
  });

  group('MeetingPlaceRelationshipSDK.sendRCard', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late MockVdipClient mockVdip;
    late MockRCardRepository mockRepo;
    late StreamController<(Channel, List<Attachment>)> channelAttachmentsCtrl;
    late DidKeyManager didManager;
    late String issuerDid;

    setUpAll(() async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
      final keyPair = await wallet.generateKey();
      await didManager.addVerificationMethod(keyPair.id);
      final didDoc = await didManager.getDidDocument();
      issuerDid = didDoc.id;
    });

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<(Channel, List<Attachment>)>.broadcast();
      mockCoreSDK = MockMeetingPlaceCoreSDK();
      mockVdip = MockVdipClient();
      when(
        () => mockVdip.incomingMessages,
      ).thenAnswer((_) => const Stream.empty());
      when(
        () => mockVdip.issueCredential(
          channel: any(named: 'channel'),
          credential: any(named: 'credential'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockCoreSDK.vdip).thenReturn(mockVdip);
      when(
        () => mockCoreSDK.channelAttachments,
      ).thenAnswer((_) => channelAttachmentsCtrl.stream);
      mockRepo = MockRCardRepository();
      when(() => mockRepo.upsert(any())).thenAnswer((_) async {});
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test('returns valid VC JSON and calls issueCredential', () async {
      final channel = MockChannel();
      when(() => channel.permanentChannelDid).thenReturn(issuerDid);
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:key:recipient');

      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );

      final vcBlob = await sdk.sendRCard(
        channel: channel,
        subjectDid: 'did:key:recipient',
        card: const RCardSubject(firstName: 'Bob', lastName: 'Smith'),
        issuerDidManager: didManager,
      );

      expect(() => jsonDecode(vcBlob), returnsNormally);
      final decoded = jsonDecode(vcBlob) as Map<String, dynamic>;
      expect(decoded['type'], contains('RelationshipCard'));
      verify(
        () => mockVdip.issueCredential(
          channel: any(named: 'channel'),
          credential: any(named: 'credential'),
        ),
      ).called(1);

      await sdk.closeRelationshipStreams();
    });

    test('throws StateError when channel lacks permanentChannelDid', () async {
      final channel = MockChannel();
      when(() => channel.permanentChannelDid).thenReturn(null);

      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
      );

      await expectLater(
        sdk.sendRCard(
          channel: channel,
          subjectDid: 'did:key:recipient',
          card: const RCardSubject(firstName: 'Bob'),
          issuerDidManager: didManager,
        ),
        throwsStateError,
      );

      await sdk.closeRelationshipStreams();
    });
  });
}

import 'dart:async';
import 'dart:convert';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
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
        issuerDid: 'did:key:issuer',
        version: 1,
        issuanceDate: DateTime.utc(2024, 1, 1),
        receivedAt: DateTime.utc(2024, 1, 1),
      ),
    );
    registerFallbackValue(MockChannel());
    registerFallbackValue(FakeVcDataModelV2());
    registerFallbackValue(
      Vrc(
        id: 'stored-vrc-fallback',
        vcBlob: '{}',
        referenceId: 'channel-fallback',
        holderDid: 'did:key:holder',
        issuerDid: 'did:key:issuer',
        issuedAt: DateTime.utc(2024, 1, 1),
      ),
    );
    registerFallbackValue(FakeVdipIssuedCredentialBody());
  });

  group('MeetingPlaceRelationshipSDK', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late MockRCardRepository mockRepo;
    late MockVrcRepository mockVrcRepo;
    late StreamController<ChannelAttachmentEvent> channelAttachmentsCtrl;
    late StreamController<PlainTextMessage> vdipMessagesCtrl;
    late MeetingPlaceRelationshipSDK sdk;

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<ChannelAttachmentEvent>.broadcast();
      vdipMessagesCtrl = StreamController<PlainTextMessage>.broadcast();
      mockCoreSDK = mockCoreSDKWithStreams(
        channelAttachmentsCtrl,
        vdipMessagesCtrl,
      );
      mockRepo = MockRCardRepository();
      mockVrcRepo = MockVrcRepository();
      when(() => mockRepo.upsert(any())).thenAnswer((_) async {});
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
      when(() => mockRepo.listAll()).thenAnswer((_) async => const []);
      when(() => mockRepo.getBySubjectDid(any())).thenAnswer((_) async => null);
      when(() => mockRepo.updateNotes(any(), any())).thenAnswer((_) async {});
      when(() => mockRepo.deleteBySubjectDid(any())).thenAnswer((_) async {});
      sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
      await vdipMessagesCtrl.close();
    });

    test(
      'receivedRCards returns the same stream instance on repeated access',
      () async {
        final sdk = MeetingPlaceRelationshipSDK(
          coreSDK: mockCoreSDK,
          rCardRepository: mockRepo,
          vrcRepository: mockVrcRepo,
        );
        expect(sdk.receivedRCards, same(sdk.receivedRCards));
        await sdk.closeRelationshipStreams();
      },
    );

    test('closeRelationshipStreams() completes without error', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      await expectLater(sdk.closeRelationshipStreams(), completes);
    });

    test('closeRelationshipStreams() is idempotent'
        ' — does not throw on second call', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      await sdk.closeRelationshipStreams();
    });

    test('watchReceivedRCards delegates to repository', () async {
      final expected = [
        RCard(
          subjectDid: 'did:key:peer',
          vcBlob: '{}',
          issuerDid: 'did:key:issuer',
          version: 1,
          issuanceDate: DateTime.utc(2024, 1, 1),
          receivedAt: DateTime.utc(2024, 1, 2),
        ),
      ];
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value(expected));

      await expectLater(sdk.watchReceivedRCards(), emits(expected));
    });

    test('list/get/update/delete delegate to repository', () async {
      final stored = RCard(
        subjectDid: 'did:key:peer',
        vcBlob: '{}',
        issuerDid: 'did:key:issuer',
        version: 1,
        issuanceDate: DateTime.utc(2024, 1, 1),
        receivedAt: DateTime.utc(2024, 1, 2),
      );
      when(() => mockRepo.listAll()).thenAnswer((_) async => [stored]);
      when(
        () => mockRepo.getBySubjectDid('did:key:peer'),
      ).thenAnswer((_) async => stored);

      expect(await sdk.listReceivedRCards(), [stored]);
      expect(await sdk.getReceivedRCardBySubjectDid('did:key:peer'), stored);

      await sdk.updateReceivedRCardNotes('did:key:peer', 'hello');
      await sdk.deleteReceivedRCard('did:key:peer');

      verify(() => mockRepo.updateNotes('did:key:peer', 'hello')).called(1);
      verify(() => mockRepo.deleteBySubjectDid('did:key:peer')).called(1);
    });
  });

  group('MeetingPlaceRelationshipSDK R-Card stream wiring', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late MockRCardRepository mockRepo;
    late MockVrcRepository mockVrcRepo;
    late StreamController<ChannelAttachmentEvent> channelAttachmentsCtrl;
    late StreamController<PlainTextMessage> vdipMessagesCtrl;
    late String issuerDid;
    late List<Attachment> signedAttachments;

    setUpAll(() async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      final didManager = DidKeyManager(
        wallet: wallet,
        store: InMemoryDidStore(),
      );
      final keyPair = await wallet.generateKey();
      await didManager.addVerificationMethod(keyPair.id);
      final didDoc = await didManager.getDidDocument();
      issuerDid = didDoc.id;

      final vc = await CredentialBuilder.buildRCard(
        issuerDid: issuerDid,
        subjectDid: issuerDid,
        subject: const RCardSubject(firstName: 'Alice'),
        issuerDidManager: didManager,
      );
      signedAttachments = RCardDIDCommAttachmentBuilder.fromVcJson(vc.toJson());
    });

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<ChannelAttachmentEvent>.broadcast();
      vdipMessagesCtrl = StreamController<PlainTextMessage>.broadcast();
      mockCoreSDK = mockCoreSDKWithStreams(
        channelAttachmentsCtrl,
        vdipMessagesCtrl,
      );
      mockRepo = MockRCardRepository();
      mockVrcRepo = MockVrcRepository();
      when(() => mockRepo.upsert(any())).thenAnswer((_) async {});
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
      when(() => mockRepo.listAll()).thenAnswer((_) async => const []);
      when(() => mockRepo.getBySubjectDid(any())).thenAnswer((_) async => null);
      when(() => mockRepo.updateNotes(any(), any())).thenAnswer((_) async {});
      when(() => mockRepo.deleteBySubjectDid(any())).thenAnswer((_) async {});
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
      await vdipMessagesCtrl.close();
    });

    test('emits and persists a valid signed attachment R-Card', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      final channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');

      final emitted = <RCard>[];
      final sub = sdk.receivedRCards.listen(emitted.add);

      channelAttachmentsCtrl.add(
        ChannelAttachmentEvent(
          channel: channel,
          attachments: signedAttachments,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emitted, hasLength(1));
      expect(emitted.first.issuerDid, issuerDid);
      verify(() => mockRepo.upsert(any())).called(1);

      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });

    test('ignores unrelated attachments', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      final channel = MockChannel();

      final emitted = <RCard>[];
      final sub = sdk.receivedRCards.listen(emitted.add);

      channelAttachmentsCtrl.add(
        ChannelAttachmentEvent(
          channel: channel,
          attachments: [
            makeAttachment(format: 'unknown_plugin', dataJson: '{}'),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      verifyNever(() => mockRepo.upsert(any()));

      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });

    test('empty attachment list does not emit', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      final channel = MockChannel();

      final emitted = <RCard>[];
      final sub = sdk.receivedRCards.listen(emitted.add);

      channelAttachmentsCtrl.add(
        ChannelAttachmentEvent(channel: channel, attachments: []),
      );

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });

    test('invalid R-Card attachment emits a stream error', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      final channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');

      final emitted = <RCard>[];
      final errors = <Object>[];
      final sub = sdk.receivedRCards.listen(emitted.add, onError: errors.add);

      channelAttachmentsCtrl.add(
        ChannelAttachmentEvent(
          channel: channel,
          attachments: [rCardAttachment()],
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      expect(errors, hasLength(1));
      expect(errors.first, isA<FormatException>());
      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });
  });

  group('MeetingPlaceRelationshipSDK VRC streams', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late MockRCardRepository mockRepo;
    late MockVrcRepository mockVrcRepo;
    late StreamController<ChannelAttachmentEvent> channelAttachmentsCtrl;
    late StreamController<PlainTextMessage> vdipMessagesCtrl;
    late String signedVrcBlob;

    setUpAll(() async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      final issuerManager = DidKeyManager(
        wallet: wallet,
        store: InMemoryDidStore(),
      );
      final keyPair = await wallet.generateKey();
      await issuerManager.addVerificationMethod(keyPair.id);
      final didDoc = await issuerManager.getDidDocument();
      final issuerDid = didDoc.id;

      final signed = await CredentialBuilder.buildVrc(
        issuerDid: issuerDid,
        subject: VrcCredentialSubject(
          from: VrcParty(did: issuerDid, name: 'Alice'),
          to: const VrcParty(did: 'did:key:peer', name: 'Bob'),
        ),
        issuerDidManager: issuerManager,
      );
      signedVrcBlob = jsonEncode(signed.toJson());
    });

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<ChannelAttachmentEvent>.broadcast();
      vdipMessagesCtrl = StreamController<PlainTextMessage>.broadcast();
      mockCoreSDK = mockCoreSDKWithStreams(
        channelAttachmentsCtrl,
        vdipMessagesCtrl,
      );
      mockRepo = MockRCardRepository();
      mockVrcRepo = MockVrcRepository();
      when(() => mockRepo.upsert(any())).thenAnswer((_) async {});
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
      when(() => mockRepo.listAll()).thenAnswer((_) async => const []);
      when(() => mockRepo.getBySubjectDid(any())).thenAnswer((_) async => null);
      when(() => mockRepo.updateNotes(any(), any())).thenAnswer((_) async {});
      when(() => mockRepo.deleteBySubjectDid(any())).thenAnswer((_) async {});
      when(
        () => mockCoreSDK.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => null);
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
      await vdipMessagesCtrl.close();
    });

    test('emits a typed VRC request and caches it by sender DID', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      final events = <VrcRequest>[];
      final sub = sdk.receivedVrcRequests.listen(events.add);

      vdipMessagesCtrl.add(
        PlainTextMessage(
          id: 'msg-1',
          type: VdipRequestIssuanceMessage.messageType,
          from: 'did:key:sender',
          to: const ['did:key:recipient'],
          body: {
            'proposal_id': 'proposal-1',
            'credential_meta': {
              'data': {
                VrcConstants.requestMetadataKeyChannelId: 'channel-1',
                VrcConstants.requestMetadataKeyIdentityDid: 'did:key:peer',
                VrcConstants.requestMetadataKeyIdentityName: 'Bob',
              },
            },
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single.senderDid, 'did:key:sender');
      expect(events.single.proposalId, 'proposal-1');
      expect(events.single.channelId, 'channel-1');
      expect(events.single.identityDid, 'did:key:peer');
      expect(sdk.consumePendingVrcRequest('did:key:sender'), events.single);
      expect(sdk.consumePendingVrcRequest('did:key:sender'), isNull);

      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });

    test('ignores VRC requests without sender DID', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      final events = <VrcRequest>[];
      final sub = sdk.receivedVrcRequests.listen(events.add);

      vdipMessagesCtrl.add(
        PlainTextMessage(
          id: 'msg-2',
          type: VdipRequestIssuanceMessage.messageType,
          body: const {'proposal_id': 'proposal-2'},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
      expect(sdk.consumePendingVrcRequest('did:key:sender'), isNull);

      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });

    test('emits a parsed VRC and caches it by sender DID', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      final events = <VrcIssuance>[];
      final sub = sdk.receivedVrcs.listen(events.add);

      vdipMessagesCtrl.add(
        PlainTextMessage(
          id: 'msg-3',
          type: VdipIssuedCredentialMessage.messageType,
          from: 'did:key:sender',
          to: const ['did:key:recipient'],
          body: {
            'credential': signedVrcBlob,
            'credential_format': RelationshipCredentialConstants.w3cLdV1,
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(events, hasLength(1));
      expect(events.single.senderDid, 'did:key:sender');
      expect(events.single.vcBlob, signedVrcBlob);
      expect(sdk.consumePendingVrc('did:key:sender'), events.single);
      expect(sdk.consumePendingVrc('did:key:sender'), isNull);

      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });

    test('ignores invalid VRC payloads', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      final events = <VrcIssuance>[];
      final sub = sdk.receivedVrcs.listen(events.add);

      vdipMessagesCtrl.add(
        PlainTextMessage(
          id: 'msg-4',
          type: VdipIssuedCredentialMessage.messageType,
          from: 'did:key:sender',
          body: const {
            'credential': '',
            'credential_format': RelationshipCredentialConstants.w3cLdV1,
          },
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);
      expect(sdk.consumePendingVrc('did:key:sender'), isNull);

      await sub.cancel();
      await sdk.closeRelationshipStreams();
    });
  });

  group('MeetingPlaceRelationshipSDK VRC persistence', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late MockRCardRepository mockRCardRepo;
    late MockVrcRepository mockVrcRepo;
    late StreamController<ChannelAttachmentEvent> channelAttachmentsCtrl;
    late StreamController<PlainTextMessage> vdipMessagesCtrl;
    late String signedVrcBlob;

    setUpAll(() async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      final issuerManager = DidKeyManager(
        wallet: wallet,
        store: InMemoryDidStore(),
      );
      final keyPair = await wallet.generateKey();
      await issuerManager.addVerificationMethod(keyPair.id);
      final didDoc = await issuerManager.getDidDocument();
      final issuerDid = didDoc.id;

      final signed = await CredentialBuilder.buildVrc(
        issuerDid: issuerDid,
        subject: VrcCredentialSubject(
          from: VrcParty(did: issuerDid, name: 'Alice'),
          to: const VrcParty(did: 'did:key:peer', name: 'Bob'),
        ),
        issuerDidManager: issuerManager,
      );
      signedVrcBlob = jsonEncode(signed.toJson());
    });

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<ChannelAttachmentEvent>.broadcast();
      vdipMessagesCtrl = StreamController<PlainTextMessage>.broadcast();
      mockCoreSDK = mockCoreSDKWithStreams(
        channelAttachmentsCtrl,
        vdipMessagesCtrl,
      );
      mockRCardRepo = MockRCardRepository();
      mockVrcRepo = MockVrcRepository();

      when(() => mockRCardRepo.upsert(any())).thenAnswer((_) async {});
      when(
        () => mockRCardRepo.watchAll(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockRCardRepo.listAll()).thenAnswer((_) async => const []);
      when(
        () => mockRCardRepo.getBySubjectDid(any()),
      ).thenAnswer((_) async => null);
      when(
        () => mockRCardRepo.updateNotes(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockRCardRepo.deleteBySubjectDid(any()),
      ).thenAnswer((_) async {});

      when(() => mockVrcRepo.upsert(any())).thenAnswer((_) async {});
      when(
        () => mockVrcRepo.watchAll(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockVrcRepo.listAll()).thenAnswer((_) async => const []);
      when(() => mockVrcRepo.getById(any())).thenAnswer((_) async => null);
      when(
        () => mockVrcRepo.listByHolderDid(any()),
      ).thenAnswer((_) async => const []);
      when(
        () => mockVrcRepo.countByHolderDid(any()),
      ).thenAnswer((_) async => 0);
      when(() => mockVrcRepo.deleteById(any())).thenAnswer((_) async {});
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
      await vdipMessagesCtrl.close();
    });

    test('storeVrc parses and persists a VRC', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRCardRepo,
        vrcRepository: mockVrcRepo,
      );

      final vrc = await sdk.storeVrc(
        vcBlob: signedVrcBlob,
        referenceId: 'channel-1',
      );

      expect(vrc, isNotNull);
      expect(vrc.referenceId, 'channel-1');
      verify(() => mockVrcRepo.upsert(any())).called(1);
    });

    test('storeVrc throws MeetingPlaceRelationshipSDKException '
        'for an invalid vcBlob', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRCardRepo,
        vrcRepository: mockVrcRepo,
      );

      await expectLater(
        () => sdk.storeVrc(vcBlob: 'not-a-vrc', referenceId: 'channel-1'),
        throwsA(isA<MeetingPlaceRelationshipSDKException>()),
      );
    });

    test('received VRC auto-persists when repository is configured', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRCardRepo,
        vrcRepository: mockVrcRepo,
      );
      final channel = MockChannel();
      when(() => channel.id).thenReturn('channel-1');
      when(
        () => mockCoreSDK.getChannelByOtherPartyPermanentDid('did:key:sender'),
      ).thenAnswer((_) async => channel);

      vdipMessagesCtrl.add(
        PlainTextMessage(
          id: 'msg-10',
          type: VdipIssuedCredentialMessage.messageType,
          from: 'did:key:sender',
          body: {
            'credential': signedVrcBlob,
            'credential_format': RelationshipCredentialConstants.w3cLdV1,
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(() => mockVrcRepo.upsert(any())).called(greaterThanOrEqualTo(1));
      await sdk.closeRelationshipStreams();
    });
  });

  group('MeetingPlaceRelationshipSDK VRC protocol helpers', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late MockVdipClient mockVdipClient;
    late MockRCardRepository mockRepo;
    late MockVrcRepository mockVrcRepo;
    late StreamController<ChannelAttachmentEvent> channelAttachmentsCtrl;
    late StreamController<PlainTextMessage> vdipMessagesCtrl;
    late MeetingPlaceRelationshipSDK sdk;
    late String signedVrcBlob;
    late DidKeyManager issuerManager;
    late String issuerDid;

    setUpAll(() async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      issuerManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
      final keyPair = await wallet.generateKey();
      await issuerManager.addVerificationMethod(keyPair.id);
      final didDoc = await issuerManager.getDidDocument();
      issuerDid = didDoc.id;

      final signed = await CredentialBuilder.buildVrc(
        issuerDid: issuerDid,
        subject: VrcCredentialSubject(
          from: VrcParty(did: issuerDid, name: 'Alice'),
          to: const VrcParty(did: 'did:key:peer', name: 'Bob'),
        ),
        issuerDidManager: issuerManager,
      );
      signedVrcBlob = jsonEncode(signed.toJson());
    });

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<ChannelAttachmentEvent>.broadcast();
      vdipMessagesCtrl = StreamController<PlainTextMessage>.broadcast();
      mockCoreSDK = mockCoreSDKWithStreams(
        channelAttachmentsCtrl,
        vdipMessagesCtrl,
      );
      mockVdipClient = mockCoreSDK.vdip as MockVdipClient;
      mockRepo = MockRCardRepository();
      mockVrcRepo = MockVrcRepository();
      when(() => mockRepo.upsert(any())).thenAnswer((_) async {});
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
      when(() => mockRepo.listAll()).thenAnswer((_) async => const []);
      when(() => mockRepo.getBySubjectDid(any())).thenAnswer((_) async => null);
      when(() => mockRepo.updateNotes(any(), any())).thenAnswer((_) async {});
      when(() => mockRepo.deleteBySubjectDid(any())).thenAnswer((_) async {});
      when(
        () => mockCoreSDK.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => null);
      sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
      await vdipMessagesCtrl.close();
    });

    test(
      'handleReceivedVrcRequest returns prompt when exchange not started',
      () async {
        final request = VrcRequest(
          senderDid: 'did:key:sender',
          credentialMetaData: const {
            VrcConstants.requestMetadataKeyIdentityDid: 'did:key:peer',
          },
        );

        final outcome = await sdk.handleReceivedVrcRequest(
          permanentChannelDid: 'channel-1',
          request: request,
          hasVrcExchangeInitiated: false,
          isConnectionInitiator: true,
        );

        expect(outcome, isA<VrcRequestProcessingResultPromptRequired>());
      },
    );

    test(
      'handleReceivedVrcRequest returns waiting for non-initiator',
      () async {
        final request = VrcRequest(
          senderDid: 'did:key:sender',
          credentialMetaData: const {
            VrcConstants.requestMetadataKeyIdentityDid: 'did:key:peer',
          },
        );

        final outcome = await sdk.handleReceivedVrcRequest(
          permanentChannelDid: 'channel-1',
          request: request,
          hasVrcExchangeInitiated: true,
          isConnectionInitiator: false,
        );

        expect(outcome, isA<VrcRequestProcessingResultWaiting>());
      },
    );

    test('returns null for R-Card without proof', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      final result = await sdk.parseRCard(vcBlob: rCardVcBlob);
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });

    test(
      'handleReceivedVrc returns completed when request already received',
      () async {
        final outcome = await sdk.handleReceivedVrc(
          permanentChannelDid: 'channel-1',
          vcBlob: signedVrcBlob,
          exchangeState: const VrcExchangeState(
            hasVrcExchangeInitiated: false,
            hasVrcRequestReceived: true,
            isConnectionInitiator: false,
          ),
        );

        expect(outcome, isA<VrcProcessingResultCompleted>());
      },
    );

    test('handleReceivedVrcRequest returns issued for simultaneous'
        ' request when initiator', () async {
      final sendChannel = MockChannel();
      when(() => sendChannel.id).thenReturn('channel-id');
      when(() => sendChannel.permanentChannelDid).thenReturn(issuerDid);
      when(
        () => mockCoreSDK.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => sendChannel);
      when(
        () => mockCoreSDK.getDidManager(issuerDid),
      ).thenAnswer((_) async => issuerManager);
      when(
        () => mockVdipClient.sendIssuedCredential(
          senderDid: any(named: 'senderDid'),
          recipientDid: any(named: 'recipientDid'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async {});

      final request = VrcRequest(
        senderDid: 'did:key:sender',
        credentialMetaData: {
          VrcConstants.requestMetadataKeyIdentityDid: 'did:key:peer',
          VrcConstants.requestMetadataKeyIdentityName: 'Bob',
        },
      );
      final outcome = await sdk.handleReceivedVrcRequest(
        permanentChannelDid: 'did:key:peer',
        request: request,
        hasVrcExchangeInitiated: true,
        isConnectionInitiator: true,
        issuerDid: issuerDid,
        issuerName: 'Alice',
      );

      expect(outcome, isA<VrcRequestProcessingResultIssued>());
    });

    test(
      'handleReceivedVrc returns reciprocated when initiator receives VRC',
      () async {
        final sendChannel = MockChannel();
        when(() => sendChannel.id).thenReturn('channel-id');
        when(() => sendChannel.permanentChannelDid).thenReturn(issuerDid);
        when(
          () => mockCoreSDK.getChannelByOtherPartyPermanentDid(any()),
        ).thenAnswer((_) async => sendChannel);
        when(
          () => mockCoreSDK.getDidManager(issuerDid),
        ).thenAnswer((_) async => issuerManager);
        when(
          () => mockVdipClient.sendIssuedCredential(
            senderDid: any(named: 'senderDid'),
            recipientDid: any(named: 'recipientDid'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async {});

        final outcome = await sdk.handleReceivedVrc(
          permanentChannelDid: 'did:key:peer',
          vcBlob: signedVrcBlob,
          exchangeState: const VrcExchangeState(
            hasVrcExchangeInitiated: true,
            hasVrcRequestReceived: false,
            isConnectionInitiator: true,
          ),
          issuerDid: issuerDid,
          issuerName: 'Alice',
        );

        expect(outcome, isA<VrcProcessingResultReciprocated>());
      },
    );

    test(
      'handleReceivedVrcRequest returns sentVcBlob in result when issued',
      () async {
        final sendChannel = MockChannel();
        when(() => sendChannel.id).thenReturn('channel-id');
        when(() => sendChannel.permanentChannelDid).thenReturn(issuerDid);
        when(
          () => mockCoreSDK.getChannelByOtherPartyPermanentDid(any()),
        ).thenAnswer((_) async => sendChannel);
        when(
          () => mockCoreSDK.getDidManager(issuerDid),
        ).thenAnswer((_) async => issuerManager);
        when(
          () => mockVdipClient.sendIssuedCredential(
            senderDid: any(named: 'senderDid'),
            recipientDid: any(named: 'recipientDid'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async {});

        final outcome = await sdk.handleReceivedVrcRequest(
          permanentChannelDid: 'did:key:peer',
          request: VrcRequest(
            senderDid: 'did:key:sender',
            credentialMetaData: {
              VrcConstants.requestMetadataKeyIdentityDid: 'did:key:peer',
              VrcConstants.requestMetadataKeyIdentityName: 'Bob',
            },
          ),
          hasVrcExchangeInitiated: true,
          isConnectionInitiator: true,
          issuerDid: issuerDid,
          issuerName: 'Alice',
        );

        expect(outcome, isA<VrcRequestProcessingResultIssued>());
        expect(
          (outcome as VrcRequestProcessingResultIssued).sentVcBlob,
          isNotEmpty,
        );
      },
    );

    test(
      'handleReceivedVrc returns sentVcBlob in result when reciprocated',
      () async {
        final sendChannel = MockChannel();
        when(() => sendChannel.id).thenReturn('channel-id');
        when(() => sendChannel.permanentChannelDid).thenReturn(issuerDid);
        when(
          () => mockCoreSDK.getChannelByOtherPartyPermanentDid(any()),
        ).thenAnswer((_) async => sendChannel);
        when(
          () => mockCoreSDK.getDidManager(issuerDid),
        ).thenAnswer((_) async => issuerManager);
        when(
          () => mockVdipClient.sendIssuedCredential(
            senderDid: any(named: 'senderDid'),
            recipientDid: any(named: 'recipientDid'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async {});

        final outcome = await sdk.handleReceivedVrc(
          permanentChannelDid: 'did:key:peer',
          vcBlob: signedVrcBlob,
          exchangeState: const VrcExchangeState(
            hasVrcExchangeInitiated: true,
            hasVrcRequestReceived: false,
            isConnectionInitiator: true,
          ),
          issuerDid: issuerDid,
          issuerName: 'Alice',
        );

        expect(outcome, isA<VrcProcessingResultReciprocated>());
        expect(
          (outcome as VrcProcessingResultReciprocated).sentVcBlob,
          isNotEmpty,
        );
      },
    );
  });

  group('MeetingPlaceRelationshipSDK.parseVrc', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late MockRCardRepository mockRepo;
    late MockVrcRepository mockVrcRepo;
    late StreamController<ChannelAttachmentEvent> channelAttachmentsCtrl;
    late StreamController<PlainTextMessage> vdipMessagesCtrl;

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<ChannelAttachmentEvent>.broadcast();
      vdipMessagesCtrl = StreamController<PlainTextMessage>.broadcast();
      mockCoreSDK = mockCoreSDKWithStreams(
        channelAttachmentsCtrl,
        vdipMessagesCtrl,
      );
      mockRepo = MockRCardRepository();
      mockVrcRepo = MockVrcRepository();
      when(() => mockRepo.upsert(any())).thenAnswer((_) async {});
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
      await vdipMessagesCtrl.close();
    });

    test('returns null for empty string', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      final result = await sdk.parseVrc(vcBlob: '');
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });

    test('returns null for non-VRC blob', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
      );
      final result = await sdk.parseVrc(vcBlob: 'not-json');
      expect(result, isNull);
      await sdk.closeRelationshipStreams();
    });

    test('returns null for VRC without proof', () async {
      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: mockVrcRepo,
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
    late StreamController<ChannelAttachmentEvent> channelAttachmentsCtrl;
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
          StreamController<ChannelAttachmentEvent>.broadcast();
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
      when(() => mockCoreSDK.closeVdipStream()).thenAnswer((_) async {});
      mockRepo = MockRCardRepository();
      when(() => mockRepo.upsert(any())).thenAnswer((_) async {});
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test('returns sent RCard and calls issueCredential', () async {
      final channel = MockChannel();
      when(() => channel.permanentChannelDid).thenReturn(issuerDid);

      final sdk = MeetingPlaceRelationshipSDK(
        coreSDK: mockCoreSDK,
        rCardRepository: mockRepo,
        vrcRepository: stubbedMockVrcRepository(),
      );

      final rCard = await sdk.sendRCard(
        channel: channel,
        subjectDid: 'did:key:recipient',
        card: const RCardSubject(firstName: 'Bob', lastName: 'Smith'),
        issuerDidManager: didManager,
      );

      expect(rCard, isA<RCard>());
      expect(rCard.subjectDid, 'did:key:recipient');
      expect(rCard.issuerDid, issuerDid);
      expect(() => jsonDecode(rCard.vcBlob), returnsNormally);
      final decoded = jsonDecode(rCard.vcBlob) as Map<String, dynamic>;
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
        vrcRepository: stubbedMockVrcRepository(),
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

  group('MeetingPlaceRelationshipSDK CRUD delegation', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late MockRCardRepository mockRepo;
    late StreamController<ChannelAttachmentEvent> channelAttachmentsCtrl;
    late StreamController<PlainTextMessage> vdipMessagesCtrl;

    final stubCard = RCard(
      subjectDid: 'did:example:subject',
      vcBlob: '{}',
      issuerDid: 'did:example:issuer',
      version: 1,
      issuanceDate: DateTime.utc(2026),
      receivedAt: DateTime.utc(2026),
    );

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<ChannelAttachmentEvent>.broadcast();
      vdipMessagesCtrl = StreamController<PlainTextMessage>.broadcast();
      mockCoreSDK = mockCoreSDKWithStreams(
        channelAttachmentsCtrl,
        vdipMessagesCtrl,
      );
      mockRepo = MockRCardRepository();
      when(() => mockRepo.upsert(any())).thenAnswer((_) async {});
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
      await vdipMessagesCtrl.close();
    });

    MeetingPlaceRelationshipSDK buildSdk() => MeetingPlaceRelationshipSDK(
      coreSDK: mockCoreSDK,
      rCardRepository: mockRepo,
      vrcRepository: stubbedMockVrcRepository(),
    );

    test('watchReceivedRCards delegates to repository.watchAll', () async {
      when(() => mockRepo.watchAll()).thenAnswer((_) => const Stream.empty());
      final sdk = buildSdk();

      sdk.watchReceivedRCards();
      verify(() => mockRepo.watchAll()).called(1);

      await sdk.closeRelationshipStreams();
    });

    test('listReceivedRCards delegates to repository.listAll', () async {
      when(() => mockRepo.listAll()).thenAnswer((_) async => [stubCard]);
      final sdk = buildSdk();

      final result = await sdk.listReceivedRCards();
      expect(result, equals([stubCard]));

      await sdk.closeRelationshipStreams();
    });

    test('getReceivedRCardBySubjectDid delegates to repository', () async {
      when(
        () => mockRepo.getBySubjectDid(stubCard.subjectDid),
      ).thenAnswer((_) async => stubCard);
      final sdk = buildSdk();

      final result = await sdk.getReceivedRCardBySubjectDid(
        stubCard.subjectDid,
      );
      expect(result, equals(stubCard));

      await sdk.closeRelationshipStreams();
    });

    test('updateReceivedRCardNotes delegates to repository', () async {
      when(
        () => mockRepo.updateNotes(stubCard.subjectDid, 'note'),
      ).thenAnswer((_) async {});
      final sdk = buildSdk();

      await sdk.updateReceivedRCardNotes(stubCard.subjectDid, 'note');
      verify(() => mockRepo.updateNotes(stubCard.subjectDid, 'note')).called(1);

      await sdk.closeRelationshipStreams();
    });

    test('deleteReceivedRCard delegates to repository', () async {
      when(
        () => mockRepo.deleteBySubjectDid(stubCard.subjectDid),
      ).thenAnswer((_) async {});
      final sdk = buildSdk();

      await sdk.deleteReceivedRCard(stubCard.subjectDid);
      verify(() => mockRepo.deleteBySubjectDid(stubCard.subjectDid)).called(1);

      await sdk.closeRelationshipStreams();
    });
  });
}

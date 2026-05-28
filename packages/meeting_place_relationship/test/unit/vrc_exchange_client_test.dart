import 'dart:convert';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:meeting_place_relationship/src/vrc/vrc_exchange_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/mocks.dart';

void main() {
  late MockMeetingPlaceCoreSDK mockCoreSDK;
  late MockVdipClient mockVdipClient;
  late VrcExchangeClient client;

  Channel makeChannel({
    String id = 'channel-1',
    String permanentChannelDid = 'did:key:local',
    bool isInitiator = true,
  }) {
    final ch = MockChannel();
    when(() => ch.id).thenReturn(id);
    when(() => ch.permanentChannelDid).thenReturn(permanentChannelDid);
    when(() => ch.mediatorDid).thenReturn('did:key:mediator');
    when(() => ch.isConnectionInitiator).thenReturn(isInitiator);
    return ch;
  }

  setUp(() {
    mockVdipClient = MockVdipClient();
    mockCoreSDK = MockMeetingPlaceCoreSDK();
    when(() => mockCoreSDK.vdip).thenReturn(mockVdipClient);

    client = VrcExchangeClient(
      coreSDK: mockCoreSDK,
      logger: DefaultMeetingPlaceCoreSDKLogger(
        className: 'VrcExchangeClientTest',
      ),
    );
  });

  setUpAll(() {
    registerFallbackValue(MockChannel());
    registerFallbackValue(
      RequestCredentialsOptions(
        proposalId: '',
        credentialMeta: CredentialMeta(data: {}),
      ),
    );
    registerFallbackValue(FakeVdipIssuedCredentialBody());
  });

  group('VrcExchangeClient.requestExchange', () {
    test('sends requestIssuance with correct metadata', () async {
      final channel = makeChannel();
      when(
        () => mockCoreSDK.getChannelByOtherPartyPermanentDid('did:key:peer'),
      ).thenAnswer((_) async => channel);
      when(
        () => mockVdipClient.requestIssuance(
          senderDid: any(named: 'senderDid'),
          recipientDid: any(named: 'recipientDid'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      await client.requestExchange(
        channelDid: 'did:key:peer',
        identityDid: 'did:key:identity',
        identityName: 'Alice',
      );

      final captured = verify(
        () => mockVdipClient.requestIssuance(
          senderDid: any(named: 'senderDid'),
          recipientDid: any(named: 'recipientDid'),
          options: captureAny(named: 'options'),
        ),
      ).captured;
      final options = captured.single as RequestCredentialsOptions;
      final meta = options.credentialMeta!.data!;
      expect(
        meta[VrcConstants.requestMetadataKeyIdentityDid],
        equals('did:key:identity'),
      );
      expect(
        meta[VrcConstants.requestMetadataKeyIdentityName],
        equals('Alice'),
      );
      expect(
        meta[VrcConstants.requestMetadataKeyChannelId],
        equals('channel-1'),
      );
    });

    test('returns without sending when channel is null', () async {
      when(
        () => mockCoreSDK.getChannelByOtherPartyPermanentDid(any()),
      ).thenAnswer((_) async => null);

      await client.requestExchange(
        channelDid: 'did:key:unknown',
        identityDid: 'did:key:identity',
        identityName: 'Alice',
      );

      verifyNever(
        () => mockVdipClient.requestIssuance(
          senderDid: any(named: 'senderDid'),
          recipientDid: any(named: 'recipientDid'),
          options: any(named: 'options'),
        ),
      );
    });
  });

  group('VrcExchangeClient.sendVrc', () {
    late DidKeyManager issuerManager;
    late String issuerDid;

    setUpAll(() async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      issuerManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
      final keyPair = await wallet.generateKey();
      await issuerManager.addVerificationMethod(keyPair.id);
      final didDoc = await issuerManager.getDidDocument();
      issuerDid = didDoc.id;
    });

    test('builds, sends VRC and returns non-empty vcBlob', () async {
      final channel = makeChannel(permanentChannelDid: issuerDid);
      when(
        () => mockCoreSDK.getChannelByOtherPartyPermanentDid('did:key:peer'),
      ).thenAnswer((_) async => channel);
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

      final vcBlob = await client.sendVrc(
        channelDid: 'did:key:peer',
        issuerDid: issuerDid,
        issuerName: 'Alice',
        peerDid: 'did:key:peer',
        peerName: 'Bob',
      );

      expect(vcBlob, isNotEmpty);
      final decoded = jsonDecode(vcBlob) as Map<String, dynamic>;
      expect(decoded['type'], contains('RelationshipCredential'));
      verify(
        () => mockVdipClient.sendIssuedCredential(
          senderDid: any(named: 'senderDid'),
          recipientDid: any(named: 'recipientDid'),
          body: any(named: 'body'),
        ),
      ).called(1);
    });

    test(
      'throws MeetingPlaceRelationshipSDKException when channel is null',
      () async {
        when(
          () => mockCoreSDK.getChannelByOtherPartyPermanentDid(any()),
        ).thenAnswer((_) async => null);

        await expectLater(
          () => client.sendVrc(
            channelDid: 'did:key:unknown',
            issuerDid: issuerDid,
            issuerName: 'Alice',
            peerDid: 'did:key:peer',
            peerName: 'Bob',
          ),
          throwsA(isA<MeetingPlaceRelationshipSDKException>()),
        );
      },
    );
  });
}

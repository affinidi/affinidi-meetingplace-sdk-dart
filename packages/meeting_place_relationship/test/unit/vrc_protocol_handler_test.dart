import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:meeting_place_relationship/src/vrc/parser/vrc_parser.dart';
import 'package:meeting_place_relationship/src/vrc/vrc_exchange_client.dart';
import 'package:meeting_place_relationship/src/vrc/vrc_protocol_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/mocks.dart';

void main() {
  late String signedVrcBlob;
  late String signedVrcIssuerDid;

  setUpAll(() async {
    registerFallbackValue(MockParsedVC());

    final wallet = PersistentWallet(InMemoryKeyStore());
    final manager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
    final keyPair = await wallet.generateKey();
    await manager.addVerificationMethod(keyPair.id);
    final didDoc = await manager.getDidDocument();
    signedVrcIssuerDid = didDoc.id;

    final vc = await CredentialBuilder.buildVrc(
      issuerDid: signedVrcIssuerDid,
      subject: VrcCredentialSubject(
        from: VrcParty(did: signedVrcIssuerDid, name: 'Alice'),
        to: const VrcParty(did: 'did:key:peer', name: 'Bob'),
      ),
      issuerDidManager: manager,
    );
    signedVrcBlob = jsonEncode(vc.toJson());
  });

  VrcProtocolHandler makeHandler({
    VrcExchangeClient? client,
    VrcParser? parser,
  }) {
    return VrcProtocolHandler(
      client: client ?? MockVrcExchangeClient(),
      parser: parser ?? VrcParser(),
      logger: DefaultMeetingPlaceCoreSDKLogger(
        className: 'VrcProtocolHandlerTest',
      ),
    );
  }

  group('VrcProtocolHandler.handleReceivedVrcRequest', () {
    late MockVrcExchangeClient mockClient;

    setUp(() {
      mockClient = MockVrcExchangeClient();
    });

    test('returns prompt when exchange has not been initiated', () async {
      final handler = makeHandler(client: mockClient);

      final outcome = await handler.handleReceivedVrcRequest(
        permanentChannelDid: 'did:key:channel',
        request: VrcRequest(senderDid: 'did:key:sender'),
        hasVrcExchangeInitiated: false,
        isConnectionInitiator: true,
      );

      expect(outcome, VrcRequestProcessingResult.prompt);
      verifyNever(
        () => mockClient.sendVrc(
          channelDid: any(named: 'channelDid'),
          issuerDid: any(named: 'issuerDid'),
          issuerName: any(named: 'issuerName'),
          peerDid: any(named: 'peerDid'),
          peerName: any(named: 'peerName'),
        ),
      );
    });

    test('returns waiting when exchange initiated but local party is '
        'not initiator', () async {
      final handler = makeHandler(client: mockClient);

      final outcome = await handler.handleReceivedVrcRequest(
        permanentChannelDid: 'did:key:channel',
        request: VrcRequest(senderDid: 'did:key:sender'),
        hasVrcExchangeInitiated: true,
        isConnectionInitiator: false,
      );

      expect(outcome, VrcRequestProcessingResult.waiting);
    });

    test('returns prompt when local identity DID is missing', () async {
      final handler = makeHandler(client: mockClient);

      final outcome = await handler.handleReceivedVrcRequest(
        permanentChannelDid: 'did:key:channel',
        request: VrcRequest(senderDid: 'did:key:sender'),
        hasVrcExchangeInitiated: true,
        isConnectionInitiator: true,
        // no localIdentityDid
      );

      expect(outcome, VrcRequestProcessingResult.prompt);
      verifyNever(
        () => mockClient.sendVrc(
          channelDid: any(named: 'channelDid'),
          issuerDid: any(named: 'issuerDid'),
          issuerName: any(named: 'issuerName'),
          peerDid: any(named: 'peerDid'),
          peerName: any(named: 'peerName'),
        ),
      );
    });

    test(
      'returns prompt when peer identity DID is absent from request',
      () async {
        final handler = makeHandler(client: mockClient);

        final outcome = await handler.handleReceivedVrcRequest(
          permanentChannelDid: 'did:key:channel',
          request: VrcRequest(
            senderDid: 'did:key:sender',
            // no identityDid or selectedIdentity in credentialMetaData
          ),
          hasVrcExchangeInitiated: true,
          isConnectionInitiator: true,
          issuerDid: 'did:key:local',
        );

        expect(outcome, VrcRequestProcessingResult.prompt);
      },
    );

    test(
      'returns issued and sends VRC for simultaneous request when initiator',
      () async {
        when(
          () => mockClient.sendVrc(
            channelDid: any(named: 'channelDid'),
            issuerDid: any(named: 'issuerDid'),
            issuerName: any(named: 'issuerName'),
            peerDid: any(named: 'peerDid'),
            peerName: any(named: 'peerName'),
          ),
        ).thenAnswer((_) async => 'sent-vc-blob');

        final handler = makeHandler(client: mockClient);

        final outcome = await handler.handleReceivedVrcRequest(
          permanentChannelDid: 'did:key:channel',
          request: VrcRequest(
            senderDid: 'did:key:sender',
            credentialMetaData: {
              VrcConstants.requestMetadataKeyIdentityDid: 'did:key:peer',
              VrcConstants.requestMetadataKeyIdentityName: 'Bob',
            },
          ),
          hasVrcExchangeInitiated: true,
          isConnectionInitiator: true,
          issuerDid: 'did:key:local',
          issuerName: 'Alice',
        );

        expect(outcome, VrcRequestProcessingResult.issued);
        verify(
          () => mockClient.sendVrc(
            channelDid: 'did:key:channel',
            issuerDid: 'did:key:local',
            issuerName: 'Alice',
            peerDid: 'did:key:peer',
            peerName: 'Bob',
          ),
        ).called(1);
      },
    );

    test('invokes onVrcSent with the sent vcBlob when issued', () async {
      when(
        () => mockClient.sendVrc(
          channelDid: any(named: 'channelDid'),
          issuerDid: any(named: 'issuerDid'),
          issuerName: any(named: 'issuerName'),
          peerDid: any(named: 'peerDid'),
          peerName: any(named: 'peerName'),
        ),
      ).thenAnswer((_) async => 'sent-vc-blob');

      String? capturedBlob;
      final handler = makeHandler(client: mockClient);

      await handler.handleReceivedVrcRequest(
        permanentChannelDid: 'did:key:channel',
        request: VrcRequest(
          senderDid: 'did:key:sender',
          credentialMetaData: {
            VrcConstants.requestMetadataKeyIdentityDid: 'did:key:peer',
          },
        ),
        hasVrcExchangeInitiated: true,
        isConnectionInitiator: true,
        issuerDid: 'did:key:local',
        onVrcSent: (blob) => capturedBlob = blob,
      );

      expect(capturedBlob, 'sent-vc-blob');
    });
  });

  group('VrcProtocolHandler.handleReceivedVrc', () {
    late MockVrcExchangeClient mockClient;

    setUp(() {
      mockClient = MockVrcExchangeClient();
    });

    test('returns completed for initiator when both initiated '
        'and request received', () async {
      final handler = makeHandler(client: mockClient);

      final outcome = await handler.handleReceivedVrc(
        permanentChannelDid: 'did:key:channel',
        vcBlob: signedVrcBlob,
        exchangeState: const VrcExchangeState(
          hasVrcExchangeInitiated: true,
          hasVrcRequestReceived: true,
          isConnectionInitiator: true,
        ),
      );

      expect(outcome, VrcProcessingResult.completed);
    });

    test(
      'returns completed when request was received but exchange not initiated',
      () async {
        final handler = makeHandler(client: mockClient);

        final outcome = await handler.handleReceivedVrc(
          permanentChannelDid: 'did:key:channel',
          vcBlob: signedVrcBlob,
          exchangeState: const VrcExchangeState(
            hasVrcExchangeInitiated: false,
            hasVrcRequestReceived: true,
            isConnectionInitiator: true,
          ),
        );

        expect(outcome, VrcProcessingResult.completed);
      },
    );

    test(
      'returns ignored when neither initiated nor request received',
      () async {
        final handler = makeHandler(client: mockClient);

        final outcome = await handler.handleReceivedVrc(
          permanentChannelDid: 'did:key:channel',
          vcBlob: signedVrcBlob,
          exchangeState: const VrcExchangeState(
            hasVrcExchangeInitiated: false,
            hasVrcRequestReceived: false,
            isConnectionInitiator: true,
          ),
        );

        expect(outcome, VrcProcessingResult.ignored);
      },
    );

    test(
      'returns ignored when initiated but local identity DID is missing',
      () async {
        final handler = makeHandler(client: mockClient);

        final outcome = await handler.handleReceivedVrc(
          permanentChannelDid: 'did:key:channel',
          vcBlob: signedVrcBlob,
          exchangeState: const VrcExchangeState(
            hasVrcExchangeInitiated: true,
            hasVrcRequestReceived: false,
            isConnectionInitiator: true,
          ),
          // no issuerDid
        );

        expect(outcome, VrcProcessingResult.ignored);
        verifyNever(
          () => mockClient.sendVrc(
            channelDid: any(named: 'channelDid'),
            issuerDid: any(named: 'issuerDid'),
            issuerName: any(named: 'issuerName'),
            peerDid: any(named: 'peerDid'),
            peerName: any(named: 'peerName'),
          ),
        );
      },
    );

    test('returns ignored when credential subject is empty', () async {
      final mockParser = MockVrcParser();
      final mockParsed = MockParsedVC();
      when(
        () => mockParser.parse(vcBlob: any(named: 'vcBlob')),
      ).thenAnswer((_) async => mockParsed);
      when(() => mockParsed.credentialSubject).thenReturn(const []);

      final handler = makeHandler(client: mockClient, parser: mockParser);

      final outcome = await handler.handleReceivedVrc(
        permanentChannelDid: 'did:key:channel',
        vcBlob: 'any-blob',
        exchangeState: const VrcExchangeState(
          hasVrcExchangeInitiated: true,
          hasVrcRequestReceived: false,
          isConnectionInitiator: true,
        ),
        issuerDid: 'did:key:local',
      );

      expect(outcome, VrcProcessingResult.ignored);
    });

    test(
      'returns reciprocated and sends VRC when initiator receives peer VRC',
      () async {
        when(
          () => mockClient.sendVrc(
            channelDid: any(named: 'channelDid'),
            issuerDid: any(named: 'issuerDid'),
            issuerName: any(named: 'issuerName'),
            peerDid: any(named: 'peerDid'),
            peerName: any(named: 'peerName'),
          ),
        ).thenAnswer((_) async => 'sent-vc-blob');

        final handler = makeHandler(client: mockClient, parser: VrcParser());

        final outcome = await handler.handleReceivedVrc(
          permanentChannelDid: 'did:key:peer',
          vcBlob: signedVrcBlob,
          exchangeState: const VrcExchangeState(
            hasVrcExchangeInitiated: true,
            hasVrcRequestReceived: false,
            isConnectionInitiator: true,
          ),
          issuerDid: 'did:key:local',
          issuerName: 'Carol',
        );

        expect(outcome, VrcProcessingResult.reciprocated);
        verify(
          () => mockClient.sendVrc(
            channelDid: 'did:key:peer',
            issuerDid: 'did:key:local',
            issuerName: 'Carol',
            peerDid: signedVrcIssuerDid,
            peerName: 'Alice',
          ),
        ).called(1);
      },
    );

    test('invokes onVrcSent with the sent vcBlob when reciprocated', () async {
      when(
        () => mockClient.sendVrc(
          channelDid: any(named: 'channelDid'),
          issuerDid: any(named: 'issuerDid'),
          issuerName: any(named: 'issuerName'),
          peerDid: any(named: 'peerDid'),
          peerName: any(named: 'peerName'),
        ),
      ).thenAnswer((_) async => 'sent-vc-blob');

      String? capturedBlob;
      final handler = makeHandler(client: mockClient, parser: VrcParser());

      await handler.handleReceivedVrc(
        permanentChannelDid: 'did:key:peer',
        vcBlob: signedVrcBlob,
        exchangeState: const VrcExchangeState(
          hasVrcExchangeInitiated: true,
          hasVrcRequestReceived: false,
          isConnectionInitiator: true,
        ),
        issuerDid: 'did:key:local',
        issuerName: 'Carol',
        onVrcSent: (blob) => capturedBlob = blob,
      );

      expect(capturedBlob, 'sent-vc-blob');
    });

    test('returns reciprocated after waiting for non-initiator', () async {
      when(
        () => mockClient.sendVrc(
          channelDid: any(named: 'channelDid'),
          issuerDid: any(named: 'issuerDid'),
          issuerName: any(named: 'issuerName'),
          peerDid: any(named: 'peerDid'),
          peerName: any(named: 'peerName'),
        ),
      ).thenAnswer((_) async => 'sent-vc-blob');

      final handler = makeHandler(client: mockClient, parser: VrcParser());

      final outcome = await handler.handleReceivedVrc(
        permanentChannelDid: 'did:key:peer',
        vcBlob: signedVrcBlob,
        exchangeState: const VrcExchangeState(
          hasVrcExchangeInitiated: true,
          hasVrcRequestReceived: true,
          isConnectionInitiator: false,
        ),
        issuerDid: 'did:key:local',
        issuerName: 'Carol',
      );

      expect(outcome, VrcProcessingResult.reciprocated);
    });
  });
}

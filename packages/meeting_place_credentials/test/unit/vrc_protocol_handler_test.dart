import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:meeting_place_credentials/src/vrc/vrc_exchange_client.dart';
import 'package:meeting_place_credentials/src/vrc/vrc_protocol_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/mocks.dart';

void main() {
  late String signedVrcBlob;
  late String signedVrcIssuerDid;
  late String impersonatedVrcBlob;
  late String impersonatedSubjectDid;
  late MockDidResolver mockDidResolver;

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

    // A second, real, resolvable DID standing in for a victim identity: a
    // VC validly signed by `signedVrcIssuerDid` that falsely names this DID
    // as the subject's `from` party, to prove the signer/subject mismatch
    // is rejected rather than trusted.
    final victimManager = DidKeyManager(
      wallet: wallet,
      store: InMemoryDidStore(),
    );
    final victimKeyPair = await wallet.generateKey();
    await victimManager.addVerificationMethod(victimKeyPair.id);
    impersonatedSubjectDid = (await victimManager.getDidDocument()).id;

    final impersonatedVc = await CredentialBuilder.buildVrc(
      issuerDid: signedVrcIssuerDid,
      subject: VrcCredentialSubject(
        from: VrcParty(did: impersonatedSubjectDid, name: 'Victim'),
        to: const VrcParty(did: 'did:key:peer', name: 'Bob'),
      ),
      issuerDidManager: manager,
    );
    impersonatedVrcBlob = jsonEncode(impersonatedVc.toJson());
  });

  setUp(() {
    mockDidResolver = MockDidResolver();
    when(
      () => mockDidResolver.resolveDid(any()),
    ).thenAnswer((_) async => MockDidDocument());
  });

  VrcProtocolHandler makeHandler({
    VrcExchangeClient? client,
    VrcParser? parser,
    DidResolver? didResolver,
  }) {
    return VrcProtocolHandler(
      client: client ?? MockVrcExchangeClient(),
      parser: parser ?? VrcParser(),
      logger: DefaultMeetingPlaceCoreSDKLogger(
        className: 'VrcProtocolHandlerTest',
      ),
      didResolver: didResolver ?? mockDidResolver,
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

      expect(outcome, isA<VrcRequestProcessingResultPromptRequired>());
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

      expect(outcome, isA<VrcRequestProcessingResultWaiting>());
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

      expect(outcome, isA<VrcRequestProcessingResultPromptRequired>());
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

        expect(outcome, isA<VrcRequestProcessingResultPromptRequired>());
      },
    );

    test('returns unresolvable identity when peer identity DID cannot be '
        'resolved, without prompting or sending a VRC', () async {
      when(
        () => mockDidResolver.resolveDid('did:key:peer'),
      ).thenThrow(Exception('unresolvable DID'));
      final handler = makeHandler(client: mockClient);

      final outcome = await handler.handleReceivedVrcRequest(
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
      );

      expect(
        outcome,
        isA<VrcRequestProcessingResultUnresolvableIdentity>().having(
          (r) => r.peerDid,
          'peerDid',
          'did:key:peer',
        ),
      );
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

    test('retries and succeeds when the peer identity DID resolution times '
        'out once but then resolves, so a transient network blip is not '
        'treated as a definitively nonexistent DID', () async {
      when(
        () => mockClient.sendVrc(
          channelDid: any(named: 'channelDid'),
          issuerDid: any(named: 'issuerDid'),
          issuerName: any(named: 'issuerName'),
          peerDid: any(named: 'peerDid'),
          peerName: any(named: 'peerName'),
        ),
      ).thenAnswer((_) async => 'sent-vc-blob');

      var attempt = 0;
      when(() => mockDidResolver.resolveDid('did:key:peer')).thenAnswer((
        _,
      ) async {
        attempt++;
        if (attempt == 1) {
          throw TimeoutException('Request to resolver timed out');
        }
        return MockDidDocument();
      });
      final handler = makeHandler(client: mockClient);

      final outcome = await handler.handleReceivedVrcRequest(
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
      );

      expect(outcome, isA<VrcRequestProcessingResultIssued>());
      expect(attempt, greaterThan(1));
    });

    test('returns unresolvable identity after repeated timeouts exhaust '
        'retries, rather than retrying forever', () async {
      when(
        () => mockDidResolver.resolveDid('did:key:peer'),
      ).thenThrow(TimeoutException('Request to resolver timed out'));
      final handler = makeHandler(client: mockClient);

      final outcome = await handler.handleReceivedVrcRequest(
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
      );

      expect(outcome, isA<VrcRequestProcessingResultUnresolvableIdentity>());
    });

    test('returns prompt (not unresolvable identity) when exchange has not '
        'been initiated, even if the peer identity DID cannot be resolved: '
        'this path never uses peerDid, so resolution failures must not block '
        'prompting the user', () async {
      when(
        () => mockDidResolver.resolveDid('did:key:peer'),
      ).thenThrow(Exception('unresolvable DID'));
      final handler = makeHandler(client: mockClient);

      final outcome = await handler.handleReceivedVrcRequest(
        permanentChannelDid: 'did:key:channel',
        request: VrcRequest(
          senderDid: 'did:key:sender',
          credentialMetaData: {
            VrcConstants.requestMetadataKeyIdentityDid: 'did:key:peer',
          },
        ),
        hasVrcExchangeInitiated: false,
        isConnectionInitiator: true,
      );

      expect(outcome, isA<VrcRequestProcessingResultPromptRequired>());
    });

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

        expect(outcome, isA<VrcRequestProcessingResultIssued>());
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

    test('returns sentVcBlob in result when issued', () async {
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
          },
        ),
        hasVrcExchangeInitiated: true,
        isConnectionInitiator: true,
        issuerDid: 'did:key:local',
      );

      expect(
        outcome,
        isA<VrcRequestProcessingResultIssued>().having(
          (r) => r.sentVcBlob,
          'sentVcBlob',
          'sent-vc-blob',
        ),
      );
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

      expect(outcome, isA<VrcProcessingResultCompleted>());
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

        expect(outcome, isA<VrcProcessingResultCompleted>());
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

        expect(outcome, isA<VrcProcessingResultIgnored>());
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

        expect(outcome, isA<VrcProcessingResultIgnored>());
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

      expect(outcome, isA<VrcProcessingResultIgnored>());
    });

    test(
      'returns ignored, and never reciprocates, when the VC is validly '
      'signed but the claimed subject "from" DID does not match the '
      'signer: a peer could sign as itself while naming a different, '
      'resolvable DID as the subject to impersonate that other party',
      () async {
        final handler = makeHandler(client: mockClient, parser: VrcParser());

        final outcome = await handler.handleReceivedVrc(
          permanentChannelDid: 'did:key:peer',
          vcBlob: impersonatedVrcBlob,
          exchangeState: const VrcExchangeState(
            hasVrcExchangeInitiated: true,
            hasVrcRequestReceived: false,
            isConnectionInitiator: true,
          ),
          issuerDid: 'did:key:local',
          issuerName: 'Carol',
        );

        expect(outcome, isA<VrcProcessingResultIgnored>());
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

        expect(outcome, isA<VrcProcessingResultReciprocated>());
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

    test('returns sentVcBlob in result when reciprocated', () async {
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

      expect(
        outcome,
        isA<VrcProcessingResultReciprocated>().having(
          (r) => r.sentVcBlob,
          'sentVcBlob',
          'sent-vc-blob',
        ),
      );
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

      expect(outcome, isA<VrcProcessingResultReciprocated>());
    });

    test('returns ignored when the peer identity DID in the received VRC '
        'cannot be resolved, without reciprocating', () async {
      when(
        () => mockDidResolver.resolveDid(signedVrcIssuerDid),
      ).thenThrow(Exception('unresolvable DID'));

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

      expect(outcome, isA<VrcProcessingResultIgnored>());
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

    test('returns ignored when exchange is already completed', () async {
      final handler = makeHandler(client: mockClient, parser: VrcParser());

      final outcome = await handler.handleReceivedVrc(
        permanentChannelDid: 'did:key:peer',
        vcBlob: signedVrcBlob,
        exchangeState: const VrcExchangeState(
          hasVrcExchangeInitiated: true,
          hasVrcRequestReceived: true,
          isConnectionInitiator: true,
          hasVrcExchangeCompleted: true,
        ),
      );

      expect(outcome, isA<VrcProcessingResultIgnored>());
    });
  });
}

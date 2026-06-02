import 'dart:async';
import 'dart:convert';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:meeting_place_credentials/src/vrc/parser/vrc_parser.dart';
import 'package:meeting_place_credentials/src/vrc/vrc_vdip_stream_manager.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

void main() {
  group('VrcVdipStreamManager', () {
    late String signedVrcBlob;
    late String issuerDid;

    setUpAll(() async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      final manager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());
      final keyPair = await wallet.generateKey();
      await manager.addVerificationMethod(keyPair.id);
      final didDoc = await manager.getDidDocument();
      issuerDid = didDoc.id;

      final vc = await CredentialBuilder.buildVrc(
        issuerDid: issuerDid,
        subject: VrcCredentialSubject(
          from: VrcParty(did: issuerDid, name: 'Alice'),
          to: const VrcParty(did: 'did:key:peer', name: 'Bob'),
        ),
        issuerDidManager: manager,
      );
      signedVrcBlob = jsonEncode(vc.toJson());
    });

    VrcVdipStreamManager makeManager(StreamController<PlainTextMessage> ctrl) {
      return VrcVdipStreamManager(
        incomingVdipMessages: ctrl.stream,
        parser: VrcParser(),
        logger: DefaultMeetingPlaceCoreSDKLogger(
          className: 'VrcVdipStreamManagerTest',
        ),
      );
    }

    test(
      'emits ReceivedVrcRequest for a valid request issuance message',
      () async {
        final ctrl = StreamController<PlainTextMessage>();
        final manager = makeManager(ctrl);
        final events = <VrcRequest>[];
        final sub = manager.requests.listen(events.add);

        ctrl.add(
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
        expect(events.single.channelId, 'channel-1');
        expect(events.single.identityDid, 'did:key:peer');

        await sub.cancel();
        await manager.close();
        await ctrl.close();
      },
    );

    test('skips request issuance message without sender DID', () async {
      final ctrl = StreamController<PlainTextMessage>();
      final manager = makeManager(ctrl);
      final events = <VrcRequest>[];
      final sub = manager.requests.listen(events.add);

      ctrl.add(
        PlainTextMessage(
          id: 'msg-2',
          type: VdipRequestIssuanceMessage.messageType,
          body: const {'proposal_id': 'proposal-2'},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(events, isEmpty);

      await sub.cancel();
      await manager.close();
      await ctrl.close();
    });

    test(
      'emits VrcIssuance for a valid signed issued-credential message',
      () async {
        final ctrl = StreamController<PlainTextMessage>();
        final manager = makeManager(ctrl);
        final events = <VrcIssuance>[];
        final sub = manager.receivedVrcs.listen(events.add);

        ctrl.add(
          PlainTextMessage(
            id: 'msg-3',
            type: VdipIssuedCredentialMessage.messageType,
            from: issuerDid,
            to: const ['did:key:recipient'],
            body: {
              'credential': signedVrcBlob,
              'credential_format': CredentialsSDKConstants.w3cLdV1,
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(events, hasLength(1));
        expect(events.single.senderDid, issuerDid);
        expect(events.single.vcBlob, signedVrcBlob);

        await sub.cancel();
        await manager.close();
        await ctrl.close();
      },
    );

    test(
      'skips issued-credential message with empty credential blob',
      () async {
        final ctrl = StreamController<PlainTextMessage>();
        final manager = makeManager(ctrl);
        final events = <VrcIssuance>[];
        final sub = manager.receivedVrcs.listen(events.add);

        ctrl.add(
          PlainTextMessage(
            id: 'msg-4',
            type: VdipIssuedCredentialMessage.messageType,
            from: 'did:key:sender',
            body: const {
              'credential': '',
              'credential_format': CredentialsSDKConstants.w3cLdV1,
            },
          ),
        );
        await Future<void>.delayed(Duration.zero);

        expect(events, isEmpty);

        await sub.cancel();
        await manager.close();
        await ctrl.close();
      },
    );

    test(
      'consumePendingRequest returns and removes the cached request',
      () async {
        final ctrl = StreamController<PlainTextMessage>();
        final manager = makeManager(ctrl);

        ctrl.add(
          PlainTextMessage(
            id: 'msg-5',
            type: VdipRequestIssuanceMessage.messageType,
            from: 'did:key:sender',
            body: const {'proposal_id': 'proposal-5'},
          ),
        );
        await Future<void>.delayed(Duration.zero);

        final first = manager.consumePendingRequest('did:key:sender');
        final second = manager.consumePendingRequest('did:key:sender');
        expect(first, isNotNull);
        expect(second, isNull);

        await manager.close();
        await ctrl.close();
      },
    );

    test('close() is idempotent — second call does not throw', () async {
      final ctrl = StreamController<PlainTextMessage>();
      final manager = makeManager(ctrl);

      await manager.close();
      await expectLater(manager.close(), completes);
      await ctrl.close();
    });

    test(
      'discards issued-credential when vcBlob issuerDid does not match sender',
      () async {
        final ctrl = StreamController<PlainTextMessage>();
        final manager = makeManager(ctrl);
        final events = <VrcIssuance>[];
        final sub = manager.receivedVrcs.listen(events.add);

        // signedVrcBlob is signed by issuerDid; relay attacker forwards it
        // with their own DID as the message sender.
        ctrl.add(
          PlainTextMessage(
            id: 'msg-relay',
            type: VdipIssuedCredentialMessage.messageType,
            from: 'did:key:relay-attacker',
            to: const ['did:key:recipient'],
            body: {
              'credential': signedVrcBlob,
              'credential_format': CredentialsSDKConstants.w3cLdV1,
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(events, isEmpty);
        expect(manager.consumePendingVrc(issuerDid), isNull);
        expect(manager.consumePendingVrc('did:key:relay-attacker'), isNull);

        await sub.cancel();
        await manager.close();
        await ctrl.close();
      },
    );
  });
}

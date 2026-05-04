import 'dart:async';
import 'dart:convert';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:meeting_place_credentials/src/shared/credentials_vdip_stream_manager.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

void main() {
  group('CredentialsVdipStreamManager', () {
    late String issuerDid;
    late String rCardBlob;
    late String vrcBlob;

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

      final rCard = await CredentialBuilder.buildRCard(
        issuerDid: issuerDid,
        subjectDid: issuerDid,
        subject: const RCardSubject(firstName: 'Alice', lastName: 'Test'),
        issuerDidManager: didManager,
      );
      rCardBlob = jsonEncode(rCard.toJson());

      final vrc = await CredentialBuilder.buildVrc(
        issuerDid: issuerDid,
        subject: VrcCredentialSubject(
          from: VrcParty(did: issuerDid, name: 'Alice'),
          to: const VrcParty(did: 'did:key:peer', name: 'Bob'),
        ),
        issuerDidManager: didManager,
      );
      vrcBlob = jsonEncode(vrc.toJson());
    });

    CredentialsVdipStreamManager makeManager(
      StreamController<PlainTextMessage> ctrl,
    ) {
      return CredentialsVdipStreamManager(
        incomingVdipMessages: ctrl.stream,
        logger: DefaultMeetingPlaceCoreSDKLogger(
          className: 'CredentialsVdipStreamManagerTest',
        ),
      );
    }

    test('routes request-issuance messages to the VRC stream', () async {
      final ctrl = StreamController<PlainTextMessage>.broadcast();
      final manager = makeManager(ctrl);
      final routed = <PlainTextMessage>[];
      final sub = manager.vrcMessages.listen(routed.add);

      ctrl.add(
        PlainTextMessage(
          id: 'msg-1',
          type: VdipRequestIssuanceMessage.messageType,
          from: issuerDid,
          body: const {'proposal_id': 'proposal-1'},
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(routed, hasLength(1));
      expect(routed.single.type, VdipRequestIssuanceMessage.messageType);
      await sub.cancel();
      await manager.close();
      await ctrl.close();
    });

    test('routes issued R-Cards to the R-Card stream', () async {
      final ctrl = StreamController<PlainTextMessage>.broadcast();
      final manager = makeManager(ctrl);
      final routed = <PlainTextMessage>[];
      final sub = manager.rCardMessages.listen(routed.add);

      final message = PlainTextMessage(
        id: 'msg-2',
        type: VdipIssuedCredentialMessage.messageType,
        from: issuerDid,
        body: {
          'credential': rCardBlob,
          'credential_format': CredentialsSDKConstants.w3cV2,
        },
      );

      ctrl.add(message);

      await Future<void>.delayed(Duration.zero);

      expect(routed, hasLength(1));
      expect(manager.isRCardIssuedCredentialMessage(message), isTrue);
      await sub.cancel();
      await manager.close();
      await ctrl.close();
    });

    test('routes issued VRCs to the VRC stream', () async {
      final ctrl = StreamController<PlainTextMessage>.broadcast();
      final manager = makeManager(ctrl);
      final routed = <PlainTextMessage>[];
      final sub = manager.vrcMessages.listen(routed.add);

      final message = PlainTextMessage(
        id: 'msg-3',
        type: VdipIssuedCredentialMessage.messageType,
        from: issuerDid,
        body: {
          'credential': vrcBlob,
          'credential_format': CredentialsSDKConstants.w3cV2,
        },
      );

      ctrl.add(message);

      await Future<void>.delayed(Duration.zero);

      expect(routed, hasLength(1));
      expect(manager.isRCardIssuedCredentialMessage(message), isFalse);
      await sub.cancel();
      await manager.close();
      await ctrl.close();
    });

    test('skips unknown issued credentials', () async {
      final ctrl = StreamController<PlainTextMessage>.broadcast();
      final manager = makeManager(ctrl);
      final rCardMessages = <PlainTextMessage>[];
      final vrcMessages = <PlainTextMessage>[];
      final rCardSub = manager.rCardMessages.listen(rCardMessages.add);
      final vrcSub = manager.vrcMessages.listen(vrcMessages.add);

      ctrl.add(
        PlainTextMessage(
          id: 'msg-4',
          type: VdipIssuedCredentialMessage.messageType,
          from: issuerDid,
          body: {
            'credential': jsonEncode({
              '@context': ['https://example.com/unknown'],
              'type': ['VerifiableCredential', 'UnknownCredential'],
            }),
            'credential_format': CredentialsSDKConstants.w3cV2,
          },
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(rCardMessages, isEmpty);
      expect(vrcMessages, isEmpty);
      await rCardSub.cancel();
      await vrcSub.cancel();
      await manager.close();
      await ctrl.close();
    });
  });
}

import 'dart:async';
import 'dart:convert';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:meeting_place_credentials/src/rcard/parser/r_card_parser.dart';
import 'package:meeting_place_credentials/src/rcard/r_card_vdip_stream_manager.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  group('RCardVdipStreamManager', () {
    late String vcBlob;
    late String issuerDid;

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
        subject: const RCardSubject(firstName: 'Alice', lastName: 'Test'),
        issuerDidManager: didManager,
      );
      vcBlob = jsonEncode(vc.toJson());
    });

    RCardVdipStreamManager makeManager(
      StreamController<PlainTextMessage> ctrl,
    ) {
      return RCardVdipStreamManager(
        incomingVdipMessages: ctrl.stream,
        parser: RCardParser(),
        logger: DefaultMeetingPlaceCoreSDKLogger(
          className: 'RCardVdipStreamManagerTest',
        ),
      );
    }

    test('valid signed R-Card emits a RCard', () async {
      final ctrl = StreamController<PlainTextMessage>.broadcast();
      final manager = makeManager(ctrl);
      final emitted = <RCard>[];
      final sub = manager.stream.listen(emitted.add);

      ctrl.add(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: VdipIssuedCredentialMessage.messageType,
          from: issuerDid,
          to: ['did:example:recipient'],
          body: {
            'credential': vcBlob,
            'credential_format': CredentialsSDKConstants.w3cLdV1,
          },
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emitted, hasLength(1));
      expect(emitted.first.issuerDid, issuerDid);
      await sub.cancel();
      await manager.close();
      await ctrl.close();
    });

    test('request-issuance type does not emit', () async {
      final ctrl = StreamController<PlainTextMessage>.broadcast();
      final manager = makeManager(ctrl);
      final emitted = <RCard>[];
      final sub = manager.stream.listen(emitted.add);

      ctrl.add(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: VdipRequestIssuanceMessage.messageType,
          from: issuerDid,
          to: ['did:example:recipient'],
          body: {
            'credential': vcBlob,
            'credential_format': CredentialsSDKConstants.w3cLdV1,
          },
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await manager.close();
      await ctrl.close();
    });

    test('missing from field emits a stream error', () async {
      final ctrl = StreamController<PlainTextMessage>.broadcast();
      final manager = makeManager(ctrl);
      final emitted = <RCard>[];
      final errors = <Object>[];
      final sub = manager.stream.listen(emitted.add, onError: errors.add);

      ctrl.add(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: VdipIssuedCredentialMessage.messageType,
          body: {
            'credential': vcBlob,
            'credential_format': CredentialsSDKConstants.w3cLdV1,
          },
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      expect(errors, hasLength(1));
      expect(errors.first, isA<FormatException>());
      await sub.cancel();
      await manager.close();
      await ctrl.close();
    });

    test('unsupported credential_format does not emit', () async {
      final ctrl = StreamController<PlainTextMessage>.broadcast();
      final manager = makeManager(ctrl);
      final emitted = <RCard>[];
      final sub = manager.stream.listen(emitted.add);

      ctrl.add(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: VdipIssuedCredentialMessage.messageType,
          from: issuerDid,
          body: {'credential': vcBlob, 'credential_format': 'unsupported/v99'},
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await manager.close();
      await ctrl.close();
    });

    test(
      'R-Card with mismatched issuerDid is discarded — relay attack blocked',
      () async {
        final ctrl = StreamController<PlainTextMessage>.broadcast();
        final manager = makeManager(ctrl);
        final emitted = <RCard>[];
        final sub = manager.stream.listen(emitted.add);

        // Send a message where `from` is an attacker DID but the VC blob
        // was signed by issuerDid — simulates a relay/replay attack.
        ctrl.add(
          PlainTextMessage(
            id: const Uuid().v4(),
            type: VdipIssuedCredentialMessage.messageType,
            from: 'did:key:relay-attacker',
            to: ['did:example:recipient'],
            body: {
              'credential': vcBlob,
              'credential_format': CredentialsSDKConstants.w3cLdV1,
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(emitted, isEmpty);
        expect(manager.consumePendingRCard('did:key:relay-attacker'), isNull);
        expect(manager.consumePendingRCard(issuerDid), isNull);

        await sub.cancel();
        await manager.close();
        await ctrl.close();
      },
    );

    test('consumePendingRCard returns and removes the cached R-Card', () async {
      final ctrl = StreamController<PlainTextMessage>.broadcast();
      final manager = makeManager(ctrl);
      final sub = manager.stream.listen((_) {});

      ctrl.add(
        PlainTextMessage(
          id: const Uuid().v4(),
          type: VdipIssuedCredentialMessage.messageType,
          from: issuerDid,
          to: ['did:example:recipient'],
          body: {
            'credential': vcBlob,
            'credential_format': CredentialsSDKConstants.w3cLdV1,
          },
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final first = manager.consumePendingRCard(issuerDid);
      final second = manager.consumePendingRCard(issuerDid);
      expect(first, isNotNull);
      expect(first!.issuerDid, issuerDid);
      expect(second, isNull);

      await sub.cancel();
      await manager.close();
      await ctrl.close();
    });

    test('consumePendingRCard returns null when sender not found', () async {
      final ctrl = StreamController<PlainTextMessage>.broadcast();
      final manager = makeManager(ctrl);

      expect(manager.consumePendingRCard('did:key:unknown'), isNull);

      await manager.close();
      await ctrl.close();
    });

    test(
      'R-Card is stored in pending cache even with no stream listener',
      () async {
        final ctrl = StreamController<PlainTextMessage>.broadcast();
        // Intentionally no listener attached to manager.stream.
        final manager = makeManager(ctrl);

        ctrl.add(
          PlainTextMessage(
            id: const Uuid().v4(),
            type: VdipIssuedCredentialMessage.messageType,
            from: issuerDid,
            to: ['did:example:recipient'],
            body: {
              'credential': vcBlob,
              'credential_format': CredentialsSDKConstants.w3cLdV1,
            },
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Cache is populated even though no subscriber was ever attached.
        final cached = manager.consumePendingRCard(issuerDid);
        expect(cached, isNotNull);
        expect(cached!.issuerDid, issuerDid);

        await manager.close();
        await ctrl.close();
      },
    );

    test('close() is idempotent — does not throw on second call', () async {
      final ctrl = StreamController<PlainTextMessage>.broadcast();
      final manager = makeManager(ctrl);
      await manager.close();
      await expectLater(manager.close(), completes);
      await ctrl.close();
    });
  });
}

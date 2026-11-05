import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fake_vta.dart';

void main() {
  late FakeVta vta;
  late Ed25519DidKeySigner manager;
  late DidcommVtaTransport transport;

  Future<TrustTaskDocument> request(String type) => TrustTaskDocument.create(
    type: type,
    issuer: manager.did,
    recipient: vta.did,
    payload: const {},
  ).sign(manager, purpose: ProofPurpose.authentication);

  Matcher failsWith(MeetingPlaceVtcSDKErrorCode code) => throwsA(
    isA<MeetingPlaceVtcSDKException>().having((e) => e.code, 'code', code),
  );

  setUp(() {
    vta = FakeVta();
    manager = Ed25519DidKeySigner.generate();
    transport = vta.transport(manager, timeout: const Duration(seconds: 1));
  });

  group('DidcommVtaTransport', () {
    test('forwards the signed document through the VTA mediator', () async {
      vta.answers[VtaTask.whoAmI] = {'roles': <String>[]};
      final sent = await request(VtaTask.whoAmI);

      final answer = await transport.send(sent);

      final forward = vta.forwarded.single;
      expect(forward.to, [vta.mediatorDid]);
      expect(forward.next, vta.did);
      expect(vta.received.single, sent.toJson());
      expect(answer.threadId, sent.id);
      expect(answer.issuer, vta.did);
    });

    test('drops stale answers waiting in the inbox', () async {
      vta.answers[VtaTask.whoAmI] = {'roles': <String>[]};
      await transport.send(await request(VtaTask.whoAmI));
      // The first answer, delivered again.
      vta.inbox.add(vta.sentAnswers.single);

      final sent = await request(VtaTask.whoAmI);
      final answer = await transport.send(sent);

      expect(answer.threadId, sent.id);
    });

    test('does not send again a task without an answer', () async {
      vta.isSilent = true;
      final quick = vta.transport(
        manager,
        timeout: const Duration(milliseconds: 50),
      );

      await expectLater(
        quick.send(await request(VtaTask.whoAmI)),
        failsWith(MeetingPlaceVtcSDKErrorCode.transportFailed),
      );
      expect(vta.received, hasLength(1));
    });

    test('reads a Trust Task error as a refusal', () async {
      vta.refusals[VtaTask.whoAmI] = {'code': 'auth/whoami:notAuthorized'};

      await expectLater(
        transport.send(await request(VtaTask.whoAmI)),
        throwsA(
          isA<MeetingPlaceVtcSDKException>()
              .having(
                (e) => e.code,
                'code',
                MeetingPlaceVtcSDKErrorCode.refused,
              )
              .having(
                (e) => e.refusalCode,
                'refusalCode',
                'auth/whoami:notAuthorized',
              ),
        ),
      );
    });

    test('reads a DIDComm problem report as a refusal', () async {
      vta.problemCode = 'e.p.msg.unauthorized';

      await expectLater(
        transport.send(await request(VtaTask.whoAmI)),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.refusalCode,
            'refusalCode',
            'e.p.msg.unauthorized',
          ),
        ),
      );
    });

    test('says when the mediator cannot be reached', () async {
      vta.isMediatorDown = true;

      await expectLater(
        transport.send(await request(VtaTask.whoAmI)),
        failsWith(MeetingPlaceVtcSDKErrorCode.transportFailed),
      );
    });

    test('sends one task at a time, each with its own answer', () async {
      vta.answers[VtaTask.whoAmI] = {'roles': <String>[]};
      vta.answers[VtaTask.didsList] = {'dids': <Object>[]};
      final first = await request(VtaTask.whoAmI);
      final second = await request(VtaTask.didsList);

      final answers = await Future.wait([
        transport.send(first),
        transport.send(second),
      ]);

      expect(answers[0].threadId, first.id);
      expect(answers[1].threadId, second.id);
    });
  });

  group('mediatorDidOf', () {
    DidDocument withEndpoint(Object endpoint) => DidDocument.fromJson(
      DidKey.resolve(manager.did).toJson()
        ..['service'] = [
          {
            'id': '${manager.did}#didcomm',
            'type': 'DIDCommMessaging',
            'serviceEndpoint': endpoint,
          },
        ],
    );

    test('reads the mediator DID from each endpoint shape', () {
      expect(
        mediatorDidOf(withEndpoint('did:web:m.example')),
        'did:web:m.example',
      );
      expect(
        mediatorDidOf(withEndpoint({'uri': 'did:web:m.example'})),
        'did:web:m.example',
      );
      expect(
        mediatorDidOf(
          withEndpoint([
            {'uri': 'https://m.example'},
            {'uri': 'did:web:m.example'},
          ]),
        ),
        'did:web:m.example',
      );
    });

    test('names no mediator for an HTTPS endpoint', () {
      expect(mediatorDidOf(withEndpoint('https://m.example')), isNull);
    });
  });
}

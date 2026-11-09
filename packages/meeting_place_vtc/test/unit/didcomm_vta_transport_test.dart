import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:meeting_place_vtc/src/transport/didcomm_vta_transport.dart'
    show vtaForwardMessageOptions;
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

  /// Waits until [count] tasks reached the VTA.
  Future<void> untilReceived(int count) async {
    final deadline = DateTime.now().add(const Duration(seconds: 1));
    while (vta.received.length < count) {
      if (DateTime.now().isAfter(deadline)) {
        fail('${vta.received.length} of $count tasks reached the VTA');
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

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
      expect(forward.from, manager.did);
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

    test(
      'carries several tasks at once, matching each answer to its task',
      () async {
        vta.answers[VtaTask.whoAmI] = {'roles': <String>[]};
        vta.answers[VtaTask.didsList] = {'dids': <Object>[]};
        vta.holdsAnswers = true;
        final first = await request(VtaTask.whoAmI);
        final second = await request(VtaTask.didsList);

        final answers = Future.wait([
          transport.send(first),
          transport.send(second),
        ]);
        await untilReceived(2);
        vta.releaseAnswers(reversed: true);

        final [firstAnswer, secondAnswer] = await answers;
        expect(firstAnswer.threadId, first.id);
        expect(secondAnswer.threadId, second.id);
      },
    );

    test('fails only the task the VTA refused', () async {
      vta.refusals[VtaTask.whoAmI] = {'code': 'auth/whoami:notAuthorized'};
      vta.answers[VtaTask.didsList] = {'dids': <Object>[]};
      final refused = await request(VtaTask.whoAmI);
      final answered = await request(VtaTask.didsList);

      final refusal = transport.send(refused);
      final answer = transport.send(answered);

      await expectLater(
        refusal,
        failsWith(MeetingPlaceVtcSDKErrorCode.refused),
      );
      expect((await answer).threadId, answered.id);
    });

    test('fails every waiting task when the inbox is unreadable', () async {
      vta.holdsAnswers = true;
      final first = await request(VtaTask.whoAmI);
      final second = await request(VtaTask.didsList);

      final sends = [transport.send(first), transport.send(second)];
      await untilReceived(2);
      vta.isMediatorDown = true;

      for (final send in sends) {
        await expectLater(
          send,
          failsWith(MeetingPlaceVtcSDKErrorCode.transportFailed),
        );
      }
    });

    test('opens the mailbox once for tasks sent together', () async {
      vta.answers[VtaTask.whoAmI] = {'roles': <String>[]};
      var opened = 0;
      final counting = DidcommVtaTransport(
        vtaDid: vta.did,
        manager: manager,
        didResolver: FakeVtaResolver(vta),
        openMailbox:
            ({
              required mediatorDid,
              required mediatorDocument,
              required manager,
            }) {
              opened++;
              return vta.openMailbox(
                mediatorDid: mediatorDid,
                mediatorDocument: mediatorDocument,
                manager: manager,
              );
            },
        timeout: const Duration(seconds: 1),
        pollInterval: const Duration(milliseconds: 5),
      );

      await Future.wait([
        counting.send(await request(VtaTask.whoAmI)),
        counting.send(await request(VtaTask.whoAmI)),
      ]);

      expect(opened, 1);
    });
  });

  group('vtaForwardMessageOptions', () {
    test('signs the forward, as mediators refuse anonymous ones', () {
      expect(vtaForwardMessageOptions.shouldSign, isTrue);
      expect(vtaForwardMessageOptions.shouldEncrypt, isTrue);
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

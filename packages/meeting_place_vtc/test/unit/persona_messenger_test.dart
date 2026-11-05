import 'dart:convert';

import 'package:didcomm/didcomm.dart' hide TrustTaskDocument;
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fake_persona.dart';

/// A peer's mediator, in memory.
class _FakeOutbox implements MediatorOutbox {
  final List<ForwardMessage> sent = [];
  bool isClosed = false;
  Exception? failure;

  @override
  Future<void> send(ForwardMessage message) async {
    if (failure case final failure?) throw failure;
    sent.add(message);
  }

  @override
  Future<void> close() async => isClosed = true;
}

/// Resolves the documents it was given and `did:key`s, offline.
class _Resolver implements DidResolver {
  _Resolver(this.documents);

  final Map<String, DidDocument> documents;

  @override
  Future<DidDocument> resolveDid(String did) async =>
      documents[did] ??
      (did.startsWith('did:key:')
          ? DidKey.resolve(did)
          : throw StateError('unknown $did'));
}

void main() {
  const sessionResponse =
      'https://trusttasks.org/spec/vetting/session/0.1#response';
  late Ed25519DidKeySigner mediator;
  late FakePersona applicant;
  late FakePersona vetter;
  late PersonaDidManager applicantKeys;
  late _FakeOutbox outbox;
  late PersonaMessenger messenger;
  String? openedMediator;

  Matcher failsWith(MeetingPlaceVtcSDKErrorCode code) => throwsA(
    isA<MeetingPlaceVtcSDKException>().having((e) => e.code, 'code', code),
  );

  Future<PersonaDidManager> keysOf(FakePersona persona) =>
      PersonaDidManager.borrow(
        document: persona.document,
        signingSeed: persona.signingSeed,
        keyAgreementKey: persona.keyAgreementKey,
      );

  PersonaMessenger messengerFor(Map<String, DidDocument> documents) =>
      PersonaMessenger(
        persona: applicantKeys,
        didResolver: _Resolver(documents),
        openOutbox:
            ({
              required String mediatorDid,
              required DidDocument mediatorDocument,
              required DidManager manager,
            }) async {
              openedMediator = mediatorDid;
              return outbox;
            },
      );

  // The messenger carries a document as it is; signing it is the caller's.
  TrustTaskDocument answer({String? recipient}) => TrustTaskDocument.create(
    type: sessionResponse,
    issuer: applicant.did,
    recipient: recipient ?? vetter.did,
    threadId: 'urn:uuid:session',
    payload: const {
      'card': {'id': 'urn:uuid:card'},
    },
  );

  setUp(() async {
    mediator = Ed25519DidKeySigner.generate();
    applicant = FakePersona();
    vetter = FakePersona(mediatorDid: mediator.did);
    applicantKeys = await keysOf(applicant);
    outbox = _FakeOutbox();
    openedMediator = null;
    messenger = messengerFor({
      applicant.did: applicant.document,
      vetter.did: vetter.document,
    });
  });

  test('seals the document to the peer, through its mediator', () async {
    final document = answer();

    await messenger.send(document);

    expect(openedMediator, mediator.did);
    expect(outbox.isClosed, isTrue);
    final forward = outbox.sent.single;
    expect(forward.next, vetter.did);
    final sealed =
        jsonDecode(
              utf8.decode(
                base64Url.decode(
                  base64Url.normalize(
                    forward.attachments!.single.data!.base64!,
                  ),
                ),
              ),
            )
            as Map<String, dynamic>;
    final message = await DidcommMessage.unpackToPlainTextMessage(
      message: sealed,
      recipientDidManager: await keysOf(vetter),
      expectedMessageWrappingTypes: const [
        MessageWrappingType.authcryptPlaintext,
      ],
    );
    expect(message.type.toString(), sessionResponse);
    expect(message.from, applicant.did);
    expect(message.id, document.id);
    expect(message.threadId, 'urn:uuid:session');
    expect(message.body, document.toJson());
  });

  test('refuses a peer that names no DIDComm mediator', () async {
    final unreachable = FakePersona();
    messenger = messengerFor({
      applicant.did: applicant.document,
      unreachable.did: unreachable.document,
    });

    expect(
      messenger.send(answer(recipient: unreachable.did)),
      failsWith(MeetingPlaceVtcSDKErrorCode.signInNotOffered),
    );
  });

  test('says when the peer cannot be resolved', () async {
    messenger = messengerFor({applicant.did: applicant.document});

    expect(
      messenger.send(answer()),
      failsWith(MeetingPlaceVtcSDKErrorCode.didResolutionFailed),
    );
  });

  test('says when the mediator refuses', () async {
    outbox.failure = Exception('refused');

    await expectLater(
      messenger.send(answer()),
      failsWith(MeetingPlaceVtcSDKErrorCode.transportFailed),
    );
    expect(outbox.isClosed, isTrue);
  });
}

import 'package:didcomm/didcomm.dart' hide TrustTaskDocument;
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

import '../utils/fake_vta.dart';

const _groupDid = 'did:webvh:QmGroup:vtc.example:group-dids:g1';
const _communityDid = 'did:webvh:QmVtc:vtc.example';
const _personaDid = 'did:webvh:QmPersona:dids.example:persona';
const _memberDid = 'did:web:mpx.example:user:member';

void main() {
  final presentation = {
    'type': ['VerifiablePresentation'],
    'holder': _personaDid,
    'nonce': _memberDid,
    'domain': _groupDid,
  };
  final authority = {
    'id': 'urn:uuid:group-authority',
    'type': ['VerifiableCredential', 'AuthorityCredential'],
    'issuer': _communityDid,
  };

  group('GroupJoinProof attachments', () {
    test('travel and come back unchanged', () {
      final proof = GroupJoinProof(
        presentation: presentation,
        authority: authority,
      );

      final read = GroupJoinProof.fromAttachments([
        Attachment(id: 'contact-card'),
        ...proof.toAttachments(),
      ]);

      expect(read!.presentation, presentation);
      expect(read.authority, authority);
    });

    test('are absent from a request that carries none', () {
      expect(GroupJoinProof.fromAttachments([Attachment(id: 'card')]), isNull);
    });

    test('are absent when one cannot be read', () {
      final attachments = GroupJoinProof(
        presentation: presentation,
        authority: authority,
      ).toAttachments();

      expect(
        GroupJoinProof.fromAttachments([
          attachments.first,
          Attachment(
            id: GroupJoinProof.authorityAttachmentId,
            data: AttachmentData(base64: 'not json'),
          ),
        ]),
        isNull,
      );
    });
  });

  group('GroupJoinProof.prove', () {
    late FakeVta vta;
    late VtaClient client;

    setUp(() {
      vta = FakeVta();
      final manager = Ed25519DidKeySigner.generate();
      client = VtaClient(
        vtaDid: vta.did,
        manager: manager,
        didResolver: FakeVtaResolver(vta),
        transport: vta.transport(manager),
      );
      vta.answerTo[VtaTask.credentialsQuery] = (payload) => {
        'credentials': [
          if (payload['type'] == 'MembershipCredential')
            {
              'id': 'held-card',
              'types': ['VerifiableCredential', 'MembershipCredential'],
              'status': 'valid',
            }
          else
            {
              'id': 'held-grant',
              'types': ['VerifiableCredential', 'AuthorityCredential'],
              'status': 'valid',
            },
        ],
      };
      vta.answerTo[VtaTask.credentialsGet] = (payload) => {
        'credential': payload['id'] == 'held-card'
            ? {
                'id': 'urn:uuid:group-card',
                'credentialSubject': {'id': _personaDid, 'memberOf': 'g1'},
              }
            : authority,
      };
      vta.answers[VtaTask.credentialsPresent] = {
        'presentation': presentation,
        'disclosed': ['memberOf'],
      };
    });

    Map<String, dynamic> sent(String type, {int index = 0}) =>
        vta.received.where((r) => r['type'] == type).elementAt(index)['payload']
            as Map<String, dynamic>;

    Future<GroupJoinProof?> prove() => GroupJoinProof.prove(
      client,
      groupDid: _groupDid,
      communityDid: _communityDid,
      personaDid: _personaDid,
      memberDid: _memberDid,
    );

    test("presents the group's credential to the chat, bound to the "
        'joiner', () async {
      final proof = await prove();

      expect(sent(VtaTask.credentialsQuery), {
        'type': 'MembershipCredential',
        'issuerDid': _groupDid,
        'subjectDid': _personaDid,
        'status': 'valid',
      });
      expect(sent(VtaTask.credentialsQuery, index: 1), {
        'type': 'AuthorityCredential',
        'issuerDid': _communityDid,
        'subjectDid': _groupDid,
        'status': 'valid',
      });
      final present = sent(VtaTask.credentialsPresent);
      expect(present['id'], 'held-card');
      expect(present['audience'], _groupDid);
      expect(present['nonce'], _memberDid);
      expect(present['claims'], ['memberOf']);
      expect(proof!.presentation, presentation);
      expect(proof.authority, authority);
    });

    group('for a credential that names only its subject, as a '
        "group's does", () {
      setUp(() {
        vta.answerTo[VtaTask.credentialsGet] = (payload) => {
          'credential': payload['id'] == 'held-card'
              ? {
                  'id': 'urn:uuid:group-card',
                  'credentialSubject': {'id': _personaDid},
                }
              : authority,
        };
        vta.answerTo[VtaTask.signDocument] = (payload) => {
          'document': {
            ...payload['document'] as Map<String, dynamic>,
            'proof': {'proofPurpose': payload['proofPurpose']},
          },
        };
      });

      test("has the VTA sign the presentation with the persona's key, "
          'bound to the chat and the joiner', () async {
        final proof = await GroupJoinProof.prove(
          client,
          groupDid: _groupDid,
          communityDid: _communityDid,
          personaDid: _personaDid,
          memberDid: _memberDid,
          signingKeyId: 'persona-key',
        );

        final signing = sent(VtaTask.signDocument);
        expect(signing['keyId'], 'persona-key');
        expect(signing['proofPurpose'], 'authentication');
        expect(proof!.presentation['holder'], _personaDid);
        expect(proof.presentation['domain'], _groupDid);
        expect(proof.presentation['nonce'], _memberDid);
        expect(proof.presentation['verifiableCredential'], [
          {
            'id': 'urn:uuid:group-card',
            'credentialSubject': {'id': _personaDid},
          },
        ]);
        expect(proof.authority, authority);
        expect(
          vta.received.map((r) => r['type']),
          isNot(contains(VtaTask.credentialsPresent)),
        );
      });

      test("proves nothing without the persona's key", () async {
        expect(await prove(), isNull);
        expect(
          vta.received.map((r) => r['type']),
          isNot(contains(VtaTask.signDocument)),
        );
      });
    });

    test('proves nothing without a membership credential', () async {
      vta.answerTo[VtaTask.credentialsQuery] = (_) => {
        'credentials': const <Object>[],
      };

      expect(await prove(), isNull);
      expect(
        vta.received.map((r) => r['type']),
        isNot(contains(VtaTask.credentialsPresent)),
      );
    });
  });
}

import 'package:dio/dio.dart';
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fake_join_vtc.dart';
import '../utils/fake_vtc.dart';
import '../utils/fakes.dart';

const _subject = 'did:webvh:QmBob:vta.example:bob';

Matcher _refusedWith(String code) => throwsA(
  isA<MeetingPlaceVtcSDKException>()
      .having((e) => e.code, 'code', MeetingPlaceVtcSDKErrorCode.refused)
      .having((e) => e.refusalCode, 'refusalCode', code),
);

void main() {
  late FakeJoinVtc vtc;
  late FakeHttpAdapter adapter;
  late FakeSignInAgent agent;

  VtcRelationshipsClient client() => VtcRelationshipsClient(
    didResolver: FakeDidResolver({vtcDid: vtc.didDocument}),
    transport: TrustTaskHttpTransport(dio: Dio()..httpClientAdapter = adapter),
  );

  Map<String, dynamic> edge({
    String id = 'edge-1',
    String? issuer,
    String subject = _subject,
  }) => {
    'id': id,
    'issuerDid': issuer ?? agent.persona.did,
    'subjectDid': subject,
    'vrcDigestMultibase': 'zQm$id',
  };

  setUp(() {
    adapter = FakeHttpAdapter();
    vtc = FakeJoinVtc();
    adapter.handler = vtc.handle;
    agent = FakeSignInAgent();
  });

  group('VtcRelationshipsClient.publish', () {
    Future<PublishedRelationship> publish({String subjectDid = _subject}) =>
        client().publish(
          vtcDid,
          agent: agent,
          persona: agent.vtaPersona,
          signer: agent.signInPersona,
          subjectDid: subjectDid,
        );

    test('hands the community a vouch the VTA signed as the persona', () async {
      vtc.answerTo[RelationshipTask.publish] = (_) => edge();

      final published = await publish();

      final request = vtc.received.single;
      expect(request['type'], RelationshipTask.publish);
      expect(request['issuer'], agent.persona.did);
      final vrc = (request['payload'] as Map)['vrc'] as Map<String, dynamic>;
      expect(vrc['issuer'], agent.persona.did);
      expect(vrc['issuerScope'], 'directed');
      expect(vrc['credentialSubject'], {'id': _subject});
      await expectLater(
        EddsaJcs2022.verify(
          vrc,
          purpose: ProofPurpose.assertionMethod,
          resolver: FakeDidResolver(),
          expectedSigner: agent.persona.did,
        ),
        completes,
      );
      expect(published.id, 'edge-1');
      expect(published.subjectDid, _subject);
    });

    test('sends no DID but the two personas and the community', () async {
      vtc.answerTo[RelationshipTask.publish] = (_) => edge();

      await publish();

      final dids = RegExp(r'did:[a-z0-9]+:[A-Za-z0-9.:%_-]+')
          .allMatches(vtc.received.single.toString())
          .map((m) => m[0]!.split('#').first)
          .toSet();
      expect(dids, {agent.persona.did, _subject, vtcDid});
    });

    test('refuses to vouch for the persona itself', () async {
      await expectLater(
        publish(subjectDid: agent.persona.did),
        throwsArgumentError,
      );
      expect(vtc.received, isEmpty);
    });

    test('refuses an answer about another edge', () async {
      vtc.answerTo[RelationshipTask.publish] = (_) =>
          edge(subject: 'did:webvh:QmCarol:vta.example:carol');

      await expectLater(
        publish(),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceVtcSDKErrorCode.invalidDocument,
          ),
        ),
      );
    });

    for (final code in [
      RelationshipTask.subjectNotMember,
      RelationshipTask.vrcInvalid,
      'permissionDenied',
      'unavailable',
    ]) {
      test('passes on the refusal $code', () async {
        vtc.refusal = {'code': code};

        await expectLater(publish(), _refusedWith(code));
      });
    }
  });

  group('VtcRelationshipsClient.list', () {
    test('lists the edges of a DID, page by page', () async {
      final pages = [
        {
          'items': [edge(id: 'edge-1')],
          'nextCursor': 'c-1',
        },
        {
          'items': [
            edge(id: 'edge-2', issuer: _subject, subject: agent.persona.did),
          ],
        },
      ];
      var page = 0;
      vtc.answerTo[RelationshipTask.list] = (_) => pages[page++];

      final edges = await client().list(
        vtcDid,
        agent: agent,
        persona: agent.signInPersona,
        did: agent.persona.did,
      );

      expect(edges.map((e) => e.id), ['edge-1', 'edge-2']);
      final payloads = [
        for (final request in vtc.received) request['payload'] as Map,
      ];
      expect(payloads.first, {'did': agent.persona.did, 'limit': 200});
      expect(payloads.last['cursor'], 'c-1');
    });

    test('passes on a DID that is no member', () async {
      vtc.refusal = {'code': RelationshipTask.listNotFound};

      await expectLater(
        client().list(
          vtcDid,
          agent: agent,
          persona: agent.signInPersona,
          did: _subject,
        ),
        _refusedWith(RelationshipTask.listNotFound),
      );
    });
  });

  group('VtcRelationshipsClient.revoke', () {
    Future<void> revoke() => client().revoke(
      vtcDid,
      agent: agent,
      persona: agent.signInPersona,
      id: 'edge-1',
    );

    test('withdraws the edge by its id', () async {
      vtc.answerTo[RelationshipTask.revoke] = (payload) => {
        'id': payload['id'],
      };

      await revoke();

      final request = vtc.received.single;
      expect(request['type'], RelationshipTask.revoke);
      expect(request['payload'], {'id': 'edge-1'});
    });

    test('counts an edge that is gone as withdrawn', () async {
      vtc.refusal = {'code': RelationshipTask.revokeNotFound};

      await expectLater(revoke(), completes);
    });

    test('passes on other refusals', () async {
      vtc.refusal = {'code': 'permissionDenied'};

      await expectLater(revoke(), _refusedWith('permissionDenied'));
    });
  });
}

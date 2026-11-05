import 'package:dio/dio.dart';
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

import '../utils/fake_join_vtc.dart';
import '../utils/fake_vtc.dart';
import '../utils/fakes.dart';

Matcher _throwsCode(MeetingPlaceVtcSDKErrorCode code) => throwsA(
  isA<MeetingPlaceVtcSDKException>().having((e) => e.code, 'code', code),
);

Map<String, dynamic> _group({
  String groupId = 'g-1',
  String showMembers = 'groupMembers',
  List<String>? managers,
}) => {
  'groupId': groupId,
  'groupDid': 'did:webvh:QmGroup:vtc.example:group-dids:$groupId',
  'name': 'Identity WG',
  'description': 'Working on identity.',
  'kind': 'static',
  'visibility': 'members',
  'showMembers': showMembers,
  'joinPolicy': 'request',
  'managers': ?managers,
};

void main() {
  late FakeJoinVtc vtc;
  late FakeHttpAdapter adapter;
  late FakeSignInAgent agent;

  VtcGroupsClient client() => VtcGroupsClient(
    didResolver: FakeDidResolver({vtcDid: vtc.didDocument}),
    transport: TrustTaskHttpTransport(dio: Dio()..httpClientAdapter = adapter),
  );

  setUp(() {
    adapter = FakeHttpAdapter();
    vtc = FakeJoinVtc();
    adapter.handler = vtc.handle;
    agent = FakeSignInAgent();
  });

  group('VtcGroupsClient.list', () {
    test('lists my groups, asked as the persona', () async {
      vtc.answerTo[GroupTask.list] = (_) => {
        'items': [
          {'group': _group(), 'myMembership': 'member'},
        ],
      };

      final listings = await client().list(
        vtcDid,
        agent: agent,
        persona: agent.signInPersona,
        mine: true,
      );

      final request = vtc.received.single;
      expect(request['type'], GroupTask.list);
      expect(request['issuer'], agent.persona.did);
      expect(request['payload'], {'mine': true});
      final listing = listings.single;
      expect(listing.standing, GroupStanding.member);
      expect(listing.group.groupId, 'g-1');
      expect(listing.group.name, 'Identity WG');
      expect(listing.group.visibility, GroupAudience.members);
      expect(listing.group.isManagedByCaller, isFalse);
    });

    test('follows the cursor to the last page', () async {
      vtc.answerTo[GroupTask.list] = (payload) => payload['cursor'] == null
          ? {
              'items': [
                {'group': _group(), 'myMembership': 'member'},
              ],
              'nextCursor': 'page-2',
            }
          : {
              'items': [
                {'group': _group(groupId: 'g-2'), 'myMembership': 'none'},
              ],
            };

      final listings = await client().list(
        vtcDid,
        agent: agent,
        persona: agent.signInPersona,
      );

      expect(listings.map((l) => l.group.groupId), ['g-1', 'g-2']);
      expect(listings.last.standing, GroupStanding.none);
      expect((vtc.received.last['payload'] as Map)['cursor'], 'page-2');
    });

    test('stops a community that never stops paging', () async {
      vtc.answerTo[GroupTask.list] = (_) => {
        'items': const <Object>[],
        'nextCursor': 'again',
      };

      await expectLater(
        client().list(vtcDid, agent: agent, persona: agent.signInPersona),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
      expect(vtc.received, hasLength(VtcGroupsClient.maxPages));
    });

    test('refuses a group it cannot read', () async {
      vtc.answerTo[GroupTask.list] = (_) => {
        'items': [
          {
            'group': {..._group(), 'visibility': 'everyone'},
          },
        ],
      };

      await expectLater(
        client().list(vtcDid, agent: agent, persona: agent.signInPersona),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });
  });

  group('VtcGroupsClient.show', () {
    test('shows a group I manage, with its managers', () async {
      vtc.answerTo[GroupTask.show] = (payload) => {
        'group': _group(
          groupId: payload['groupId'] as String,
          managers: const ['entry-manager'],
        ),
        'myMembership': 'member',
      };

      final listing = await client().show(
        vtcDid,
        groupId: 'g-1',
        agent: agent,
        persona: agent.signInPersona,
      );

      expect(vtc.received.single['payload'], {'groupId': 'g-1'});
      expect(listing.group.isManagedByCaller, isTrue);
      expect(listing.group.managers, ['entry-manager']);
      expect(listing.group.showsMembersToMembers, isTrue);
    });

    test('tells when a group hides its members from its members', () async {
      vtc.answerTo[GroupTask.show] = (_) => {
        'group': _group(showMembers: 'admins'),
        'myMembership': 'member',
      };

      final listing = await client().show(
        vtcDid,
        groupId: 'g-1',
        agent: agent,
        persona: agent.signInPersona,
      );

      expect(listing.group.showsMembersToMembers, isFalse);
    });

    test('refuses an answer the community did not sign', () async {
      vtc
        ..signWithOtherKey = true
        ..answerTo[GroupTask.show] = (_) => {
          'group': _group(),
          'myMembership': 'member',
        };

      await expectLater(
        client().show(
          vtcDid,
          groupId: 'g-1',
          agent: agent,
          persona: agent.signInPersona,
        ),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidProof),
      );
    });
  });

  group('VtcGroupsClient.members', () {
    test('lists the members with the credential ids a manager sees', () async {
      vtc.answerTo[GroupTask.membersList] = (_) => {
        'items': [
          {
            'entryId': 'entry-1',
            'source': 'added',
            'since': '2026-11-01T00:00:00Z',
            'state': 'active',
            'credentialId': 'urn:uuid:card-1',
          },
          {
            'entryId': 'entry-2',
            'source': 'requested',
            'since': '2026-11-04T00:00:00Z',
            'state': 'pending',
          },
        ],
      };

      final members = await client().members(
        vtcDid,
        groupId: 'g-1',
        agent: agent,
        persona: agent.signInPersona,
      );

      expect(vtc.received.single['type'], GroupTask.membersList);
      expect(members.map((m) => m.entryId), ['entry-1', 'entry-2']);
      expect(members.first.isActive, isTrue);
      expect(members.first.credentialId, 'urn:uuid:card-1');
      expect(members.last.isActive, isFalse);
      expect(members.last.credentialId, isNull);
    });

    test('passes on a group that hides its members', () async {
      vtc.refusal = {'code': 'permissionDenied'};

      await expectLater(
        client().members(
          vtcDid,
          groupId: 'g-1',
          agent: agent,
          persona: agent.signInPersona,
        ),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.refused),
      );
    });
  });
}

import 'package:dio/dio.dart';
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

import '../utils/fake_join_vtc.dart';
import '../utils/fake_vtc.dart';
import '../utils/fakes.dart';

const _bob = 'did:webvh:QmBob:vta.example:bob';

Matcher _refusedWith(String code) => throwsA(
  isA<MeetingPlaceVtcSDKException>()
      .having((e) => e.code, 'code', MeetingPlaceVtcSDKErrorCode.refused)
      .having((e) => e.refusalCode, 'refusalCode', code),
);

void main() {
  late FakeJoinVtc vtc;
  late FakeHttpAdapter adapter;
  late FakeSignInAgent agent;

  VtcDirectoryClient client() => VtcDirectoryClient(
    didResolver: FakeDidResolver({vtcDid: vtc.didDocument}),
    transport: TrustTaskHttpTransport(dio: Dio()..httpClientAdapter = adapter),
  );

  setUp(() {
    adapter = FakeHttpAdapter();
    vtc = FakeJoinVtc();
    adapter.handler = vtc.handle;
    agent = FakeSignInAgent();
  });

  group('VtcDirectoryClient.search', () {
    Future<List<DirectoryEntry>> search([String query = 'Bob']) =>
        client().search(
          vtcDid,
          agent: agent,
          persona: agent.signInPersona,
          query: query,
        );

    test('finds members as the community projects them', () async {
      vtc.answerTo[DirectoryTask.entriesList] = (_) => {
        'items': [
          {
            'entryId': 'dir_bob',
            'fields': {'displayName': 'Bob Meyer', 'did': _bob},
            'connected': true,
          },
          {
            'entryId': 'dir_bobby',
            'fields': {'displayName': 'Bobby'},
          },
          {'fields': <String, dynamic>{}},
        ],
        'nextCursor': 'c-1',
      };

      final entries = await search();

      final request = vtc.received.single;
      expect(request['type'], DirectoryTask.entriesList);
      expect(request['payload'], {'query': 'Bob', 'limit': 25});
      expect(entries.map((e) => e.entryId), ['dir_bob', 'dir_bobby']);
      expect(entries.first.displayName, 'Bob Meyer');
      expect(entries.first.did, _bob);
      expect(entries.first.isConnected, isTrue);
      expect(entries.last.did, isNull, reason: 'Bobby shows no DID');
      expect(entries.last.isConnected, isFalse);
    });

    test('passes on a search that is too short', () async {
      vtc.refusal = {'code': DirectoryTask.queryTooShort};

      await expectLater(
        search('Bo'),
        _refusedWith(DirectoryTask.queryTooShort),
      );
    });
  });

  group('VtcDirectoryClient.show', () {
    Future<DirectoryEntry?> show() => client().show(
      vtcDid,
      agent: agent,
      persona: agent.signInPersona,
      entryId: 'dir_bob',
    );

    test('shows one entry', () async {
      vtc.answerTo[DirectoryTask.entriesShow] = (payload) => {
        'entry': {
          'entryId': payload['entryId'],
          'fields': {'displayName': 'Bob Meyer', 'did': _bob},
        },
      };

      final entry = await show();

      expect(entry?.did, _bob);
      expect(vtc.received.single['payload'], {'entryId': 'dir_bob'});
    });

    test('answers null for an entry the persona may not see', () async {
      vtc.refusal = {'code': DirectoryTask.entryNotFound};

      expect(await show(), isNull);
    });

    test('refuses an answer about another entry', () async {
      vtc.answerTo[DirectoryTask.entriesShow] = (_) => {
        'entry': {'entryId': 'dir_other', 'fields': <String, dynamic>{}},
      };

      await expectLater(
        show(),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceVtcSDKErrorCode.invalidDocument,
          ),
        ),
      );
    });
  });

  group('VtcDirectoryClient.myCard', () {
    Map<String, dynamic> card(
      Map<String, dynamic> visibility, {
      Map<String, dynamic> values = const {},
    }) => {
      'card': {
        'entryId': 'dir_me',
        'values': values,
        'visibility': visibility,
        'discoverability': {'listing': 'listed', 'search': 'byName'},
        'introductions': {'accept': 'members'},
        'revision': 3,
        'updatedAt': '2026-11-09T10:00:00Z',
      },
      'missingRequired': <String>[],
    };

    Future<MyDirectoryCard> myCard() =>
        client().myCard(vtcDid, agent: agent, persona: agent.signInPersona);

    test('tells the DID shown to members', () async {
      vtc.answerTo[DirectoryTask.cardShow] = (_) => card({'did': 'members'});

      final mine = await myCard();

      expect(vtc.received.single['type'], DirectoryTask.cardShow);
      expect(mine.entryId, 'dir_me');
      expect(mine.isDidVisibleToMembers, isTrue);
      expect(mine.displayName, isNull, reason: 'a new card has no name');
    });

    test('tells the name members see', () async {
      vtc.answerTo[DirectoryTask.cardShow] = (_) =>
          card({}, values: {'displayName': 'Ada'});

      expect((await myCard()).displayName, 'Ada');
    });

    test('tells the DID kept to administrators', () async {
      vtc.answerTo[DirectoryTask.cardShow] = (_) => card({'did': 'admins'});

      expect((await myCard()).isDidVisibleToMembers, isFalse);
    });

    test('tells the DID left at its default', () async {
      vtc.answerTo[DirectoryTask.cardShow] = (_) => card({});

      expect((await myCard()).isDidVisibleToMembers, isFalse);
    });
  });

  group('VtcDirectoryClient.setDisplayName', () {
    Future<void> set(String? name) => client().setDisplayName(
      vtcDid,
      agent: agent,
      persona: agent.signInPersona,
      name: name,
    );

    test('sets the name members see, trimmed', () async {
      await set('  Ada Lovelace ');

      final request = vtc.received.single;
      expect(request['type'], DirectoryTask.cardUpdate);
      expect(request['payload'], {
        'values': {'displayName': 'Ada Lovelace'},
      });
    });

    test('clears a blank name', () async {
      await set('  ');

      expect(vtc.received.single['payload'], {
        'values': {'displayName': null},
      });
    });

    test('passes on a name the community refuses', () async {
      vtc.refusal = {'code': DirectoryTask.valueRefused};

      await expectLater(set('Ada'), _refusedWith(DirectoryTask.valueRefused));
    });
  });

  group('VtcDirectoryClient.setDidVisibleToMembers', () {
    Future<void> set({required bool visible}) =>
        client().setDidVisibleToMembers(
          vtcDid,
          agent: agent,
          persona: agent.signInPersona,
          visible: visible,
        );

    test('shows the DID to members', () async {
      await set(visible: true);

      final request = vtc.received.single;
      expect(request['type'], DirectoryTask.cardUpdate);
      expect(request['payload'], {
        'visibility': {'did': 'members'},
      });
    });

    test('returns the DID to its default', () async {
      await set(visible: false);

      expect(vtc.received.single['payload'], {
        'visibility': {'did': null},
      });
    });

    test('passes on a community that does not let members show it', () async {
      vtc.refusal = {'code': DirectoryTask.aboveCeiling};

      await expectLater(
        set(visible: true),
        _refusedWith(DirectoryTask.aboveCeiling),
      );
    });
  });
}

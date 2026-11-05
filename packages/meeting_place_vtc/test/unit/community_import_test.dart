import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

import '../utils/fake_vta.dart';

const _vtcDid = 'did:web:community.example';
const _persona = 'did:webvh:QmPersona:host.example';

void main() {
  late FakeVta vta;
  late VtaClient client;

  setUp(() {
    vta = FakeVta();
    final manager = VtaLink.newManagerKey();
    client = VtaClient(
      vtaDid: vta.did,
      manager: manager,
      didResolver: FakeVtaResolver(vta),
      transport: vta.transport(manager),
    );
    vta.answers[VtaTask.didsList] = {
      'dids': [
        {'did': 'did:webvh:QmOther:host.example', 'contextId': 'other'},
        {'did': _persona, 'contextId': 'keyring'},
      ],
    };
    vta.answers[VtaTask.credentialsQuery] = {
      'credentials': [
        {'id': 'card-1'},
      ],
    };
  });

  group('CommunityImport', () {
    test('finds the persona named by the community card', () async {
      vta.answers[VtaTask.credentialsGet] = {
        'credential': {
          'issuer': {'id': _vtcDid},
          'name': 'Football Club',
          'credentialSubject': {'id': _persona},
        },
      };

      final membership = await CommunityImport(client).find(_vtcDid);

      expect(membership?.persona.did, _persona);
      expect(membership?.persona.contextId, 'keyring');
      expect(membership?.name, 'Football Club');
    });

    test("finds the persona's card from the community", () async {
      vta.answers[VtaTask.credentialsGet] = {
        'credential': {
          'id': 'urn:uuid:vmc',
          'issuer': _vtcDid,
          'credentialSubject': {'id': _persona},
        },
      };

      final card = await CommunityImport(
        client,
      ).membershipCard(_vtcDid, personaDid: _persona);
      final other = await CommunityImport(
        client,
      ).membershipCard(_vtcDid, personaDid: 'did:key:z6MkSomeoneElse');

      expect(card?['id'], 'urn:uuid:vmc');
      expect(other, isNull);
    });

    test('lists every membership card the VTA holds', () async {
      vta.answers[VtaTask.credentialsGet] = {
        'credential': {
          'id': 'urn:uuid:vmc',
          'issuer': _vtcDid,
          'credentialSubject': {'id': _persona},
        },
      };

      final cards = await CommunityImport(client).membershipCards();

      expect(cards.single['id'], 'urn:uuid:vmc');
      expect(
        vta.received
            .where((task) => task['type'] == VtaTask.credentialsQuery)
            .single['payload'],
        {'purpose': 'membership'},
      );
    });

    test("archives the persona's cards from the community", () async {
      vta.answers[VtaTask.credentialsGet] = {
        'credential': {
          'issuer': _vtcDid,
          'credentialSubject': {'id': _persona},
        },
      };

      await CommunityImport(
        client,
      ).archiveMembershipCards(_vtcDid, personaDid: _persona);

      expect(vta.received.last['type'], VtaTask.credentialsArchive);
      expect(vta.received.last['payload'], {'id': 'card-1'});
    });

    test("keeps another persona's cards", () async {
      vta.answers[VtaTask.credentialsGet] = {
        'credential': {
          'issuer': _vtcDid,
          'credentialSubject': {'id': 'did:webvh:QmSomeoneElse:host.example'},
        },
      };

      await CommunityImport(
        client,
      ).archiveMembershipCards(_vtcDid, personaDid: _persona);

      expect(
        vta.received.map((request) => request['type']),
        isNot(contains(VtaTask.credentialsArchive)),
      );
    });

    test('finds nothing for another community', () async {
      vta.answers[VtaTask.credentialsGet] = {
        'credential': {
          'issuer': 'did:web:other.example',
          'credentialSubject': {'id': _persona},
        },
      };

      expect(await CommunityImport(client).find(_vtcDid), isNull);
    });

    test('finds nothing when the card names no persona of the VTA', () async {
      vta.answers[VtaTask.credentialsGet] = {
        'credential': {
          'issuer': _vtcDid,
          'credentialSubject': [
            {'id': 'did:webvh:QmSomeoneElse:host.example'},
          ],
        },
      };

      expect(await CommunityImport(client).find(_vtcDid), isNull);
    });
  });

  group('VtaLink.isGranted', () {
    test('is true for an admin holding personas', () async {
      vta.answers[VtaTask.whoAmI] = {
        'roles': ['admin'],
        'capabilities': ['vault-read', 'persona-holder'],
      };

      expect(await VtaLink.isGranted(client), isTrue);
    });

    test('is false for an admin not holding personas', () async {
      vta.answers[VtaTask.whoAmI] = {
        'roles': ['admin'],
        'capabilities': ['vault-read'],
      };

      expect(await VtaLink.isGranted(client), isFalse);
      expect((await VtaLink.access(client))?.isAdmin, isTrue);
    });

    test('is false for another role holding personas', () async {
      vta.answers[VtaTask.whoAmI] = {
        'roles': ['reader'],
        'capabilities': ['persona-holder'],
      };

      expect(await VtaLink.isGranted(client), isFalse);
    });

    test('is false while the key is not on the access list', () async {
      vta.refusals[VtaTask.whoAmI] = {'code': 'auth/whoami:notAuthorized'};

      expect(await VtaLink.isGranted(client), isFalse);
      expect(await VtaLink.access(client), isNull);
    });
  });

  group('VtaLink.grantCommand', () {
    test('grants the admin role with persona-holder, in one step', () {
      expect(
        VtaLink.grantCommand('did:key:z6MkManager'),
        'pnm acl create --did did:key:z6MkManager --role admin '
        '--capabilities persona-holder --label "Meeting Place"',
      );
    });
  });
}

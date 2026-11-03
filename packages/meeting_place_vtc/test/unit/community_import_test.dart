import 'package:dio/dio.dart';
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

import '../utils/fake_vta.dart';
import '../utils/fakes.dart';

const _vtcDid = 'did:web:community.example';
const _persona = 'did:webvh:QmPersona:host.example';

void main() {
  late FakeVta vta;
  late VtaClient client;

  setUp(() {
    vta = FakeVta();
    client = VtaClient(
      vtaDid: vta.did,
      manager: VtaLink.newManagerKey(),
      didResolver: FakeDidResolver({vta.did: vta.document}),
      transport: TrustTaskHttpTransport(
        dio: Dio()
          ..httpClientAdapter = (FakeHttpAdapter()..handler = vta.handle),
      ),
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

  group('VtaLink.grantCommands', () {
    test('grants the admin role, then persona-holder', () {
      expect(VtaLink.grantCommands('did:key:z6MkManager'), [
        'pnm acl create --did did:key:z6MkManager --role admin '
            '--label "Meeting Place"',
        'pnm acl update did:key:z6MkManager --capabilities persona-holder',
      ]);
    });
  });
}

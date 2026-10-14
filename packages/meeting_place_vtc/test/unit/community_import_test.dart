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
    test('is true once the VTA answers whoami', () async {
      expect(await VtaLink.isGranted(client), isTrue);
    });

    test('is false while the key is not on the access list', () async {
      vta.refusals[VtaTask.whoAmI] = {'code': 'auth/whoami:notAuthorized'};

      expect(await VtaLink.isGranted(client), isFalse);
    });
  });
}

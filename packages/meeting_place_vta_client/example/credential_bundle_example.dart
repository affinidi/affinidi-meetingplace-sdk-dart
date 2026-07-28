import 'dart:convert';

import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

void main() {
  final rawBundle = <String, dynamic>{
    'did': 'did:key:zHolder',
    'vta_url': 'https://vta.example',
    'private_key_multibase': 'z3u2secret',
    'context_id': 'ctx-personal',
    'key_id': 'holder-ed25519-1',
  };

  final encoded = base64Url.encode(utf8.encode(jsonEncode(rawBundle)));

  final parsed = VtaCredentialBundle.parse(encoded);

  print('holderDid=${parsed.did}');
  print('vtaUrl=${parsed.vtaUrl}');
  print('contextId=${parsed.contextId}');
  print('keyId=${parsed.keyId}');
}

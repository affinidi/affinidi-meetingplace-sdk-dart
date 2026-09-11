import 'package:meeting_place_credentials/src/vrc/model/vrc_constants.dart';
import 'package:meeting_place_credentials/src/vrc/model/vrc_request.dart';
import 'package:test/test.dart';

void main() {
  group('VrcRequest.identityDid', () {
    test('returns a valid DID unchanged', () {
      final request = VrcRequest(
        senderDid: 'did:key:sender',
        credentialMetaData: const {
          VrcConstants.requestMetadataKeyIdentityDid: 'did:key:peer',
        },
      );

      expect(request.identityDid, 'did:key:peer');
    });

    test('returns null for a malformed DID', () {
      final request = VrcRequest(
        senderDid: 'did:key:sender',
        credentialMetaData: const {
          VrcConstants.requestMetadataKeyIdentityDid: 'not-a-did',
        },
      );

      expect(request.identityDid, isNull);
    });

    test('returns null for an oversized DID', () {
      final oversized = 'did:key:${'a' * 600}';
      final request = VrcRequest(
        senderDid: 'did:key:sender',
        credentialMetaData: {
          VrcConstants.requestMetadataKeyIdentityDid: oversized,
        },
      );

      expect(request.identityDid, isNull);
    });

    test('falls back to selected_identity when identity_did is absent', () {
      final request = VrcRequest(
        senderDid: 'did:key:sender',
        credentialMetaData: const {
          VrcConstants.requestMetadataKeySelectedIdentity: 'did:key:legacy',
        },
      );

      expect(request.identityDid, 'did:key:legacy');
    });

    test('does not fall back to a malformed selected_identity', () {
      final request = VrcRequest(
        senderDid: 'did:key:sender',
        credentialMetaData: const {
          VrcConstants.requestMetadataKeySelectedIdentity: 'not-a-did',
        },
      );

      expect(request.identityDid, isNull);
    });

    test('returns null when identity_did is absent', () {
      final request = VrcRequest(senderDid: 'did:key:sender');

      expect(request.identityDid, isNull);
    });
  });

  group('VrcRequest.selectedIdentity', () {
    test('returns null for a malformed legacy DID', () {
      final request = VrcRequest(
        senderDid: 'did:key:sender',
        credentialMetaData: const {
          VrcConstants.requestMetadataKeySelectedIdentity: 'not-a-did',
        },
      );

      expect(request.selectedIdentity, isNull);
    });
  });

  group('VrcRequest.identityName', () {
    test('returns a plain name unchanged', () {
      final request = VrcRequest(
        senderDid: 'did:key:sender',
        credentialMetaData: const {
          VrcConstants.requestMetadataKeyIdentityName: 'Bob',
        },
      );

      expect(request.identityName, 'Bob');
    });

    test('strips bidi override and control characters', () {
      // U+202E (RTL override) ... U+202C (pop directional formatting),
      // plus a C0 control character (bell).
      final name = 'Bob\u202Eevil\u202C\x07';
      final request = VrcRequest(
        senderDid: 'did:key:sender',
        credentialMetaData: {VrcConstants.requestMetadataKeyIdentityName: name},
      );

      expect(request.identityName, 'Bobevil');
    });

    test('truncates an oversized name', () {
      final oversized = 'a' * 300;
      final request = VrcRequest(
        senderDid: 'did:key:sender',
        credentialMetaData: {
          VrcConstants.requestMetadataKeyIdentityName: oversized,
        },
      );

      expect(request.identityName, hasLength(256));
      expect(request.identityName, 'a' * 256);
    });

    test('returns null when identity_name is absent', () {
      final request = VrcRequest(senderDid: 'did:key:sender');

      expect(request.identityName, isNull);
    });
  });
}

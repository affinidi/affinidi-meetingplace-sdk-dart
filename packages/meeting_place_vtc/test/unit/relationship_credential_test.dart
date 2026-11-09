import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

void main() {
  const issuer = 'did:webvh:QmA:vta.example:alice';
  const subject = 'did:webvh:QmB:vta.example:bob';

  group('relationshipCredential', () {
    test('is an attributed DTG relationship between two personas', () {
      final vrc = relationshipCredential(
        issuerDid: issuer,
        subjectDid: subject,
        now: DateTime.utc(2026, 11, 9, 10, 30, 15, 250),
      );

      expect(vrc['@context'], [
        'https://www.w3.org/ns/credentials/v2',
        'https://registry.trustoverip.org/dtg/context/v1',
      ]);
      expect(vrc['type'], [
        'VerifiableCredential',
        'DTGCredential',
        'RelationshipCredential',
      ]);
      expect(vrc['id'], startsWith('urn:uuid:'));
      expect(vrc['issuer'], issuer);
      expect(vrc['issuerScope'], 'directed');
      expect(vrc['validFrom'], '2026-11-09T10:30:15Z');
      expect(vrc['credentialSubject'], {'id': subject});
      expect(vrc.containsKey('validUntil'), isFalse);
      expect(vrc.containsKey('proof'), isFalse);
    });

    test('names no DID but the two personas', () {
      final vrc = relationshipCredential(
        issuerDid: issuer,
        subjectDid: subject,
      );

      final dids = RegExp(
        r'did:[a-z0-9]+:[^"\s,}]+',
      ).allMatches(vrc.toString()).map((m) => m[0]).toSet();
      expect(dids, {issuer, subject});
    });

    test('is a new credential each time', () {
      final first = relationshipCredential(
        issuerDid: issuer,
        subjectDid: subject,
      );
      final second = relationshipCredential(
        issuerDid: issuer,
        subjectDid: subject,
      );

      expect(first['id'], isNot(second['id']));
    });
  });

  group('PublishedRelationship.read', () {
    test('reads a listed edge', () {
      final edge = PublishedRelationship.read({
        'id': '6f1c',
        'issuerDid': issuer,
        'subjectDid': subject,
        'vrcDigestMultibase': 'zQm1',
        'createdAt': '2026-11-09T10:30:15Z',
        'vrcJsonld': {'type': 'VerifiableCredential'},
      });

      expect(edge.id, '6f1c');
      expect(edge.issuerDid, issuer);
      expect(edge.subjectDid, subject);
      expect(edge.vrcDigestMultibase, 'zQm1');
      expect(edge.createdAt, DateTime.utc(2026, 11, 9, 10, 30, 15));
      expect(edge.vrc, {'type': 'VerifiableCredential'});
    });

    test('reads a publish answer, which has no creation time', () {
      final edge = PublishedRelationship.read({
        'id': '6f1c',
        'issuerDid': issuer,
        'subjectDid': subject,
        'vrcDigestMultibase': 'zQm1',
      });

      expect(edge.createdAt, isNull);
    });

    test('refuses an edge without its parties', () {
      expect(
        () => PublishedRelationship.read({
          'id': '6f1c',
          'issuerDid': issuer,
          'vrcDigestMultibase': 'zQm1',
        }),
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
}

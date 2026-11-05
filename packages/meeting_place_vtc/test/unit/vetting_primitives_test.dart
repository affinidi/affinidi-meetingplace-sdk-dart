import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

// `vetting_conformance_vectors.json` is copied unchanged from Keyring
// (github.com/berkmancenter/keyring-bifold @ 881d284,
// packages/core/src/modules/trust-tasks/__tests__/fixtures/
// vti-conformance-vectors.json, Apache-2.0): golden vectors computed by the
// upstream vetting code. Update it by copying a newer revision whole, never
// by editing a vector.
final _vectors =
    jsonDecode(
          File(
            'test/fixtures/vetting_conformance_vectors.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

List<Map<String, dynamic>> _list(String name) =>
    (_vectors[name] as List).cast<Map<String, dynamic>>();

List<VettingCardClaim> _claims(Object? json) => [
  for (final claim in (json as List).cast<Map<String, dynamic>>())
    VettingCardClaim(
      type: claim['type'] as String,
      value: claim['value'] as Object,
    ),
];

const _community = 'did:webvh:QmCommunity:dids.example:community';
const _vetter = 'did:webvh:QmVetter:dids.example:vetter';

void main() {
  group('vettingMatchCode', () {
    for (final vector in _list('matchCode')) {
      test('matches upstream for ${vector['sessionDocumentId']}', () {
        expect(
          vettingMatchCode(vector['sessionDocumentId'] as String),
          vector['expected'],
        );
      });
    }
  });

  group('vettingIdentityCommitment', () {
    for (final (index, vector) in _list('identityCommitment').indexed) {
      test('matches upstream vector $index', () {
        expect(
          vettingIdentityCommitment(
            salt: vector['salt'] as String,
            claims: _claims(vector['claims']),
            identityTypes: (vector['requiredClaims'] as List).cast<String>(),
          ),
          vector['expected'],
        );
      });
    }

    test('refuses a missing identity claim', () {
      expect(
        () => vettingIdentityCommitment(
          salt: 'salt',
          claims: const [],
          identityTypes: const ['name.legal'],
        ),
        throwsArgumentError,
      );
    });
  });

  group('vettingDigest', () {
    test('matches upstream for a card, its proof left out', () {
      final vector = _vectors['cardDigest'] as Map<String, dynamic>;

      expect(
        vettingDigest(vector['card'] as Map<String, dynamic>),
        vector['expected'],
      );
    });
  });

  group('unsignedVettingCard', () {
    final vector = (_vectors['cardDigest'] as Map)['card'] as Map;

    Map<String, dynamic> card({
      Duration validity = const Duration(minutes: 15),
    }) => unsignedVettingCard(
      id: vector['id'] as String,
      publisher: vector['publisher'] as String,
      audience: vector['audience'] as String,
      community: vector['community'] as String,
      challenge: vector['challenge'] as String,
      domain: vector['domain'] as String,
      issuedAt: DateTime.parse(vector['issuedAt'] as String),
      validity: validity,
      claims: _claims(vector['claims']),
      identityTypes: const ['name.legal'],
      salt: vector['commitmentSalt'] as String,
    );

    test('builds the card upstream signed', () {
      final expected = {...vector}..remove('proof');

      expect(card(), expected);
    });

    test('refuses a validity beyond 15 minutes', () {
      expect(
        () => card(validity: const Duration(minutes: 16)),
        throwsArgumentError,
      );
      expect(() => card(validity: Duration.zero), throwsArgumentError);
    });
  });

  test('newCommitmentSalt makes 32 fresh bytes, base64url', () {
    final salt = newCommitmentSalt();

    expect(salt, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(newCommitmentSalt(), isNot(salt));
  });

  group('VettingTicket', () {
    for (final vector in _list('ticketUri')) {
      test('reads and writes upstream ${vector['uri']}', () {
        final decoded = vector['decoded'] as Map<String, dynamic>;
        final ticket = VettingTicket.parse(vector['uri'] as String)!;

        expect(ticket.community, decoded['community']);
        expect(ticket.vetter, decoded['vetter']);
        expect(ticket.toJson(), decoded['presentation']);
        expect(ticket.toString(), vector['reencoded']);
      });
    }

    String uri(String members) =>
        'vetting-ticket:?v=1&community=${Uri.encodeComponent(_community)}'
        '&vetter=${Uri.encodeComponent(_vetter)}$members';

    test('ignores members it does not know', () {
      expect(VettingTicket.parse(uri('&code=K7QF-2M9X&lang=de')), isNotNull);
    });

    test('refuses what upstream refuses', () {
      for (final input in [
        'https://example.com/?code=K7QF-2M9X',
        uri('&code=K7QF-2M9X').replaceFirst('v=1', 'v=2'),
        uri('&code=K7QF-2M9X').replaceFirst('v=1&', ''),
        uri('&code=K7QF-2M9X&code=K7QF-2M9X'),
        uri('&code=K7QF-2M9X#more'),
        uri(''),
        uri('&ticket=t-1'),
        uri('&ticket=t-1&secret=${'A' * 43}&code=K7QF-2M9X'),
        uri('&code=k7qf-2m9x'),
        uri('&ticket=t-1&secret=short'),
        uri('&code=K7QF-2M9X').replaceFirst('vetter=did', 'vetter=bob'),
        uri('&code=%E0%A4%A'),
      ]) {
        expect(VettingTicket.parse(input), isNull, reason: input);
      }
    });

    test('reads a code the way people type it', () {
      final ticket = VettingTicket.spoken(
        community: _community,
        vetter: _vetter,
        code: ' k7qf 2m9x ',
      )!;

      expect(ticket.toJson(), {'code': 'K7QF-2M9X'});
      expect(
        VettingTicket.spoken(
          community: _community,
          vetter: _vetter,
          code: 'K7QF-2M9',
        ),
        isNull,
      );
    });
  });
}

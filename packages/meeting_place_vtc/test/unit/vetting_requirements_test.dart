import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

const _community = 'did:webvh:club.example';
const _applicant = 'did:webvh:alice.example';

Map<String, dynamic> _requirements([Map<String, dynamic> extra = const {}]) => {
  'version': '0.1',
  'statementType': VettingStatement.predicate,
  'minStatements': 2,
  'acceptedMethods': ['inPerson', 'video', 'priorAcquaintance'],
  'eligibleVetters': {'role': 'vetter'},
  'requiredClaims': ['name.legal'],
  ...extra,
};

Map<String, dynamic> _statement({
  String vetter = 'did:webvh:bob.example',
  String community = _community,
  String method = 'inPerson',
  List<String> documentClasses = const ['passport'],
  List<String> claimsVerified = const ['name.legal'],
  String relationship = 'none',
  String commitment = 'zCommitment',
  String validFrom = '2026-11-01T10:00:00Z',
}) => {
  'type': ['VerifiableCredential', 'DTGCredential', 'StatementCredential'],
  'id': 'urn:uuid:$vetter$validFrom',
  'issuer': vetter,
  'validFrom': validFrom,
  'validUntil': '2027-11-01T10:00:00Z',
  'taskContext': 'urn:uuid:session',
  'taskDigestMultibase': 'zSession',
  'credentialSubject': {
    'id': _applicant,
    'predicate': VettingStatement.predicate,
    'object': {
      'value': {
        'community': community,
        'method': method,
        'documentClasses': documentClasses,
        'claimsVerified': claimsVerified,
        'livenessConfirmed': true,
        'identityCommitment': commitment,
        'cardDigestMultibase': 'zCard',
        'declaredRelationship': relationship,
      },
    },
  },
};

void main() {
  final now = DateTime.utc(2026, 11, 5);

  group('VettingRequirements.read', () {
    test('reads every member it knows', () {
      final requirements = VettingRequirements.read(
        _requirements({
          'minByMethod': {'inPerson': 1},
          'optionalClaims': ['address.locality'],
          'maxStatementAge': 'P2W3DT4H',
          'acceptedDocumentClasses': ['passport', 'nationalId'],
          'independence': {
            'maxByDeclaredRelationship': {'family': 0},
            'requireConsistentIdentityCommitment': true,
          },
          'aMemberFromANewerShape': true,
        }),
      )!;

      expect(requirements.statementType, VettingStatement.predicate);
      expect(requirements.minStatements, 2);
      expect(requirements.acceptedMethods, VettingMethod.values);
      expect(requirements.vetterRole, 'vetter');
      expect(requirements.minByMethod, {VettingMethod.inPerson: 1});
      expect(requirements.requiredClaims, ['name.legal']);
      expect(requirements.optionalClaims, ['address.locality']);
      expect(requirements.maxStatementAge, const Duration(days: 17, hours: 4));
      expect(requirements.acceptedDocumentClasses, ['passport', 'nationalId']);
      expect(requirements.maxByDeclaredRelationship, {
        VettingRelationship.family: 0,
      });
      expect(requirements.requireConsistentIdentityCommitment, isTrue);
    });

    test('refuses requirements it cannot meet', () {
      for (final broken in [
        {'minStatements': 0},
        {'minStatements': '2'},
        {'eligibleVetters': <String, dynamic>{}},
        {'acceptedMethods': <String>[]},
        {
          'acceptedMethods': ['carrierPigeon'],
        },
        {'maxStatementAge': 'P1Y'},
        {
          'ext': {'org.example.new': <String, dynamic>{}},
          'extCritical': ['org.example.new'],
        },
      ]) {
        expect(
          VettingRequirements.read(_requirements(broken)),
          isNull,
          reason: '$broken',
        );
      }
      expect(VettingRequirements.read('vetting'), isNull);
    });
  });

  group('parseVettingDuration', () {
    test('reads weeks to seconds in order', () {
      expect(parseVettingDuration('P120D'), const Duration(days: 120));
      expect(parseVettingDuration('PT15M'), const Duration(minutes: 15));
      expect(parseVettingDuration('P1W'), const Duration(days: 7));
    });

    test('refuses anything else', () {
      for (final value in ['P', 'PT', 'P1DT', 'P1M', 'P1D2W', '120D', 7]) {
        expect(parseVettingDuration(value), isNull, reason: '$value');
      }
    });
  });

  group('VettingStatement.read', () {
    test('reads a vetter statement', () {
      final statement = VettingStatement.read(_statement())!;

      expect(statement.vetterDid, 'did:webvh:bob.example');
      expect(statement.applicantDid, _applicant);
      expect(statement.community, _community);
      expect(statement.method, VettingMethod.inPerson);
      expect(statement.claimsVerified, ['name.legal']);
      expect(statement.declaredRelationship, VettingRelationship.none);
      expect(statement.taskContext, 'urn:uuid:session');
    });

    test("refuses another credential and a community's own check", () {
      final ownCheck = _statement();
      final value =
          ((ownCheck['credentialSubject'] as Map)['object'] as Map)['value']
              as Map;
      value
        ..remove('identityCommitment')
        ..remove('cardDigestMultibase')
        ..remove('declaredRelationship');

      expect(VettingStatement.read(ownCheck), isNull);
      expect(
        VettingStatement.read({
          ..._statement(),
          'type': ['VerifiableCredential', 'MembershipCredential'],
        }),
        isNull,
      );
    });
  });

  group('VettingProgress', () {
    VettingProgress progress(
      List<Map<String, dynamic>> statements, [
      Map<String, dynamic> extra = const {},
    ]) => VettingProgress.of(
      requirements: VettingRequirements.read(_requirements(extra))!,
      communityDid: _community,
      statements: [
        for (final statement in statements) VettingStatement.read(statement)!,
      ],
      now: now,
    );

    test('counts one statement per vetter', () {
      final result = progress([
        _statement(),
        _statement(validFrom: '2026-11-02T10:00:00Z'),
      ]);

      expect(result.counted, hasLength(1));
      expect(result.counted.single.validFrom, DateTime.utc(2026, 11, 2, 10));
      expect(result.needs.single, isA<MoreStatements>());
      expect(result.needs.single.count, 1);
      expect(result.satisfied, isFalse);
    });

    test('is satisfied by enough distinct vetters', () {
      final result = progress([
        _statement(),
        _statement(vetter: 'did:webvh:carol.example'),
      ]);

      expect(result.counted, hasLength(2));
      expect(result.needs, isEmpty);
      expect(result.satisfied, isTrue);
    });

    test('leaves out statements that do not count', () {
      final result = progress(
        [
          _statement(vetter: 'did:a', community: 'did:webvh:other.example'),
          _statement(vetter: 'did:b', method: 'priorAcquaintance'),
          _statement(vetter: 'did:c', claimsVerified: const []),
          _statement(vetter: 'did:d', validFrom: '2026-01-01T00:00:00Z'),
          _statement(vetter: 'did:e', documentClasses: const ['library']),
        ],
        {
          'acceptedMethods': ['inPerson'],
          'maxStatementAge': 'P30D',
          'acceptedDocumentClasses': ['passport'],
        },
      );

      expect(result.counted, isEmpty);
      expect(result.needs.single.count, 2);
    });

    test('asks for statements by a method still short', () {
      final result = progress(
        [
          _statement(vetter: 'did:a', method: 'video'),
          _statement(vetter: 'did:b', method: 'video'),
        ],
        {
          'minByMethod': {'inPerson': 1},
        },
      );

      expect(
        result.needs.single,
        isA<MoreByMethod>()
            .having((need) => need.method, 'method', VettingMethod.inPerson)
            .having((need) => need.count, 'count', 1),
      );
    });

    test('holds the independence rules', () {
      final result = progress(
        [
          _statement(vetter: 'did:a', relationship: 'family'),
          _statement(vetter: 'did:b', commitment: 'zOther'),
        ],
        {
          'independence': {
            'maxByDeclaredRelationship': {'family': 0},
            'requireConsistentIdentityCommitment': true,
          },
        },
      );

      expect(result.needs, isEmpty);
      expect(result.independent, isFalse);
      expect(result.commitmentsConsistent, isFalse);
      expect(result.satisfied, isFalse);
    });
  });
}

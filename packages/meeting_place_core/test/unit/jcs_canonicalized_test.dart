import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_core/src/extensions/jcs_canonicalized.dart';
import 'package:test/test.dart';

final _jcsFixtureRoot = Directory('test/fixtures/jcs');

String _readJcsFixture(String category, String name) {
  return File('${_jcsFixtureRoot.path}/$category/$name').readAsStringSync();
}

String _readCanonicalJcsFixture(String name) {
  return toCanonicalJcsJson(jsonDecode(_readJcsFixture('output', name)));
}

void main() {
  group('CanonicalizedMap', () {
    test('canonicalizes nested maps recursively', () {
      final input = <String, dynamic>{
        'zebra': 1,
        'alpha': <String, dynamic>{'delta': 4, 'beta': 2},
        'items': <dynamic>[
          <String, dynamic>{'y': 2, 'x': 1},
          'value',
        ],
      };

      expect(input.canonicalized(), {
        'alpha': {'beta': 2, 'delta': 4},
        'items': [
          {'x': 1, 'y': 2},
          'value',
        ],
        'zebra': 1,
      });
    });

    test('sorts object properties using UTF-16 code unit order', () {
      final carriageReturn = '\r';
      final control = String.fromCharCode(0x0080);
      final diaeresis = String.fromCharCode(0x00F6);
      final euro = String.fromCharCode(0x20AC);
      final emoji = String.fromCharCode(0x1F600);
      final hebrew = String.fromCharCode(0xFB33);

      final input = <String, dynamic>{
        euro: 'Euro Sign',
        carriageReturn: 'Carriage Return',
        hebrew: 'Hebrew Letter Dalet With Dagesh',
        '1': 'One',
        emoji: 'Emoji: Grinning Face',
        control: 'Control',
        diaeresis: 'Latin Small Letter O With Diaeresis',
      };

      expect(input.canonicalized().keys.toList(), [
        carriageReturn,
        '1',
        control,
        diaeresis,
        euro,
        emoji,
        hebrew,
      ]);
    });

    test('serializes the RFC 8785 sample canonically', () {
      final input =
          jsonDecode(_readJcsFixture('input', 'values.json'))
              as Map<String, dynamic>;
      final expected = _readCanonicalJcsFixture('values.json');

      expect(input.toCanonicalJson(), expected);
    });

    test('returns canonical JSON encoded as UTF-8 bytes', () {
      final input = <String, dynamic>{'b': 2, 'a': 1};

      expect(input.toCanonicalUtf8(), utf8.encode('{"a":1,"b":2}'));
    });

    test('canonicalizes official JCS array vector at the top level', () {
      final input =
          jsonDecode(_readJcsFixture('input', 'arrays.json')) as List<dynamic>;

      final expected = _readCanonicalJcsFixture('arrays.json');

      expect(input.toCanonicalJson(), expected);
      expect(input.toCanonicalUtf8(), utf8.encode(expected));
      expect(toCanonicalJcsJson(input), expected);
    });

    test('matches official JCS object vectors', () {
      const fixtureNames = [
        'structures.json',
        'unicode.json',
        'french.json',
        'weird.json',
      ];

      for (final fixtureName in fixtureNames) {
        final input =
            jsonDecode(_readJcsFixture('input', fixtureName))
                as Map<String, dynamic>;
        final expected = _readCanonicalJcsFixture(fixtureName);

        expect(input.toCanonicalJson(), expected);
        expect(input.toCanonicalUtf8(), utf8.encode(expected));
        expect(toCanonicalJcsJson(input), expected);
      }
    });

    test('serializes primitive top-level JSON values', () {
      expect(toCanonicalJcsJson(null), 'null');
      expect(toCanonicalJcsJson(true), 'true');
      expect(toCanonicalJcsJson('value'), '"value"');
      expect(toCanonicalJcsJson(1), '1');
      expect(toCanonicalJcsJson(-0.0), '0');

      expect(toCanonicalJcsUtf8('value'), utf8.encode('"value"'));
      expect(canonicalizeJcsValue('value'), 'value');
    });

    test('serializes strings using RFC 8785 escape rules', () {
      final input = <String, dynamic>{
        'value':
            '${String.fromCharCode(0x0000)}'
            '${String.fromCharCode(0x0008)}'
            '${String.fromCharCode(0x0009)}'
            '${String.fromCharCode(0x000A)}'
            '${String.fromCharCode(0x000C)}'
            '${String.fromCharCode(0x000D)}'
            '${String.fromCharCode(0x001F)}\\"',
      };

      expect(
        input.toCanonicalJson(),
        '{"value":"\\u0000\\b\\t\\n\\f\\r\\u001f\\\\\\""}',
      );
    });

    test('serializes RFC 8785 Appendix B-style number vectors', () {
      final cases = <MapEntry<Object, String>>[
        const MapEntry(0.0, '{"value":0}'),
        const MapEntry(-0.0, '{"value":0}'),
        const MapEntry(5e-324, '{"value":5e-324}'),
        const MapEntry(-5e-324, '{"value":-5e-324}'),
        const MapEntry(
          1.7976931348623157e308,
          '{"value":1.7976931348623157e+308}',
        ),
        const MapEntry(
          -1.7976931348623157e308,
          '{"value":-1.7976931348623157e+308}',
        ),
        const MapEntry(9007199254740992, '{"value":9007199254740992}'),
        const MapEntry(-9007199254740992, '{"value":-9007199254740992}'),
        const MapEntry(9.999999999999997e22, '{"value":9.999999999999997e+22}'),
        const MapEntry(1e23, '{"value":1e+23}'),
        const MapEntry(
          1.0000000000000001e23,
          '{"value":1.0000000000000001e+23}',
        ),
        const MapEntry(
          999999999999999700000.0,
          '{"value":999999999999999700000}',
        ),
        const MapEntry(
          999999999999999900000.0,
          '{"value":999999999999999900000}',
        ),
        const MapEntry(1e21, '{"value":1e+21}'),
        const MapEntry(9.999999999999997e-7, '{"value":9.999999999999997e-7}'),
        const MapEntry(0.000001, '{"value":0.000001}'),
        const MapEntry(333333333.3333332, '{"value":333333333.3333332}'),
        const MapEntry(333333333.33333325, '{"value":333333333.33333325}'),
        const MapEntry(333333333.3333333, '{"value":333333333.3333333}'),
        const MapEntry(333333333.3333334, '{"value":333333333.3333334}'),
        const MapEntry(333333333.33333343, '{"value":333333333.33333343}'),
        const MapEntry(
          -0.0000033333333333333333,
          '{"value":-0.0000033333333333333333}',
        ),
        const MapEntry(1424953923781206.25, '{"value":1424953923781206.2}'),
      ];

      for (final testCase in cases) {
        expect(
          <String, dynamic>{'value': testCase.key}.toCanonicalJson(),
          testCase.value,
        );
      }
    });

    test('rejects non-finite numbers', () {
      expect(
        () => <String, dynamic>{'value': double.nan}.toCanonicalJson(),
        throwsFormatException,
      );
      expect(
        () => <String, dynamic>{'value': double.infinity}.toCanonicalJson(),
        throwsFormatException,
      );
    });

    test('accepts integers exactly representable as IEEE 754 doubles', () {
      expect(
        <String, dynamic>{'value': 9007199254740992}.toCanonicalJson(),
        '{"value":9007199254740992}',
      );
    });

    test('rejects integers not exactly representable as IEEE 754 doubles', () {
      expect(
        () => <String, dynamic>{'value': 9007199254740993}.toCanonicalJson(),
        throwsFormatException,
      );
    });

    test('rejects lone surrogate strings', () {
      final loneLowSurrogate = String.fromCharCode(0xDEAD);

      expect(
        () => <String, dynamic>{'value': loneLowSurrogate}.toCanonicalJson(),
        throwsFormatException,
      );
    });

    test('rejects lone high surrogate strings', () {
      final loneHighSurrogate = String.fromCharCode(0xD83D);

      expect(
        () => <String, dynamic>{'value': loneHighSurrogate}.toCanonicalJson(),
        throwsFormatException,
      );
    });

    test('rejects high surrogate not followed by low surrogate', () {
      final invalidPair = String.fromCharCodes([0xD83D, 0x0041]);

      expect(
        () => <String, dynamic>{'value': invalidPair}.toCanonicalJson(),
        throwsFormatException,
      );
    });

    test('accepts valid surrogate pairs', () {
      final emoji = String.fromCharCode(0x1F600);

      expect(
        <String, dynamic>{'value': emoji}.toCanonicalJson(),
        '{"value":"😀"}',
      );
    });
  });
}

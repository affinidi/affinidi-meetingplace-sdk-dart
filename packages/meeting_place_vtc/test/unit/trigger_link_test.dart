import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

// `trigger_link_vectors.json` is copied unchanged from Keyring
// (github.com/berkmancenter/keyring-bifold @ 881d284,
// packages/core/src/modules/trust-tasks/__tests__/fixtures/
// trigger-link-vectors.json, Apache-2.0): the conformance vectors of the VTI
// trigger-link chapter. Update it by copying a newer revision whole, never by
// editing a vector.
final _file =
    jsonDecode(
          File('test/fixtures/trigger_link_vectors.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

TriggerLinkConfig _configFromVectors(Map<String, dynamic> json) {
  return TriggerLinkConfig(
    skewSeconds: json['skew'] as int,
    maxLinkLength: json['maxLinkLength'] as int,
    aliasSchemes: (json['aliasSchemes'] as List).cast<String>(),
    flows: [
      for (final flow in (json['flows'] as List).cast<Map<String, dynamic>>())
        TriggerFlow(
          flow: flow['flow'] as String,
          typeBase: flow['typeBase'] as String,
          isDraft: flow['status'] == 'draft',
          expRequired: flow['expRequired'] as bool,
          allowedDidMethods: switch (flow['allowedVidTypes']) {
            final List<dynamic> methods => methods.cast<String>(),
            _ => null,
          },
          supportedVersions: {
            for (final MapEntry(:key, :value)
                in (flow['supported'] as Map<String, dynamic>).entries)
              int.parse(key): switch (value) {
                final List<dynamic> minors => minors.cast<int>(),
                _ => null,
              },
          },
        ),
    ],
  );
}

Map<String, dynamic> _asExpectation(TriggerLinkResult result) {
  return switch (result) {
    TriggerLinkAccepted() => {
      'outcome': 'accept',
      'via': 'url',
      'from': result.from,
      'id': result.id,
      'exp': result.exp,
      'flow': result.flow,
      'task': switch (result.task) {
        final TriggerTask task => {
          'uri': task.uri,
          'major': task.major,
          'minor': task.minor,
        },
        null => null,
      },
      'ignored': result.ignored,
    },
    TriggerLinkRejected(:final reason, :final ui) => {
      'outcome': 'reject',
      'reason': reason,
      'ui': ui == TriggerLinkUi.passOn ? 'pass-on' : ui.name,
    },
  };
}

void main() {
  final vectorConfig = _file['config'] as Map<String, dynamic>;
  final config = _configFromVectors(vectorConfig);
  final now = vectorConfig['now'] as int;
  final vectors = (_file['vectors'] as List).cast<Map<String, dynamic>>();

  group('TriggerLink.read: every conformance vector', () {
    test('has the vectors it runs', () {
      expect(vectors, hasLength(161));
    });

    for (final vector in vectors) {
      test(vector['id'], () {
        final result = TriggerLink.read(
          vector['input'] as String,
          config: config,
          now: now,
        );
        expect(_asExpectation(result), vector['expect']);
      });
    }
  });

  group('TriggerLink.read with the Meeting Place config', () {
    const now = 1791460800;
    String link(String type, {int exp = now + 120}) =>
        'https://link.trustoverip.org/t'
        '#_from=did:webvh:QmCommScid:portal.community.example'
        '&_id=q3Vn7Zk2Xo9Rt1LwPb4HdA&_exp=$exp&_type=$type';

    test('carries a sign-in through', () {
      final result = TriggerLink.read(link('/vti/flow/sign-in/0.1'), now: now);

      expect(result, isA<TriggerLinkAccepted>());
      expect((result as TriggerLinkAccepted).flow, signInFlow);
      expect(result.id, 'q3Vn7Zk2Xo9Rt1LwPb4HdA');
      expect(result.uiFor(TriggerLinkConfig.meetingPlace), isNull);
    });

    test('says update for an agent claim, which it does not implement', () {
      final result = TriggerLink.read(
        link('/vti/flow/vta-claim/0.1'),
        now: now,
      );

      expect(result, isA<TriggerLinkAccepted>());
      expect(
        result.uiFor(TriggerLinkConfig.meetingPlace),
        TriggerLinkUi.update,
      );
    });

    test('says a sign-in past its expiry has expired', () {
      final result = TriggerLink.read(
        link('/vti/flow/sign-in/0.1', exp: now - 61),
        now: now,
      );

      expect(
        result.uiFor(TriggerLinkConfig.meetingPlace),
        TriggerLinkUi.expired,
      );
    });

    test('never puts the text it read into a rejection', () {
      final result =
          TriggerLink.read(
                link(
                  '/vti/flow/sign-in/0.1',
                ).replaceFirst('_id=q3Vn7Zk2Xo9Rt1LwPb4HdA', '_id=short'),
                now: now,
              )
              as TriggerLinkRejected;

      expect(result.reason, 'bad-id');
      expect(result.ui, TriggerLinkUi.invalid);
    });
  });
}

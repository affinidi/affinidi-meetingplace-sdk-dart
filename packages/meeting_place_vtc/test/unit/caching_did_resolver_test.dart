import 'dart:async';

import 'package:meeting_place_vtc/src/vtc/caching_did_resolver.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

const _did = 'did:webvh:QmCommScid:community.example';

DidDocument _document() => DidDocument.fromJson({
  '@context': ['https://www.w3.org/ns/did/v1'],
  'id': _did,
});

/// Answers each resolution with the next of [answers], counting them.
class _CountingResolver implements DidResolver {
  _CountingResolver(this.answers);

  final List<Future<DidDocument> Function()> answers;
  int calls = 0;

  @override
  Future<DidDocument> resolveDid(String did) => answers[calls++]();
}

void main() {
  group('CachingDidResolver', () {
    late DateTime now;

    setUp(() => now = DateTime(2026));

    CachingDidResolver cachingIn(_CountingResolver inner) => CachingDidResolver(
      inner,
      ttl: const Duration(minutes: 5),
      now: () => now,
    );

    test('resolves a DID once within the ttl', () async {
      final inner = _CountingResolver([() async => _document()]);
      final resolver = cachingIn(inner);

      await resolver.resolveDid(_did);
      now = now.add(const Duration(minutes: 4));
      final document = await resolver.resolveDid(_did);

      expect(document.id, _did);
      expect(inner.calls, 1);
    });

    test('resolves again once the ttl has passed', () async {
      final inner = _CountingResolver([
        () async => _document(),
        () async => _document(),
      ]);
      final resolver = cachingIn(inner);

      await resolver.resolveDid(_did);
      now = now.add(const Duration(minutes: 5));
      await resolver.resolveDid(_did);

      expect(inner.calls, 2);
    });

    test('shares a resolution already under way', () async {
      final pending = Completer<DidDocument>();
      final inner = _CountingResolver([() => pending.future]);
      final resolver = cachingIn(inner);

      final first = resolver.resolveDid(_did);
      final second = resolver.resolveDid(_did);
      pending.complete(_document());

      expect((await first).id, _did);
      expect((await second).id, _did);
      expect(inner.calls, 1);
    });

    test('does not keep a failure', () async {
      final inner = _CountingResolver([
        () async => throw StateError('unreachable'),
        () async => _document(),
      ]);
      final resolver = cachingIn(inner);

      await expectLater(resolver.resolveDid(_did), throwsStateError);
      final document = await resolver.resolveDid(_did);

      expect(document.id, _did);
      expect(inner.calls, 2);
    });
  });
}

import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:test/test.dart';

import '../fixtures/vrc_fixture.dart';

void main() {
  late VrcParser parser;

  setUp(() {
    parser = VrcParser();
  });

  group('VrcParser', () {
    test('returns null for empty string', () async {
      final result = await parser.parse(vcBlob: '');
      expect(result, isNull);
    });

    test('returns null for invalid JSON', () async {
      final result = await parser.parse(vcBlob: 'not-json');
      expect(result, isNull);
    });

    test('returns null for VC missing RelationshipCredential type', () async {
      final result = await parser.parse(vcBlob: vrcBlobMissingType);
      expect(result, isNull);
    });

    test('returns null for VRC blob without proof', () async {
      final result = await parser.parse(vcBlob: vrcBlobWithoutProof);
      expect(result, isNull);
    });

    test('returns null for VRC blob without id', () async {
      final result = await VrcParser.parse(
        vcBlob: vrcBlobWithoutId,
        channelId: 'ch-1',
      );
      expect(result, isNull);
    });
  });
}

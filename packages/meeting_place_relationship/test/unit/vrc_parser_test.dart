import 'package:meeting_place_relationship/src/parsers/vrc_parser.dart';
import 'package:test/test.dart';

import '../fixtures/vrc_fixture.dart';

void main() {
  group('VrcParser', () {
    test('returns null for empty string', () async {
      final result = await VrcParser.parse(vcBlob: '', channelId: 'ch-1');
      expect(result, isNull);
    });

    test('returns null for invalid JSON', () async {
      final result = await VrcParser.parse(
        vcBlob: 'not-json',
        channelId: 'ch-1',
      );
      expect(result, isNull);
    });

    test('returns null for VC missing RelationshipCredential type', () async {
      final result = await VrcParser.parse(
        vcBlob: vrcBlobMissingType,
        channelId: 'ch-1',
      );
      expect(result, isNull);
    });

    test('returns null for VRC blob without proof', () async {
      final result = await VrcParser.parse(
        vcBlob: vrcBlobWithoutProof,
        channelId: 'ch-1',
      );
      expect(result, isNull);
    });
  });
}

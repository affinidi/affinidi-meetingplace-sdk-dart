import 'dart:convert';

import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:test/test.dart';

void main() {
  group('LivenessZkpDIDCommAttachmentBuilder', () {
    test('buildLivenessCheckRequest encodes expected format and payload', () {
      final list =
          LivenessZkpDIDCommAttachmentBuilder.buildLivenessCheckRequest(
            attachmentId: 'req-1',
            lastModified: DateTime.utc(2026, 1, 2),
          );

      expect(list, hasLength(1));
      final att = list.single;
      expect(att.id, 'req-1');
      expect(att.format, LivenessZkpProtocol.livenessCheckRequestFormat);
      expect(att.mediaType, 'application/json');

      final map = jsonDecode(att.data!.json!) as Map<String, dynamic>;
      expect(
        map[LivenessZkpProtocol.typeJsonKey],
        LivenessZkpProtocol.livenessRequestPayloadType,
      );
      expect(LivenessZkpAttachmentParser.tryParseRequest(att), isNotNull);
    });

    test('buildLivenessProof encodes proof payload', () {
      const payload = LivenessProofPayload(proof: 'p1', publicSignals: 's1');

      final list = LivenessZkpDIDCommAttachmentBuilder.buildLivenessProof(
        payload: payload,
        attachmentId: 'proof-1',
        lastModified: DateTime.utc(2026, 1, 3),
      );

      expect(list, hasLength(1));
      final att = list.single;
      expect(att.format, LivenessZkpProtocol.livenessProofFormat);

      final map = jsonDecode(att.data!.json!) as Map<String, dynamic>;
      expect(map, payload.toJson());
    });
  });
}

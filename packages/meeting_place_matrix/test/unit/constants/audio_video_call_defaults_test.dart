import 'package:meeting_place_matrix/src/constants/audio_video_call_defaults.dart';
import 'package:test/test.dart';

void main() {
  group('AudioVideoCallDefaults', () {
    test('sharedKeyEncryption uses per-participant keys', () {
      expect(AudioVideoCallDefaults.sharedKeyEncryption, isFalse);
    });
  });
}

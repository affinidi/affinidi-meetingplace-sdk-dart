import 'package:meeting_place_matrix/src/constants/audio_video_call_defaults.dart';
import 'package:test/test.dart';

void main() {
  group('AudioVideoCallDefaults', () {
    test('sharedKeyEncryption is enabled as a temporary measure', () {
      expect(AudioVideoCallDefaults.sharedKeyEncryption, isTrue);
    });
  });
}

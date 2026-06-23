import 'package:flutter_test/flutter_test.dart';
import 'package:meeting_place_matrix_livekit/src/constants/audio_video_call_defaults.dart';

void main() {
  group('AudioVideoCallDefaults', () {
    test('sharedKeyEncryption is enabled as a temporary measure', () {
      expect(AudioVideoCallDefaults.sharedKeyEncryption, isTrue);
    });
  });
}

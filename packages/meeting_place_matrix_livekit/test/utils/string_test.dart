import 'package:meeting_place_matrix_livekit/src/utils/string.dart';
import 'package:test/test.dart';

void main() {
  group('topAndTail', () {
    test('truncates a long string keeping the head and tail', () {
      const did = 'did:key:zABCDEFGHIJKLMNOPQRSTUVWXYZ';

      expect(did.topAndTail(), 'did:key:zABCDEFG...STUVWXYZ');
    });

    test('joins head and tail with an ellipsis using custom counts', () {
      const value = 'abcdefghijklmnop';

      expect(value.topAndTail(charCountTop: 4, charCountTail: 3), 'abcd...nop');
    });

    test('returns the original string when shorter than charCountTop', () {
      const value = 'short';

      expect(value.topAndTail(), 'short');
    });

    test('omits the ellipsis when charCountTop is zero', () {
      const value = 'abcdefghijklmnop';

      expect(value.topAndTail(charCountTop: 0, charCountTail: 4), 'mnop');
    });

    test('returns the original string when the tail would underflow', () {
      const value = 'abc';

      expect(value.topAndTail(charCountTop: 1, charCountTail: 10), 'abc');
    });
  });
}

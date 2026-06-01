import 'package:meeting_place_chat/src/event/chat_stream.dart';
import 'package:meeting_place_chat/src/event/stream_data.dart';
import 'package:test/test.dart';

void main() {
  group('ChatStream buffering', () {
    test(
      'events pushed before listener are flushed via .stream.listen',
      () async {
        final chatStream = ChatStream();
        final a = StreamData();
        final b = StreamData();

        chatStream.pushData(a);
        chatStream.pushData(b);

        final collected = <StreamData>[];
        chatStream.stream.listen(collected.add);

        await Future<void>.delayed(Duration.zero);

        expect(collected, [a, b]);
      },
    );

    test('events pushed after listener are delivered live', () async {
      final chatStream = ChatStream();
      final collected = <StreamData>[];
      chatStream.stream.listen(collected.add);

      final a = StreamData();
      chatStream.pushData(a);

      await Future<void>.delayed(Duration.zero);
      expect(collected, [a]);
    });

    test('buffer is flushed only once on first listen', () async {
      final chatStream = ChatStream();
      final a = StreamData();
      chatStream.pushData(a);

      final firstCollected = <StreamData>[];
      final sub = chatStream.stream.listen(firstCollected.add);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      final secondCollected = <StreamData>[];
      chatStream.stream.listen(secondCollected.add);
      await Future<void>.delayed(Duration.zero);

      expect(firstCollected, [a]);
      expect(secondCollected, isEmpty);
    });
  });
}

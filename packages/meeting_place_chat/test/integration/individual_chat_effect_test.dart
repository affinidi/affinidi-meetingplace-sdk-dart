import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../utils/chat_test_harness.dart';
import 'utils/individual_chat_fixture.dart';

void main() {
  late IndividualChatFixture fixture;

  setUp(() async {
    fixture = await IndividualChatFixture.create();
  });

  tearDown(() {
    fixture.dispose();
  });

  test('sendEffect delivers ChatEffectEvent to other party', () async {
    await fixture.aliceChatSDK.startChatSession();
    await fixture.bobChatSDK.startChatSession();

    final bobEffect = ChatTestHarness.awaitEvent<ChatEffectEvent>(
      fixture.bobChatSDK,
      where: (e) => e.effectName == Effect.confetti.name,
    );

    await fixture.aliceChatSDK.sendEffect(Effect.confetti);

    final received = await bobEffect;
    expect(received.effectName, equals(Effect.confetti.name));
  });
}

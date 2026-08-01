import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:test/test.dart';

import '../../../utils/chat_test_harness.dart';
import '../../utils/group_chat_fixture.dart';

const _fixtureCreateMaxAttempts = 2;

Future<GroupChatFixture> _createFixtureWithRetry() async {
  Object? lastError;
  StackTrace? lastStackTrace;

  for (var attempt = 1; attempt <= _fixtureCreateMaxAttempts; attempt++) {
    try {
      return await GroupChatFixture.create();
    } catch (error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      if (attempt == _fixtureCreateMaxAttempts) rethrow;
    }
  }

  Error.throwWithStackTrace(lastError!, lastStackTrace!);
}

void main() {
  GroupChatFixture? fixture;

  setUp(() async {
    fixture = await _createFixtureWithRetry();
  });

  tearDown(() async {
    if (fixture != null) {
      await fixture!.disposeSessions();
      fixture = null;
    }
  });

  test(
    'owner leaving group emits ChatGroupDeletedEvent on remaining members',
    () async {
      final currentFixture = fixture!;
      await currentFixture.startAliceChatSession();
      await currentFixture.startBobChatSession();
      await currentFixture.startCharlieChatSession();

      final groupDid =
          currentFixture.publishOfferResult.connectionOffer.groupDid!;

      final bobDeleted = ChatTestHarness.awaitEvent<ChatGroupDeletedEvent>(
        currentFixture.bobChatSDK,
        where: (e) => e.groupDid == groupDid,
      );
      final charlieDeleted = ChatTestHarness.awaitEvent<ChatGroupDeletedEvent>(
        currentFixture.charlieChatSDK,
        where: (e) => e.groupDid == groupDid,
      );

      final aliceChannel = await currentFixture.aliceSDK.getChannelByDid(
        currentFixture.groupOwnerDidDocument.id,
      );
      await currentFixture.aliceSDK.leaveChannel(aliceChannel!);

      await bobDeleted;
      await charlieDeleted;
    },
  );

  test(
    'member leaving group emits ChatMemberDeregisteredEvent on others',
    () async {
      final currentFixture = fixture!;
      await currentFixture.startAliceChatSession();
      await currentFixture.startBobChatSession();
      await currentFixture.startCharlieChatSession();

      final groupDid =
          currentFixture.publishOfferResult.connectionOffer.groupDid!;

      final aliceLeft = ChatTestHarness.awaitEvent<ChatMemberDeregisteredEvent>(
        currentFixture.aliceChatSDK,
        where: (e) =>
            e.groupDid == groupDid &&
            e.memberDid == currentFixture.bobMemberDid,
      );
      final charlieLeft =
          ChatTestHarness.awaitEvent<ChatMemberDeregisteredEvent>(
            currentFixture.charlieChatSDK,
            where: (e) =>
                e.groupDid == groupDid &&
                e.memberDid == currentFixture.bobMemberDid,
          );

      final bobChannel = await currentFixture.bobSDK.getChannelByDid(
        currentFixture.bobMemberDid,
      );
      await currentFixture.bobSDK.leaveChannel(bobChannel!);

      await aliceLeft;
      await charlieLeft;
    },
  );
}

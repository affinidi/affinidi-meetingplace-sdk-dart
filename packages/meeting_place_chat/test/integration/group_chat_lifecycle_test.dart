// import 'package:meeting_place_chat/meeting_place_chat.dart';
// import 'package:test/test.dart';

// import '../utils/chat_test_harness.dart';
// import 'utils/group_chat_fixture.dart';

// void main() {
//   late GroupChatFixture fixture;

//   setUp(() async {
//     fixture = await GroupChatFixture.create();
//   });

//   tearDown(() {
//     fixture.disposeSessions();
//   });

//   test(
//     'owner leaving group emits ChatGroupDeletedEvent on remaining members',
//     () async {
//       await fixture.aliceChatSDK.startChatSession();
//       await fixture.bobChatSDK.startChatSession();
//       await fixture.charlieChatSDK.startChatSession();

//       final groupDid = fixture.publishOfferResult.connectionOffer.groupDid!;

//       final bobDeleted = ChatTestHarness.awaitEvent<ChatGroupDeletedEvent>(
//         fixture.bobChatSDK,
//         where: (e) => e.groupDid == groupDid,
//       );
//       final charlieDeleted = ChatTestHarness.awaitEvent<ChatGroupDeletedEvent>(
//         fixture.charlieChatSDK,
//         where: (e) => e.groupDid == groupDid,
//       );

//       final aliceChannel = await fixture.aliceSDK.getChannelByDid(
//         fixture.groupOwnerDidDocument.id,
//       );
//       await fixture.aliceSDK.leaveChannel(aliceChannel!);

//       await bobDeleted;
//       await charlieDeleted;
//     },
//   );

//   test(
//     'member leaving group emits ChatMemberDeregisteredEvent on others',
//     () async {
//       await fixture.aliceChatSDK.startChatSession();
//       await fixture.bobChatSDK.startChatSession();
//       await fixture.charlieChatSDK.startChatSession();

//       final groupDid = fixture.publishOfferResult.connectionOffer.groupDid!;

//       final aliceLeft = ChatTestHarness.awaitEvent<ChatMemberDeregisteredEvent>(
//         fixture.aliceChatSDK,
//         where: (e) =>
//             e.groupDid == groupDid && e.memberDid == fixture.bobMemberDid,
//       );
//       final charlieLeft =
//           ChatTestHarness.awaitEvent<ChatMemberDeregisteredEvent>(
//             fixture.charlieChatSDK,
//             where: (e) =>
//                 e.groupDid == groupDid && e.memberDid == fixture.bobMemberDid,
//           );

//       final bobChannel = await fixture.bobSDK.getChannelByDid(
//         fixture.bobMemberDid,
//       );
//       await fixture.bobSDK.leaveChannel(bobChannel!);

//       await aliceLeft;
//       await charlieLeft;
//     },
//   );
// }

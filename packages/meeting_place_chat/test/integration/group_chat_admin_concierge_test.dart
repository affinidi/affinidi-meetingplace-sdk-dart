import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../utils/sdk.dart';
import 'utils/group_chat_fixture.dart';

void main() {
  late GroupChatFixture fixture;

  setUpAll(() async {
    fixture = await GroupChatFixture.create();
  });

  tearDown(() {
    fixture.disposeSessions();
  });

  test('group admin sees concierge message for pending approvals', () async {
    await fixture.anotherMemberJoinsGroup();

    final completer = Completer<void>();
    fixture.aliceSDK.controlPlaneEventsStream.listen((event) {
      if (event.type == ControlPlaneEventType.InvitationGroupAccept) {
        if (!completer.isCompleted) completer.complete();
      }
    });

    await fixture.aliceSDK.processControlPlaneEvents();
    await completer.future;

    final newGroup = await fixture.aliceSDK.getGroupById(fixture.aliceGroup.id);
    final newAliceChatSDK = await initGroupChatSDK(
      coreSDK: fixture.aliceSDK,
      did: fixture.groupOwnerDidDocument.id,
      otherPartyDid: fixture.publishOfferResult.connectionOffer.groupDid!,
      group: newGroup!,
      channelRepository: fixture.aliceChannelRepository,
    );

    final chat = await newAliceChatSDK.startChatSession();
    expect(chat.messages.whereType<ConciergeMessage>().length, equals(1));

    final conciergeMessage = chat.messages.whereType<ConciergeMessage>().first;
    await newAliceChatSDK.approveConnectionRequest(conciergeMessage);

    expect(conciergeMessage.status, ChatItemStatus.confirmed);
    newAliceChatSDK.endChatSession();
  });

  test('group admin rejects connection request', () async {
    final (newMemberSDK, acceptance) = await fixture.anotherMemberJoinsGroup();

    final completer = Completer<void>();
    fixture.aliceSDK.controlPlaneEventsStream.listen((event) {
      if (event.type == ControlPlaneEventType.InvitationGroupAccept &&
          event.channel.offerLink == acceptance.connectionOffer.offerLink) {
        completer.complete();
      }
    });

    await fixture.bobChatSDK.startChatSession();

    await Future<void>.delayed(const Duration(seconds: 2));
    await fixture.aliceSDK.processControlPlaneEvents();
    await completer.future;

    final newGroup = await fixture.aliceSDK.getGroupById(fixture.aliceGroup.id);
    final newAliceChatSDK = await initGroupChatSDK(
      coreSDK: fixture.aliceSDK,
      did: fixture.groupOwnerDidDocument.id,
      otherPartyDid: fixture.publishOfferResult.connectionOffer.groupDid!,
      group: newGroup!,
      channelRepository: fixture.aliceChannelRepository,
    );

    final chat = await newAliceChatSDK.startChatSession();

    await Future<void>.delayed(const Duration(seconds: 2));

    final conciergeMessage = chat.messages.whereType<ConciergeMessage>().first;
    await newAliceChatSDK.rejectConnectionRequest(conciergeMessage);

    final newMemberDidDoc = await acceptance.permanentChannelDid
        .getDidDocument();

    final updatedGroup = await fixture.aliceSDK.getGroupById(
      fixture.aliceGroup.id,
    );
    expect(conciergeMessage.status, ChatItemStatus.confirmed);
    expect(updatedGroup!.members.length, equals(4));
    expect(
      updatedGroup.members.firstWhereOrNull(
        (member) => member.did == newMemberDidDoc.id,
      ),
      isNull,
    );

    newAliceChatSDK.endChatSession();
    // Silence unused variable warning while keeping the original signature.
    // (The SDK is created to mimic a real joining member.)
    // ignore: unnecessary_statements
    newMemberSDK;
  });
}

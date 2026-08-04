import 'dart:async';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/chat/group/group_matrix_chat_sdk.dart';
import 'package:meeting_place_matrix/src/matrix_room_subscription.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../utils/repository/chat_repository_impl.dart';
import '../../../../utils/storage/in_memory_storage.dart';

class _MockCoreSDK extends Mock implements MeetingPlaceCoreSDK {}

class _FakeIncomingMessageHandle implements IncomingMessageHandle {
  _FakeIncomingMessageHandle(this._controller);

  final StreamController<IncomingMessage> _controller;

  @override
  Stream<IncomingMessage> get stream => _controller.stream;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

const _aliceDid = 'did:test:alice';
const _bobDid = 'did:test:bob';
const _groupDid = 'did:test:group';
const _mediatorDid = 'did:test:mediator';

ContactCard _card(String did) =>
    ContactCard(did: did, type: 'human', contactInfo: {'n': did});

Channel _channel() => Channel(
  offerLink: 'offer://group',
  publishOfferDid: _aliceDid,
  mediatorDid: _mediatorDid,
  status: ChannelStatus.inaugurated,
  contactCard: _card(_aliceDid),
  type: ChannelType.group,
  isConnectionInitiator: true,
  permanentChannelDid: _aliceDid,
  otherPartyPermanentChannelDid: _groupDid,
);

Group _group() => Group(
  id: 'group-1',
  did: _groupDid,
  offerLink: 'offer://group',
  created: DateTime.utc(2026, 1, 1),
  ownerDid: _bobDid,
  publicKey: 'pk',
  status: GroupStatus.created,
  members: [
    GroupMember.admin(
      did: _bobDid,
      publicKey: 'pk-bob',
      contactCard: _card(_bobDid),
    ),
    GroupMember(
      did: _aliceDid,
      publicKey: 'pk-alice',
      dateAdded: DateTime.utc(2026, 1, 1),
      status: GroupMemberStatus.approved,
      membershipType: GroupMembershipType.member,
      contactCard: _card(_aliceDid),
    ),
  ],
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const MatrixRoomSubscription(
        receiverDid: '',
        options: TransportSubscriptionOptions(excludeSelf: true),
      ),
    );
    registerFallbackValue(
      const DidCommSubscription(receiverDid: '', mediatorDid: ''),
    );
    registerFallbackValue(_channel());
    registerFallbackValue(
      DidCommOutgoingMessage(
        senderDid: '',
        recipientDid: '',
        mediatorDid: '',
        payload: PlainTextMessage(
          id: 'fallback',
          type: Uri.parse('https://example.com'),
          body: {},
        ),
      ),
    );
  });

  test(
    'GroupMatrixChatSDK contains a Matrix room stream error and keeps handling '
    'subsequent messages',
    () async {
      final core = _MockCoreSDK();
      final incomingController = StreamController<IncomingMessage>.broadcast();
      final repo = ChatRepositoryImpl(storage: InMemoryStorage());

      when(
        () => core.subscribe(any()),
      ).thenAnswer((_) async => _FakeIncomingMessageHandle(incomingController));
      when(
        () => core.getChannelByOtherPartyPermanentDid(_groupDid),
      ).thenAnswer((_) async => _channel());
      when(() => core.sendMessage(any())).thenAnswer((_) async => 'ok');
      when(() => core.updateChannel(any())).thenAnswer((_) async {});

      final sdk = GroupMatrixChatSDK(
        coreSDK: core,
        did: _aliceDid,
        otherPartyDid: _groupDid,
        mediatorDid: _mediatorDid,
        chatRepository: repo,
        options: MeetingPlaceChatSDKOptions(
          chatPresenceSendInterval: const Duration(hours: 1),
        ),
        group: _group(),
      );

      final unhandled = <Object>[];
      await runZonedGuarded(() async {
        await sdk.startChatSession();
        await Future<void>.delayed(Duration.zero);

        incomingController.addError(
          StateError('Matrix room not found'),
          StackTrace.current,
        );
        await Future<void>.delayed(Duration.zero);

        incomingController.add(
          DidCommIncomingMessage(
            senderDid: _bobDid,
            timestamp: DateTime.utc(2026),
            payload: PlainTextMessage(
              id: 'group-mediator-msg-after-error',
              type: Uri.parse(ChatProtocol.chatMessage.value),
              from: _bobDid,
              to: [_groupDid],
              body: {
                'text': 'Still alive after error',
                'seq_no': 1,
                'timestamp': DateTime.utc(2026).toIso8601String(),
              },
              createdTime: DateTime.utc(2026),
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }, (error, _) => unhandled.add(error));

      expect(unhandled, isEmpty);

      final messages = await sdk.messages;
      expect(messages, hasLength(1));
      expect(
        (messages.single as Message).messageId,
        'group-mediator-msg-after-error',
      );

      await sdk.endChatSession();
      if (!incomingController.isClosed) {
        await incomingController.close();
      }
    },
  );
}

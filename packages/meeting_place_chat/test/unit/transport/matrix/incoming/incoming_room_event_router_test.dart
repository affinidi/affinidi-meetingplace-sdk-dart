import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_chat/src/transport/matrix/incoming/incoming_room_event_router.dart';
import 'package:meeting_place_chat/src/transport/matrix/matrix_user_id_cache.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockChatEventHandler extends Mock implements ChatEventHandler {}

class _TestRouter extends IncomingRoomEventRouter {
  _TestRouter({
    required super.didCache,
    required super.matrixHandlers,
    required super.chatHandlers,
    super.chatStream,
    // ignore: invalid_use_of_protected_member
  }) : super.withHandlers();
}

MatrixRoomEvent _event({
  required String type,
  Map<String, dynamic> content = const {},
}) => MatrixRoomEvent(
  id: 'evt-1',
  type: type,
  userId: '@alice:server',
  roomId: '!room:server',
  content: content,
  timestamp: DateTime.utc(2026, 1, 1),
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      IncomingChatEvent(type: '', senderDid: null, content: const {}),
    );
  });

  group('IncomingRoomEventRouter._translate via route()', () {
    late _MockChatEventHandler memberJoinedHandler;
    late _MockChatEventHandler memberLeftHandler;
    late _MockChatEventHandler groupDeletionHandler;
    late _MockChatEventHandler groupDetailsHandler;
    late _MockChatEventHandler contactDetailsHandler;
    late _MockChatEventHandler chatEffectHandler;
    late _MockChatEventHandler fallthroughHandler;
    late _TestRouter router;

    setUp(() {
      memberJoinedHandler = _MockChatEventHandler();
      memberLeftHandler = _MockChatEventHandler();
      groupDeletionHandler = _MockChatEventHandler();
      groupDetailsHandler = _MockChatEventHandler();
      contactDetailsHandler = _MockChatEventHandler();
      chatEffectHandler = _MockChatEventHandler();
      fallthroughHandler = _MockChatEventHandler();

      for (final h in [
        memberJoinedHandler,
        memberLeftHandler,
        groupDeletionHandler,
        groupDetailsHandler,
        contactDetailsHandler,
        chatEffectHandler,
        fallthroughHandler,
      ]) {
        when(() => h.handle(any())).thenAnswer((_) async {});
      }

      router = _TestRouter(
        didCache: MatrixUserIdCache(serverName: 'server'),
        matrixHandlers: const {},
        chatHandlers: {
          ChatEventTypes.memberJoined: memberJoinedHandler,
          ChatEventTypes.memberLeft: memberLeftHandler,
          ChatEventTypes.groupDeletion: groupDeletionHandler,
          ChatEventTypes.groupDetailsUpdate: groupDetailsHandler,
          ChatEventTypes.contactDetailsUpdate: contactDetailsHandler,
          ChatEventTypes.chatEffect: chatEffectHandler,
          'm.custom.thing': fallthroughHandler,
        },
      );
    });

    test('m.room.member with membership=join → memberJoined', () async {
      await router.route(
        _event(
          type: matrix.EventTypes.RoomMember,
          content: const {'membership': 'join'},
        ),
      );
      verify(() => memberJoinedHandler.handle(any())).called(1);
      verifyNever(() => memberLeftHandler.handle(any()));
    });

    test('m.room.member with membership=leave → memberLeft', () async {
      await router.route(
        _event(
          type: matrix.EventTypes.RoomMember,
          content: const {'membership': 'leave'},
        ),
      );
      verify(() => memberLeftHandler.handle(any())).called(1);
    });

    test('m.room.member with unknown membership → silently ignored', () async {
      await router.route(
        _event(
          type: matrix.EventTypes.RoomMember,
          content: const {'membership': 'invite'},
        ),
      );
      verifyNever(() => memberJoinedHandler.handle(any()));
      verifyNever(() => memberLeftHandler.handle(any()));
    });

    test('com.affinidi.chat.group-deletion → groupDeletion', () async {
      await router.route(_event(type: 'com.affinidi.chat.group-deletion'));
      verify(() => groupDeletionHandler.handle(any())).called(1);
    });

    test(
      'com.affinidi.chat.group-details-update → groupDetailsUpdate',
      () async {
        await router.route(
          _event(type: 'com.affinidi.chat.group-details-update'),
        );
        verify(() => groupDetailsHandler.handle(any())).called(1);
      },
    );

    test(
      'com.affinidi.chat.contact-details-update → contactDetailsUpdate',
      () async {
        await router.route(
          _event(type: 'com.affinidi.chat.contact-details-update'),
        );
        verify(() => contactDetailsHandler.handle(any())).called(1);
      },
    );

    test('com.affinidi.chat.effect → chatEffect', () async {
      await router.route(_event(type: 'com.affinidi.chat.effect'));
      verify(() => chatEffectHandler.handle(any())).called(1);
    });

    test('unknown type passes through unchanged (fallthrough)', () async {
      await router.route(_event(type: 'm.custom.thing'));
      verify(() => fallthroughHandler.handle(any())).called(1);
    });

    test(
      'unrouted type pushes UnhandledChatEvent to the chat stream',
      () async {
        final stream = ChatStream();
        final emitted = <StreamData>[];
        stream.listen(emitted.add);

        final unhandledRouter = _TestRouter(
          didCache: MatrixUserIdCache(serverName: 'server'),
          matrixHandlers: const {},
          chatHandlers: const {},
          chatStream: stream,
        );

        await unhandledRouter.route(
          _event(type: 'm.totally.unmapped', content: const {'k': 'v'}),
        );
        await Future<void>.delayed(Duration.zero);

        verifyNever(() => chatEffectHandler.handle(any()));
        expect(emitted.length, 1);
        final event = emitted.single.event;
        expect(event, isA<UnhandledChatEvent>());
        event as UnhandledChatEvent;
        expect(event.type, 'm.totally.unmapped');
        expect(event.body, {'k': 'v'});
      },
    );

    test('IncomingChatEvent.senderDid is resolved via the didCache', () async {
      final cache = MatrixUserIdCache(serverName: 'server');
      cache.register('did:test:alice');

      final captureRouter = _TestRouter(
        didCache: cache,
        matrixHandlers: const {},
        chatHandlers: {ChatEventTypes.chatEffect: chatEffectHandler},
      );

      await captureRouter.route(
        MatrixRoomEvent(
          id: 'evt-1',
          type: 'com.affinidi.chat.effect',
          userId: deriveMatrixUserId('did:test:alice', 'server'),
          roomId: '!room:server',
          content: const {'effect': 'confetti'},
          timestamp: DateTime.utc(2026, 1, 1),
        ),
      );

      final captured =
          verify(() => chatEffectHandler.handle(captureAny())).captured.single
              as IncomingChatEvent;
      expect(captured.senderDid, 'did:test:alice');
      expect(captured.type, ChatEventTypes.chatEffect);
      expect(captured.content, {'effect': 'confetti'});
    });
  });
}

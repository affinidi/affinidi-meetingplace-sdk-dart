import 'dart:io';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_drift_repository/meeting_place_drift_repository.dart';
import 'package:test/test.dart';

ChatItemsDatabase _inMemoryDatabase() => ChatItemsDatabase(
      databaseName: 'test.db',
      passphrase: 'test-passphrase',
      directory: Directory.systemTemp,
      inMemory: true,
      lazy: false,
    );

void main() {
  group('ChatItemsRepositoryDrift', () {
    late ChatItemsDatabase database;
    late ChatItemsRepositoryDrift repository;

    setUp(() {
      database = _inMemoryDatabase();
      repository = ChatItemsRepositoryDrift(database: database);
    });

    tearDown(() => database.close());

    group('ConciergeMessage', () {
      test('persists and retrieves a built-in concierge type', () async {
        final message = ConciergeMessage(
          chatId: 'chat-1',
          messageId: 'msg-1',
          senderDid: 'did:example:alice',
          isFromMe: false,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.userInput,
          conciergeType: ConciergeMessageType.permissionToJoinGroup,
          data: {'groupId': 'group-42'},
        );

        await repository.createMessage(message);
        final stored = await repository.getMessage(
          chatId: 'chat-1',
          messageId: 'msg-1',
        ) as ConciergeMessage;

        expect(
          stored.conciergeType,
          equals(ConciergeMessageType.permissionToJoinGroup),
        );
        expect(stored.data['groupId'], equals('group-42'));
      });

      test('persists and retrieves a custom concierge type', () async {
        const meetingRequest = ConciergeMessageType('meetingRequest');

        final message = ConciergeMessage(
          chatId: 'chat-1',
          messageId: 'msg-2',
          senderDid: 'did:example:bot',
          isFromMe: false,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.userInput,
          conciergeType: meetingRequest,
          data: {'scheduledAt': '2026-05-01T10:00:00Z'},
        );

        await repository.createMessage(message);
        final stored = await repository.getMessage(
          chatId: 'chat-1',
          messageId: 'msg-2',
        ) as ConciergeMessage;

        expect(stored.conciergeType, equals(meetingRequest));
        expect(stored.conciergeType.value, equals('meetingRequest'));
        expect(stored.data['scheduledAt'], equals('2026-05-01T10:00:00Z'));
      });

      test('listMessages returns custom concierge type', () async {
        const supportTicket = ConciergeMessageType('supportTicket');

        await repository.createMessage(
          ConciergeMessage(
            chatId: 'chat-1',
            messageId: 'msg-3',
            senderDid: 'did:example:support',
            isFromMe: false,
            dateCreated: DateTime.utc(2026),
            status: ChatItemStatus.userInput,
            conciergeType: supportTicket,
            data: {'ticketId': 'TKT-999'},
          ),
        );

        final messages = await repository.listMessages('chat-1');
        final result = messages.whereType<ConciergeMessage>().first;

        expect(result.conciergeType, equals(supportTicket));
      });

      test('updates status while preserving a custom concierge type', () async {
        const bookingApproval = ConciergeMessageType('bookingApproval');

        final message = ConciergeMessage(
          chatId: 'chat-1',
          messageId: 'msg-4',
          senderDid: 'did:example:alice',
          isFromMe: false,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.userInput,
          conciergeType: bookingApproval,
          data: {},
        );

        await repository.createMessage(message);
        message.status = ChatItemStatus.confirmed;
        await repository.updateMesssage(message);

        final updated = await repository.getMessage(
          chatId: 'chat-1',
          messageId: 'msg-4',
        ) as ConciergeMessage;

        expect(updated.status, equals(ChatItemStatus.confirmed));
        expect(updated.conciergeType, equals(bookingApproval));
      });
    });

    group('EventMessage', () {
      test('persists and retrieves a built-in event type', () async {
        final message = EventMessage(
          chatId: 'chat-1',
          messageId: 'evt-1',
          senderDid: 'did:example:group',
          isFromMe: false,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.received,
          eventType: EventMessageType.groupMemberJoinedGroup,
          data: {'memberDid': 'did:example:bob'},
        );

        await repository.createMessage(message);
        final stored = await repository.getMessage(
          chatId: 'chat-1',
          messageId: 'evt-1',
        ) as EventMessage;

        expect(
          stored.eventType,
          equals(EventMessageType.groupMemberJoinedGroup),
        );
      });

      test('persists and retrieves a custom event type', () async {
        const fileShared = EventMessageType('fileShared');

        final message = EventMessage(
          chatId: 'chat-1',
          messageId: 'evt-2',
          senderDid: 'did:example:alice',
          isFromMe: true,
          dateCreated: DateTime.utc(2026),
          status: ChatItemStatus.received,
          eventType: fileShared,
          data: {'filename': 'report.pdf', 'size': 204800},
        );

        await repository.createMessage(message);
        final stored = await repository.getMessage(
          chatId: 'chat-1',
          messageId: 'evt-2',
        ) as EventMessage;

        expect(stored.eventType, equals(fileShared));
        expect(stored.eventType.value, equals('fileShared'));
        expect(stored.data['filename'], equals('report.pdf'));
      });

      test('listMessages returns custom event type', () async {
        const callStarted = EventMessageType('callStarted');

        await repository.createMessage(
          EventMessage(
            chatId: 'chat-1',
            messageId: 'evt-3',
            senderDid: 'did:example:alice',
            isFromMe: true,
            dateCreated: DateTime.utc(2026),
            status: ChatItemStatus.received,
            eventType: callStarted,
            data: {},
          ),
        );

        final messages = await repository.listMessages('chat-1');
        final result = messages.whereType<EventMessage>().first;

        expect(result.eventType, equals(callStarted));
      });
    });
  });
}

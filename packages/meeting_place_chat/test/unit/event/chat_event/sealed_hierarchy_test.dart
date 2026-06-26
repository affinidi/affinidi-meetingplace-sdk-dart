import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

/// Compile-time exhaustive switch over [ChatEvent].
///
/// If a new sealed subtype is added without a corresponding case, this file
/// will fail to compile — which is the test. Each case also returns the
/// concrete type name, exercised below.
String _describe(ChatEvent event) => switch (event) {
  ChatMessageEvent() => 'ChatMessageEvent',
  ChatMessageUpdatedEvent() => 'ChatMessageUpdatedEvent',
  ChatMessageDeliveredEvent() => 'ChatMessageDeliveredEvent',
  ChatPresenceEvent() => 'ChatPresenceEvent',
  ChatActivityEvent() => 'ChatActivityEvent',
  ChatEffectEvent() => 'ChatEffectEvent',
  ChatContactDetailsUpdateEvent() => 'ChatContactDetailsUpdateEvent',
  ChatProfileRequestEvent() => 'ChatProfileRequestEvent',
  ChatProfileHashEvent() => 'ChatProfileHashEvent',
  ChatGroupDeletedEvent() => 'ChatGroupDeletedEvent',
  ChatGroupDetailsUpdateEvent() => 'ChatGroupDetailsUpdateEvent',
  ChatMemberDeregisteredEvent() => 'ChatMemberDeregisteredEvent',
  ChatRequestIssuanceEvent() => 'ChatRequestIssuanceEvent',
  ChatIssuedCredentialEvent() => 'ChatIssuedCredentialEvent',
  UnhandledChatEvent() => 'UnhandledChatEvent',
};

void main() {
  test('exhaustive switch covers every ChatEvent subtype', () {
    final contactCard = ContactCard(
      did: 'did:test:alice',
      type: 'human',
      contactInfo: const {'n': 'Alice'},
    );
    final now = DateTime.utc(2026, 1, 1);

    final events = <ChatEvent>[
      const ChatMessageEvent(),
      const ChatMessageUpdatedEvent(),
      const ChatMessageDeliveredEvent(messageIds: ['m1']),
      ChatPresenceEvent(timestamp: now),
      ChatActivityEvent(
        senderDid: 'did:test:alice',
        timestamp: now,
        createdTime: now,
      ),
      const ChatEffectEvent(effectName: 'confetti'),
      ChatContactDetailsUpdateEvent(
        senderDid: 'did:test:alice',
        contactCard: contactCard,
      ),
      const ChatProfileRequestEvent(
        senderDid: 'did:test:bob',
        profileHash: 'abc123',
      ),
      const ChatProfileHashEvent(
        senderDid: 'did:test:bob',
        profileHash: 'def456',
      ),
      const ChatGroupDeletedEvent(groupDid: 'did:test:group'),
      const ChatGroupDetailsUpdateEvent(),
      const ChatMemberDeregisteredEvent(
        groupDid: 'did:test:group',
        memberDid: 'did:test:bob',
      ),
      ChatRequestIssuanceEvent(
        senderDid: 'did:test:alice',
        body: const {},
        createdTime: now,
        attachments: const [],
      ),
      ChatIssuedCredentialEvent(
        senderDid: 'did:test:alice',
        body: const {},
        createdTime: now,
        attachments: const [],
      ),
      const UnhandledChatEvent(type: 'unknown'),
    ];

    final names = events.map(_describe).toList();
    expect(names.toSet().length, events.length);
  });
}

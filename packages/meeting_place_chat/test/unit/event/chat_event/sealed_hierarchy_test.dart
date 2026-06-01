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
  ChatPresenceEvent() => 'ChatPresenceEvent',
  ChatActivityEvent() => 'ChatActivityEvent',
  ChatEffectEvent() => 'ChatEffectEvent',
  ChatContactDetailsUpdateEvent() => 'ChatContactDetailsUpdateEvent',
  ChatGroupDeletedEvent() => 'ChatGroupDeletedEvent',
  ChatGroupDetailsUpdateEvent() => 'ChatGroupDetailsUpdateEvent',
  ChatMemberDeregisteredEvent() => 'ChatMemberDeregisteredEvent',
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
      const ChatGroupDeletedEvent(groupDid: 'did:test:group'),
      const ChatGroupDetailsUpdateEvent(),
      const ChatMemberDeregisteredEvent(
        groupDid: 'did:test:group',
        memberDid: 'did:test:bob',
      ),
      const UnhandledChatEvent(type: 'unknown'),
    ];

    final names = events.map(_describe).toList();
    expect(names.toSet().length, events.length);
  });
}

# Listening to a chat

Once you have a `MeetingPlaceChatSDK` for a channel, everything that happens
in that chat — incoming messages, the peer typing, a group member leaving,
your own outbound send getting persisted — surfaces on a single stream.
This document walks through how to consume it.

## Getting the stream

```dart
final stream = await chatSDK.chatStreamSubscription;
stream?.listen((data) { /* handle data */ });
```

The subscription is `null` until the chat session has been started with
`startChatSession()`. After that it stays alive until you call
`endChatSession()`.

## What's on the stream

Each emission is a `StreamData` with two optional fields:

- **`event`** — a typed `ChatEvent` describing _what happened_ (a message
  arrived, the peer is typing, the group was deleted, …).
- **`chatItem`** — a row that was written to chat history (a message, a
  system notice like "Bob joined", a concierge message awaiting your
  approval).

Both are nullable, and the four combinations all occur in practice:

| `event`     | `chatItem` | Example                                                        |
| ----------- | ---------- | -------------------------------------------------------------- |
| set         | set        | New chat message: an event tells you what happened, the item holds the payload. |
| set         | `null`     | Pure signal: peer typing, peer online, visual effect.          |
| `null`      | set        | History row that doesn't have a dedicated event yet — concierge messages, reactions, redactions, "member joined" notices. Display it as-is from `chatItem.type`. |
| `null`      | `null`     | Doesn't happen; treat as a no-op if you ever see one.          |

The `null`/`set` row above is a known rough edge — over time those paths
should grow dedicated `ChatEvent` subtypes so consumers don't have to look
inside `chatItem` to discriminate. For now, fall through to `chatItem.type`
when `event` is `null`.

## `ChatEvent` is sealed — write an exhaustive switch

`ChatEvent` is a `sealed` Dart type. That means the compiler knows every
possible subtype, and a `switch` expression over it must cover them all.
When the SDK adds a new event in a future release, your switch becomes a
compile error until you handle it — so you find out about new capabilities
at build time, not because users notice something missing.

```dart
final stream = await chatSDK.chatStreamSubscription;
stream?.listen((data) {
  switch (data.event) {
    case ChatMessageEvent():
      // A chat message was just delivered — payload is in data.chatItem.

    case ChatEffectEvent(:final effectName):
      // A visual effect (e.g. "confetti") was sent. No chat item; just
      // animate the effect.

    case ChatContactDetailsUpdateEvent(:final senderDid, :final contactCard):
      // The peer (or a group member) edited their card. Refresh their
      // name/avatar wherever you display them.

    case ChatGroupDeletedEvent(:final groupDid):
      // The group is gone. Close the chat screen and drop the entry from
      // your contact list.

    case ChatGroupDetailsUpdateEvent():
      // Group details (e.g. membership list) changed. Re-fetch the group
      // via coreSDK.getGroup() if you need the latest state.

    case ChatMemberDeregisteredEvent(:final groupDid, :final memberDid):
      // A specific member left. A "member left" system row also arrives
      // as data.chatItem; render it in the conversation.

    case ChatPresenceEvent(:final timestamp):
      // The peer signalled they are online at `timestamp`. Treat as stale
      // after ~60s.

    case ChatActivityEvent(:final senderDid, :final timestamp):
      // The peer is typing. Show a "typing…" indicator for a few seconds
      // after `timestamp`.

    case UnhandledChatEvent(:final type, :final body):
      // The SDK received a protocol message it doesn't have a typed
      // event for yet. Safe to ignore in release; log it in dev.

    case null:
      // The data only carries a chatItem — handle it via chatItem.type.
  }
});
```

## Event reference

| Event                            | Fires when…                                                      | `chatItem`             |
| -------------------------------- | ---------------------------------------------------------------- | ---------------------- |
| `ChatMessageEvent`               | A chat message is received or one of your sends is persisted.    | yes (the message)      |
| `ChatEffectEvent`                | A visual effect is triggered.                                    | no                     |
| `ChatContactDetailsUpdateEvent`  | A contact card was updated.                                      | no                     |
| `ChatGroupDeletedEvent`          | The group is deleted.                                            | sometimes (system row) |
| `ChatGroupDetailsUpdateEvent`    | Group details (e.g. membership list) changed.                    | sometimes (per member) |
| `ChatMemberDeregisteredEvent`    | A member leaves the group.                                       | yes (system row)       |
| `ChatPresenceEvent`              | The peer is online.                                              | no                     |
| `ChatActivityEvent`              | The peer is typing.                                              | no                     |
| `UnhandledChatEvent`             | The SDK received an event it doesn't yet model as a typed event. | no                     |

## Cleaning up

Cancel your listener when the chat screen is torn down, and call
`endChatSession()` to release the underlying subscription:

```dart
await mySubscription?.cancel();
chatSDK.endChatSession();
```

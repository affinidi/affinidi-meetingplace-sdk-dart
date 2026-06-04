# `lib/src/` Architecture

This document explains the layout of `meeting_place_chat`'s internal source
tree and the reasoning behind it. Public API is unchanged — this is purely
about how the code is organised inside `lib/src/`.

## Layout

```
lib/
  meeting_place_chat.dart            — public barrel (the package's API surface)
  src/
    constants.dart                   — package-wide constants
    meeting_place_chat_sdk.dart      — public interface + factory
                                       (MeetingPlaceChatSDK.initialiseFromChannel)
    meeting_place_chat_sdk_options.dart            — public configuration

    chat/                            — ChatSDK implementations
      chat.dart                      — barrel for the three concrete SDKs
      base_chat_sdk.dart             — transport-neutral abstract base
      matrix_chat_sdk.dart           — MatrixChatSDK: intermediate base that
                                       owns Matrix room subscription, outgoing
                                       events, server↔message id maps
      group/                         — GroupMatrixChatSDK + event handlers,
                                       actions, listeners, factories,
                                       group_room_event_router
      individual/                    — IndividualMatrixChatSDK,
                                       IndividualDidcommChatSDK

    entity/                          — domain models
      chat.dart, message.dart, event_message.dart, chat_attachment.dart, …

    event/                           — events and their delivery
      chat_event.dart                — sealed event hierarchy
      chat_event/                    — concrete event variants
      chat_event_conversion.dart     — transport → domain conversion
      chat_event_handler.dart        — transport-neutral handler interface
      chat_event_types.dart          — neutral dispatch keys (memberJoined, memberLeft)
      incoming_chat_event.dart       — transport-neutral incoming event
      stream_data.dart               — event/item union
      chat_stream.dart               — broadcast stream that emits StreamData

    transport/                       — protocol adapters
      matrix/                        — Matrix transport (outgoing/, incoming/)
      didcomm/                       — DIDComm transport (outgoing/, protocol/, chat_protocol.dart)

    repository/                      — persistence interface (ChatRepository)

    logger/                          — logging primitives and formatters
```

## Why this shape

The structure separates three things that change for different reasons: the
**public API contract**, the **domain** the package talks about, and the
**transports** it uses to deliver that domain. Layering by reason-to-change
keeps each folder small, scannable, and meaningful on its own.

### Top-level files are the public API contract

`meeting_place_chat_sdk.dart` and `meeting_place_chat_sdk_options.dart` sit directly
under `lib/src/` (not in a subfolder) because they are the package's
entry points: the public `abstract interface class MeetingPlaceChatSDK`
(and its `initialiseFromChannel` factory), plus its configuration.
Co-locating them at the top makes the surface obvious — readers see what
the package *offers* before how it *works*.

### `chat/` holds the implementations of `MeetingPlaceChatSDK`

The hierarchy has two levels. `BaseChatSDK` is the transport-neutral
abstract base — chat-session lifecycle, the broadcast `ChatStream`, and
the operations that don't depend on Matrix or DIDComm specifics. On top
of that, `MatrixChatSDK` is an intermediate abstract subclass that owns
everything Matrix-flavoured (room subscription, server↔message id maps,
outgoing room events).

Three concrete SDKs sit at the leaves:

- `GroupMatrixChatSDK` (groups always use Matrix)
- `IndividualMatrixChatSDK`
- `IndividualDidcommChatSDK` (extends `BaseChatSDK` directly — no Matrix
  state)

`MeetingPlaceChatSDK.initialiseFromChannel` picks one based on the
channel: groups go to Matrix; individual channels dispatch on
`Channel.transport`. The singular folder name parallels `entity/`,
`event/`, `transport/`, `repository/` — every internal folder names one
concept.

### `entity/` is the domain vocabulary

Plain data models: `Chat`, `Message`, `ChatAttachment`, `ConciergeMessage`,
`Effect`, etc. No behavior beyond construction and small derivations
(e.g. `Chat.deriveId`). These types appear in the public API, so they need
a stable home that is independent of how messages are transported or
persisted.

### `event/` covers events and their delivery

A chat is a stream of events. This folder groups the things that make event
delivery work:

1. **Event types** — `ChatEvent` (sealed) and its variants in
   `chat_event/`. `StreamData` unions an event with its persisted item.
2. **Conversion** — `chat_event_conversion.dart` maps transport-level
   messages (DIDComm `PlainTextMessage`, Matrix room events) into
   domain-level `ChatEvent`s.
3. **Stream** — `ChatStream` is the broadcast stream consumers subscribe
   to. It belongs with the types it carries.
4. **Transport-neutral handler contract** —
   `IncomingChatEvent { type, senderDid, content }` is the shape
   transport adapters produce for chat-level handlers to consume. It
   carries only inbound input; handlers that also need a `ChatEvent` to
   push onto the stream call the `IncomingChatEvent.toChatEvent()`
   extension at the point of use. `ChatEventHandler` is the interface
   those handlers implement, and `ChatEventTypes` defines neutral
   dispatch keys (`memberJoined`, `memberLeft`) for structural events
   that aren't named by an application-level protocol.

Keeping conversion and the neutral handler contract next to the event
types means the rule "how does a transport message become a domain event"
lives in one place.

### `chat/group/event_handler/` is transport-neutral

The group event handlers (`MemberJoinedHandler`, `MemberDeregisteredHandler`,
`GroupDeletionHandler`, `GroupDetailsUpdateHandler`,
`ContactDetailsUpdateHandler`) implement `ChatEventHandler` and consume
`IncomingChatEvent`. They do not import from `transport/matrix/` — the
sender DID is pre-resolved by the transport adapter, and the payload is
delivered as a plain `Map`. This is what lets `chat/` stay generic even
though Matrix is currently the only transport that drives incoming
events.

### `transport/` is the swap point

`transport/matrix/` and `transport/didcomm/` are protocol adapters.
Putting them under a common parent communicates that they are *alternative
transports*, not parallel domain concepts. If a third protocol is added,
it gets a sibling folder here and nothing in `chat/`, `entity/`, `event/`,
or `repository/` needs to know.

Each transport folder follows the same `outgoing/` + `incoming/` split,
which mirrors the direction data flows: outbound messages the SDK
produces vs inbound events it consumes.

Sender DIDs on inbound Matrix events are pre-resolved by
`meeting_place_core`'s `MessagingService` (which hashes each channel
candidate DID with `deriveMatrixUserId` and matches against
`event.userId`). The chat package never sees the Matrix user-id → DID
problem, and there is no local cache to invalidate.

The Matrix router (`transport/matrix/incoming/incoming_room_event_router.dart`)
maintains **two parallel dispatch tables**:

- **Matrix-coupled handlers** for events whose handling is inherently
  transport-specific — receipts, reactions, redactions, typing, text
  messages. These live in `transport/matrix/incoming/` and consume
  `MatrixRoomEvent` directly. The router holds them as a
  `Map<String, MatrixRoomEventHandler>` (a `Future<void> Function(MatrixRoomEvent)`
  typedef) populated with method tear-offs — no shared interface,
  because the only thing they have in common is the function shape.
- **Transport-neutral handlers** (`ChatEventHandler`s) for application-
  level chat events. The router resolves the sender DID, converts the
  payload, and dispatches an `IncomingChatEvent`. Matrix's `RoomMember`
  events are translated into `ChatEventTypes.memberJoined` or
  `ChatEventTypes.memberLeft` based on the `membership` field; protocol-
  typed events pass through with their protocol string as the key.

### `repository/` and `loggers/` are infrastructure interfaces

Small, focused folders for cross-cutting concerns the SDK depends on
through interfaces. Consumers provide their own implementations.

## Layering rules

Dependencies flow inward, from outer concerns to the core domain:

```
chat/ ──► event/, entity/, transport/, repository/, loggers/
transport/ ──► event/, entity/
event/ ──► entity/
entity/ ──► (no internal deps)
```

- `entity/` depends on nothing internal — it's the stable core.
- `event/` may reference `entity/` (e.g. `ChatItem` in `StreamData`).
- `transport/` may produce/consume `event/` and `entity/` types via the
  conversion layer, but does not know about `chat/`.
- `chat/` orchestrates everything: it wires transports to the stream,
  persists via the repository, and surfaces events to consumers.

This direction keeps the domain free of transport details and lets a new
transport be added without touching `chat/` or `entity/`.

## What we deliberately do not have

- **No `utils/` folder.** Generic helpers tend to attract unrelated code.
  When a helper has a clear home (e.g. a logging-only string extension
  lives in `logger/`, a chat-id derivation lives on `Chat`), it goes
  there instead.
- **No `sdk/` folder.** "SDK" describes the whole package, not a layer
  inside it. Files that previously lived there were dispersed to their
  proper homes: the public interface and options sit at top level, the
  abstract bases live next to their subclasses in `chat/`, and the
  `Chat` domain type lives in `entity/`.
- **No standalone `ChatSDK` interface file.** `MeetingPlaceChatSDK` is
  itself an `abstract interface class`, so the public contract and its
  factory live in one file at the top level.
- **No Matrix user-id cache in `transport/matrix/`.** Resolving a
  Matrix `@hash:host` user-id back to a DID is now done in core
  (`MessagingService._resolveSenderDid`), per-event, by hashing the
  channel's candidate DIDs and matching. No invalidation lifecycle,
  membership changes are picked up automatically on the next event.
- **No `stream/` folder.** `ChatStream` is part of the event-delivery
  story and lives in `event/` alongside what it carries.
- **No `ChatHistoryService`.** Construction of structural event messages
  (member joined/left, awaiting member, group deleted) lives on
  `EventMessage` as named constructors (`EventMessage.groupMemberJoined`,
  `EventMessage.groupMemberLeft`, `EventMessage.awaitingGroupMember`,
  `EventMessage.groupDeleted`). Callers persist via
  `chatRepository.createMessage(...)`. Entities own their construction;
  no thin service wrapper.
- **No `room_event_handler/` under `chat/`.** The Matrix-flavoured name
  was the symptom — the underlying problem was that those handlers
  imported from `transport/matrix/`. They are now `event_handler/` and
  consume the transport-neutral `IncomingChatEvent`.

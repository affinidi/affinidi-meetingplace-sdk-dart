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
    meeting_place_chat_sdk.dart      — public facade (MeetingPlaceChatSDK)
    chat_sdk.dart                    — public ChatSDK interface
    chat_sdk_options.dart            — public configuration

    chat/                            — ChatSDK implementations
      base_chat_sdk.dart             — abstract base class
      group/                         — GroupChatSDK + handlers, actions, listeners, factories, chat_history_service
      individual/                    — IndividualChatSDK

    entity/                          — domain models
      chat.dart, message.dart, chat_attachment.dart, …

    event/                           — events and their delivery
      chat_event.dart                — sealed event hierarchy
      chat_event/                    — concrete event variants
      chat_event_conversion.dart     — transport → domain conversion
      stream_data.dart               — event/item union
      chat_stream.dart               — broadcast stream that emits StreamData

    transport/                       — protocol adapters
      matrix/                        — Matrix transport (outgoing/, incoming/, cache)
      didcomm/                       — DIDComm transport (outgoing/, protocol/, chat_protocol.dart)

    repository/                      — persistence interface (ChatRepository)

    loggers/                         — logging primitives and formatters
```

## Why this shape

The structure separates three things that change for different reasons: the
**public API contract**, the **domain** the package talks about, and the
**transports** it uses to deliver that domain. Layering by reason-to-change
keeps each folder small, scannable, and meaningful on its own.

### Top-level files are the public API contract

`meeting_place_chat_sdk.dart`, `chat_sdk.dart`, and `chat_sdk_options.dart`
sit directly under `lib/src/` (not in a subfolder) because they are the
package's entry points: the interface, its configuration, and the facade
that implements the interface and delegates to a concrete `ChatSDK`.
Co-locating them at the top makes the surface obvious — readers see what
the package *offers* before how it *works*.

### `chat/` holds the implementations of `chat_sdk.dart`

`MeetingPlaceChatSDK` selects between `GroupChatSDK` and `IndividualChatSDK`
at construction time, both of which extend `BaseChatSDK`. They are
alternative implementations of the same contract, so they live together.
The singular folder name parallels `entity/`, `event/`, `transport/`,
`repository/` — every internal folder names one concept.

### `entity/` is the domain vocabulary

Plain data models: `Chat`, `Message`, `ChatAttachment`, `ConciergeMessage`,
`Effect`, etc. No behavior beyond construction and small derivations
(e.g. `Chat.deriveId`). These types appear in the public API, so they need
a stable home that is independent of how messages are transported or
persisted.

### `event/` covers events and their delivery

A chat is a stream of events. This folder groups the three things that
make event delivery work:

1. **Event types** — `ChatEvent` (sealed) and its variants in
   `chat_event/`. `StreamData` unions an event with its persisted item.
2. **Conversion** — `chat_event_conversion.dart` maps transport-level
   messages (DIDComm `PlainTextMessage`, Matrix room events) into
   domain-level `ChatEvent`s.
3. **Stream** — `ChatStream` is the broadcast stream consumers subscribe
   to. It belongs with the types it carries.

Keeping conversion next to the event types means the rule "how does a
transport message become a domain event" lives in one place.

### `transport/` is the swap point

`transport/matrix/` and `transport/didcomm/` are protocol adapters.
Putting them under a common parent communicates that they are *alternative
transports*, not parallel domain concepts. If a third protocol is added,
it gets a sibling folder here and nothing in `chat/`, `entity/`, `event/`,
or `repository/` needs to know.

Each transport folder follows the same `outgoing/` + `incoming/` split,
which mirrors the direction data flows: outbound messages the SDK
produces vs inbound events it consumes.

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
  lives in `loggers/`, a chat-id derivation lives on `Chat`), it goes
  there instead.
- **No `sdk/` folder.** "SDK" describes the whole package, not a layer
  inside it. Files that previously lived there were dispersed to their
  proper homes: the interface and options sit at top level, the abstract
  base lives next to its subclasses in `chat/`, and the `Chat` domain
  type lives in `entity/`.
- **No `stream/` folder.** `ChatStream` is part of the event-delivery
  story and lives in `event/` alongside what it carries.

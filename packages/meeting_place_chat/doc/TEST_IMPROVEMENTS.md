# Test improvement analysis — `meeting_place_chat`

## Context

The chat SDK currently has ~1,278 lines of integration tests and ~2 trivial unit tests. Every integration test boots a live Matrix homeserver, a live mediator, and a live control plane, and runs against real DIDs + cryptography. That makes the suite slow, flaky in CI without secrets, and unusable offline. It also means most behavior (event dispatch, conversion, handler logic) is exercised only as a side-effect of end-to-end flows, and only on happy paths. The SDK splits cleanly into seams that are easy to test in isolation, so the highest-leverage move is to introduce a layer of fast unit tests beneath the existing integration suite — not to write more integration tests.

## Current state — summary

- **No mocking framework**. Tests use hand-rolled in-memory repositories (`test/utils/repository/*.dart`) and live external services.
- **No unit tests for handlers**: `GroupDetailsUpdateHandler`, `GroupDeletionHandler`, `MemberDeregisteredHandler`, `MemberJoinedHandler`, `ContactDetailsUpdateHandler`, plus every Matrix incoming handler (`TextMessageHandler`, `ReactionHandler`, `ReceiptHandler`, `RedactionHandler`, `TypingHandler`, `ChatEffectHandler`).
- **No tests for outgoing message classes** (Matrix `*RoomEvent`, DIDComm `*Message`) — the `type` constants and `content` shapes recently changed to `com.affinidi.chat.*` have no regression coverage.
- **No tests for routers / conversion**: `IncomingRoomEventRouter._translate`, `GroupRoomEventRouter`, `chat_event_conversion.dart`.
- **No tests for `ChatEvent` subtypes** as a sealed hierarchy (exhaustive-switch contract).
- **Integration tests inspect internal state** to assert behavior — e.g. casting `UnhandledChatEvent.body['messages']` (`individual_chat_delivery_test.dart:53`).
- **Brittle setup**: `GroupChatFixture.create()` is ~130 lines and serially orchestrates 3 SDKs + connection approval.
- **External-only**: tests fail without `MATRIX_HOMESERVER`, `MEDIATOR_DID`, `CONTROL_PLANE_DID` (`test/utils/sdk.dart:20-25`).
- **Stale references**: `individual_chat_profile_sync_test.dart:129,207` calls a removed `proposeProfileUpdate` method — currently a hard analyzer error.

## Recommendations, ranked by leverage

### 1. Establish a `test/unit/` layer that mirrors `lib/src/`

The existing folder `test/unit/entity/` shows the intent. Extend it so every directory under `lib/src/` has a sibling under `test/unit/`. This is purely additive — integration tests stay.

Target unit-test files (priority order):

- `test/unit/transport/matrix/incoming/incoming_room_event_router_test.dart` — verify every branch of `_translate`, including the `com.affinidi.chat.*` literals and the fallthrough. This is the single most valuable file: it locks down the wire format.
- `test/unit/transport/matrix/outgoing/*_room_event_test.dart` — one file per outgoing class, asserting `type` and `content` payload shape. Plain constructor tests, no IO.
- `test/unit/event/chat_event_conversion_test.dart` — cover the `MatrixRoomEvent`, `IncomingChatEvent`, `MatrixOutgoingMessage` extensions; assert what falls back to `ChatMessageEvent` and what doesn't.
- `test/unit/chat/group/event_handler/*_handler_test.dart` — one file per handler. Inject fakes for `ChatRepository`, `ChatStream`, `MeetingPlaceCoreSDK`; assert the handler emits the right `ChatEvent`, persists the right `ChatItem`, calls `coreSDK.updateGroup` exactly once, etc.
- `test/unit/event/chat_event/sealed_hierarchy_test.dart` — a single test that exhaustively switches over `ChatEvent` and would fail to compile if a new subtype is added without coverage. Cheap, catches a real failure mode.

### 2. Adopt `mocktail`

Hand-rolled in-memory repos are fine for integration tests but heavy for unit tests of a single handler. `mocktail` (null-safe, no codegen) is the right fit — `mockito` would force build_runner into the workflow. Use it only for the unit layer; integration tests keep their in-memory repos.

### 3. Extract a `ChatTestHarness` to replace ad-hoc Completer loops

Several integration tests reimplement the same shape: subscribe → Completer → push → await → assert (e.g. `individual_chat_delivery_test.dart:24-65`). Lift this into `test/utils/chat_test_harness.dart` with helpers like `Future<T> awaitEvent<T extends ChatEvent>(ChatSDK sdk)` and `Future<ChatItem> awaitItem(...)`. Cuts setup, removes timeout duplication, and stops the trend of reading private payload shapes.

### 4. Stop asserting on `UnhandledChatEvent.body['…']`

`individual_chat_delivery_test.dart:53` and similar sites assert against the raw DIDComm/Matrix payload because the typed event didn't exist yet. Now that we have typed events for every meaningful case, integration tests should `switch (event)` on the sealed type and assert on the typed fields. Tests stop breaking when the wire format changes, and any future event lacking a typed subclass becomes visible as a test gap.

### 5. Make integration tests opt-in, not the default

Move `test/integration/*` behind a `@Tags(['live'])` annotation and configure `dart test --tags live` for CI / `dart test --exclude-tags live` for local. Then the unit layer (fast, deterministic, no env vars) is what runs by default — the integration layer remains the safety net.

### 6. Fix the stale references

`individual_chat_profile_sync_test.dart:129,207` references the removed `proposeProfileUpdate`. Either restore the method (if the feature should exist) or delete the test. Currently the suite cannot pass `dart analyze`.

### 7. Add error-path coverage to the new unit tests

While writing handler tests, also cover:
- Handler exception → does the stream stay alive?
- Unknown `event.type` → routes to `UnhandledChatEvent`?
- Out-of-order events (e.g. member-joined for a group that was just deleted)?
- Idempotency: re-delivering the same event id (Matrix sync replay) doesn't double-emit?

These are all cheap in the unit layer and would catch the kind of bugs integration tests only find by accident.

## Critical files (for execution, if approved)

- New: `test/unit/transport/matrix/incoming/incoming_room_event_router_test.dart`
- New: `test/unit/transport/matrix/outgoing/*_test.dart` (5 files matching `lib/src/transport/matrix/outgoing/`)
- New: `test/unit/chat/group/event_handler/*_test.dart` (5 handler files)
- New: `test/unit/event/chat_event_conversion_test.dart`
- New: `test/utils/chat_test_harness.dart`
- Modify: `test/integration/*` — add `@Tags(['live'])`, switch payload inspection to typed-event switching
- Modify: `pubspec.yaml` (dev_dependencies) — add `mocktail`
- Modify: `.github/workflows/check.yaml` — run `dart test --exclude-tags live` by default, `--tags live` in a separate job that needs the secrets
- Delete or restore: `proposeProfileUpdate` references in `individual_chat_profile_sync_test.dart`

## Verification

1. `dart analyze packages/meeting_place_chat` is clean (today it isn't — `proposeProfileUpdate` errors).
2. `cd packages/meeting_place_chat && dart test --exclude-tags live` runs in <5 s with no env vars set, all green.
3. `dart test --tags live` (with env vars) still runs the original integration suite green.
4. Coverage delta: every file under `lib/src/transport/matrix/outgoing/`, `lib/src/transport/matrix/incoming/`, `lib/src/chat/group/event_handler/`, and `lib/src/event/chat_event/` has at least one direct test file.
5. The router test fails if anyone changes `com.affinidi.chat.*` without updating both sides.

## Out of scope

- Rewriting integration tests to avoid real Matrix/mediator — they should keep doing what they do.
- Adding code-coverage tooling / gating — separate concern.
- Testing `meeting_place_core` or `meeting_place_control_plane` — this analysis is scoped to `meeting_place_chat`.

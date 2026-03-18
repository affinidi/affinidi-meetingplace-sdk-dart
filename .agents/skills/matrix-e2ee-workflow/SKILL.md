---
name: matrix-e2ee-workflow
description: "Use when enabling, debugging, testing, or reviewing Matrix end-to-end encryption (E2EE), Megolm room encryption, Vodozemac initialization, encrypted room creation, encrypted message sending, or decrypted-event verification in the Meeting Place SDK and reference app. Keywords: Matrix, E2EE, encryption, Megolm, Vodozemac, encrypted room, m.room.encrypted, integration test, decrypt, reference app."
---

# Matrix E2EE Workflow

## Purpose

Use this skill for Matrix encryption work in the Meeting Place codebase, especially when tasks involve:

- enabling Matrix E2EE for SDK or app flows
- verifying that group messages are actually sent as `m.room.encrypted`
- confirming decrypted events still resolve to the original plaintext body
- wiring `vodozemac` or `flutter_vodozemac`
- building or fixing integration tests around Matrix encryption

This repo has two relevant codebases in the same workspace:

- SDK repo: `affinidi-meetingplace-sdk-dart`
- App repo: `affinidi-meetingplace-reference-app`

## Repository Conventions

### SDK-side Matrix rules

In `meeting_place_core`, Matrix encryption must be handled through the Matrix room APIs, not raw client send APIs.

Preferred patterns:

- create encrypted rooms with `Client.createGroupChat(enableEncryption: true, waitForSync: true)`
- send text through `Room.sendTextEvent(...)`
- require `matrixClient.encryptionEnabled` before encrypted room creation or encrypted sending
- wait for room visibility in sync state before using it

Avoid:

- manually treating a room as encrypted only by inserting `m.room.encryption` state without ensuring crypto is initialized
- calling raw `client.sendMessage(...)` for encrypted room messaging

### App-side Matrix rules

The reference app initializes Matrix crypto through Flutter native bindings:

- use `flutter_vodozemac` in the app
- initialize with `await vod.init()` before using Matrix login/session flows

### Pure Dart test rules

Pure Dart integration tests do not get Flutter-native loading behavior automatically.

For SDK integration tests:

- use `package:vodozemac/vodozemac.dart`
- require `VODOZEMAC_LIBRARY_PATH` for native library loading when crypto is enabled in tests
- skip Matrix-encryption integration tests if the native library path is not configured
- keep non-Matrix tests independent from native crypto setup

## Known Working Locations

Primary files involved in this workflow:

- `packages/meeting_place_core/lib/src/service/matrix/matrix_service.dart`
- `packages/meeting_place_core/test/integration/group/group_matrix_encryption_test.dart`
- `packages/meeting_place_core/test/utils/sdk.dart`
- `packages/meeting_place_core/test/integration/utils/group_chat_fixture.dart`
- `packages/meeting_place_core/example/utils/sdk.dart`
- `app/lib/infrastructure/providers/meeting_place_sdk_provider.dart` in the reference app repo

## Standard Workflow

### 1. Inspect the current integration points

Check these first:

- where the Matrix client is created
- where `vod.init()` or `flutter_vodozemac.init()` is called
- how rooms are created
- how messages are sent
- whether tests are asserting only delivery or also encrypted payload shape

### 2. Verify crypto initialization path

For Flutter app work:

- confirm `await vod.init()` runs before `MeetingPlaceCoreSDK.create(...)`

For SDK examples or pure Dart tests:

- confirm `await vod.init(libraryPath: ...)` is called when encryption runtime is required
- confirm missing native library configuration causes a skip or an explicit error, not a false-positive pass

### 3. Verify encrypted room creation

A valid encrypted group flow should:

- create the room with encryption enabled through the Matrix SDK room helper
- not rely only on manual room state injection
- ensure the room is present in sync before sending or joining-dependent assertions

### 4. Verify encrypted message sending

A valid encrypted message flow should:

- send via `Room.sendTextEvent(...)`
- not use raw client send APIs for room messages
- assert that the received event came from `m.room.encrypted`

### 5. Verify decryption in tests

A strong Matrix E2EE integration test should assert both:

- raw encrypted source properties
- decrypted event properties

Expected encrypted-source assertions:

- `originalSource.type == m.room.encrypted`
- `originalSource.content['algorithm'] == 'm.megolm.v1.aes-sha2'`
- `ciphertext` exists and is non-empty
- `session_id` exists and is non-empty
- `sender_key` exists and is non-empty
- encrypted payload does not expose plaintext `body`

Expected decrypted-event assertions:

- event type resolves to `m.room.message`
- decrypted `body` matches the sent message
- decrypted `msgtype` is `m.text`

## Test Execution Guidance

Prefer targeted runs:

- Matrix service unit test
- Matrix encryption integration test only

If the integration test is skipped, report why explicitly.

Typical reason:

- `VODOZEMAC_LIBRARY_PATH` is not configured for pure Dart execution

## Good Outcome Criteria

The work is complete when:

- encrypted group rooms are created through Matrix’s encryption-aware API
- messages are sent through room APIs that produce encrypted events
- the app initializes native crypto correctly
- pure Dart tests either run with a configured native library or skip cleanly
- integration tests verify both encrypted wire payload and decrypted message body

## Anti-patterns

Do not:

- claim E2EE is enabled just because a room has encryption state
- treat successful plaintext delivery as proof of encryption
- make all SDK tests depend on native crypto initialization
- hide environment prerequisites for Vodozemac in tests

## Suggested Prompt Triggers

This skill should activate for prompts like:

- "enable Matrix encryption"
- "verify Matrix E2EE"
- "check if message is really encrypted"
- "fix Vodozemac setup"
- "add Matrix encryption integration test"
- "debug m.room.encrypted vs m.room.message"

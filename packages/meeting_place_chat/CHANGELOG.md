## 0.0.1-dev.53

 - Update a dependency to the latest release.

## 0.0.1-dev.52

 - **FIX**: surface busy auto-reject on cancelled-call stream (#275).

## 0.0.1-dev.51

 - **FIX**: remove duplicate changelog headings for package releases (#274).

### Breaking Changes

- `meeting_place_chat` now supports DIDComm individual chats only. Matrix-backed chat implementations and group chat support have moved to `meeting_place_matrix`.

- `MeetingPlaceChatSDK.initialiseFromChannel(...)` has been replaced by synchronous `MeetingPlaceChatSDK.initialiseChatFromChannel(...)`.
 - Passing a group channel or a Matrix channel now throws `ArgumentError`.
 - Matrix consumers should initialize chat sessions from `meeting_place_matrix` instead.

### Added

- `MeetingPlaceChatSDK.updateMessage()` updates a persisted message and re-emits it on the chat stream so clients can refresh local UI state immediately.

- `ChatGroupDetailsUpdate` is now re-exported from `package:meeting_place_chat/meeting_place_chat.dart`.

- `TransportCapabilities.audioVideoCalling` indicates whether the transport supports audio and video calls.

## 0.0.1-dev.50

 - **FIX**: persist attachment IDs (#256).

## 0.0.1-dev.49

 - **FIX**: split media capabilities into images and videos (#254).

## 0.0.1-dev.48

 - **FIX**: handle sync markers correctly (#246).

## 0.0.1-dev.47

 - **FIX**: apply incoming profile updates in individual Matrix chat (#247).

## 0.0.1-dev.46

 - **FIX**: add Matrix transport support alongside DIDComm.

### Breaking Changes

- **MeetingPlaceChatSDK** — Converted from a concrete wrapper class to an `abstract interface class`. Previously: a concrete class wrapping either `GroupChatSDK` or `IndividualChatSDK`. Now: an interface implemented by `GroupMatrixChatSDK`, `IndividualMatrixChatSDK`, and `IndividualDidcommChatSDK`.
  - Previously: `MeetingPlaceChatSDK(sdk: GroupChatSDK(...))`.
  - **Migration:** Use `MeetingPlaceChatSDK.initialiseFromChannel(channel, ...)` exclusively. The concrete SDK type is chosen automatically by `Channel.transport`.

- **ChatSDKOptions → MeetingPlaceChatSDKOptions** — Renamed configuration class.
  - Previously: `ChatSDKOptions`.
  - **Migration:** Replace all references to `ChatSDKOptions` with `MeetingPlaceChatSDKOptions`.

- **sendMessage() removed** — The `sendMessage(PlainTextMessage)` method was removed from the interface.
  - Previously: Sent raw DIDComm `PlainTextMessage` objects.
  - **Migration:** Use `sendTextMessage(String text, {List<ChatAttachment> attachments})` instead. Construct a `ChatAttachment` for any media payloads.

- **sendChatDeliveredMessage() signature** — Now accepts a `String messageId` instead of a `PlainTextMessage`.
  - Previously: `sendChatDeliveredMessage(PlainTextMessage message)`.
  - **Migration:** Pass the server event ID (String) directly.

- **fetchNewMessages() removed** — The manual fetch method is gone; delivery is now event-driven through the live subscription.
  - **Migration:** Subscribe to the `ChatStream` returned by `startChatSession()` and use `ChatTestHarness.awaitEvent<T>()` / `ChatTestHarness.awaitItem()` in tests.

- **Attachment → ChatAttachment** — The attachment type used in `sendTextMessage` and `createAttachmentMessage` changed.
  - Previously: `Attachment` (from DIDComm SDK).
  - **Migration:** Use `ChatAttachment` for all chat attachment operations. Convert existing DIDComm `Attachment` instances via `toChatAttachment()`.

- **endChatSession()** — Return type changed from `void` to `Future<void>`.
  - **Migration:** Await the call.

---

### Added

- **TransportCapabilities / ChatFeature** — Per-chat feature capability system. Query `chatSDK.capabilities.supports(ChatFeature.messageEdit)` to gate consumer actions by what the transport supports.

- **ChatFeature.documentAttachments** — New capability flag for Matrix-only document file support (PDF, archives, etc). DIDComm chats do not expose this.

- **sendCustomEvent()** — Transport-neutral escape hatch for sending arbitrary events to participants.

- **editTextMessage()** — Edit a previously sent text message (Matrix only, requires `ChatFeature.messageEdit`).

- **deleteMessage()** — Delete a message for all participants (within `deleteMessageWindow`) or hide locally.

- **downloadMedia()** — Download and decrypt hosted media from a `ChatAttachment`.

- **removeMember()** — Owner can remove a group member. Matrix kick + control-plane deregistration.

- **Message.editedAt** — Timestamp of last edit on a message.

- **Message.transportId** — Server-side event ID used to reference the message in the transport layer.

- **MessageReaction.senderDid** — Reactions now track per-user ownership so each user can independently toggle their own emoji.

- **VoiceMessageMetadata** — Structured metadata for voice-note attachments (duration, waveform).

- **TypingIndicatorManager** — Internal class that debounces typing indicator sends and auto-clears after expiry.

- **UnhandledChatEvent** — Events with no registered handler are surfaced on the stream instead of being silently dropped.

- **ChatEventTypes enum** — Canonical string constants for transport-neutral event types.

---

### Changed

- **MeetingPlaceChatSDK.initialiseFromChannel** — Now dispatches on `Channel.transport` to select the correct individual chat implementation (Matrix or DIDComm). Group channels always route to `GroupMatrixChatSDK`.

- **startChatSession()** — Returns immediately with persisted messages, auth, history replay, and delivery receipts run in the background.

- **Delivery receipts** — Now sent at the SDK level after history replay completes

---

### Fixed

- **startChatSession() race condition** — `transportSubscriptionFuture` is now set before the first await, fixing `chatStreamSubscription is null` errors when callers set up event listeners without awaiting the session.

- **Group member leave reason** — Leave events now include a reason field (voluntary vs kicked).

## 0.0.1-dev.45

 - **FIX**: add decline zkp request (#227).

## 0.0.1-dev.43

 - Update a dependency to the latest release.

## 0.0.1-dev.42

 - Update a dependency to the latest release.

## 0.0.1-dev.41

 - **FEAT**: add meeting_place_credentials package (#160).

## 0.0.1-dev.40

 - **FEAT**: add VRC/VDIP channel attachment support to meeting_place_core (#196).

## 0.0.1-dev.39

 - Update a dependency to the latest release.

## 0.0.1-dev.38

 - **FIX**: delete mediator messages individually after processing in fetchNewMessages (#178).

## 0.0.1-dev.37

 - Update a dependency to the latest release.

## 0.0.1-dev.36

 - **FIX**: stop ChatActivityEventHandler from deleting mediator messages (#177).

## 0.0.1-dev.35

 - Update a dependency to the latest release.

## 0.0.1-dev.34

 - **FEAT**: abstract concierge and event messages (#132).

## 0.0.1-dev.33

 - **REFACTOR**: extract ChatSDK message handlers into dedicated classes (#138).

## 0.0.1-dev.32

 - Update a dependency to the latest release.

## 0.0.1-dev.31

 - **FIX**: improvements and bug fixes (#131).

## 0.0.1-dev.30

 - **FIX**: quality improvements and resolution of minor bugs (#108).

## 0.0.1-dev.29

 - Update a dependency to the latest release.

## 0.0.1-dev.28

 - Update a dependency to the latest release.

## 0.0.1-dev.27

 - **FIX**: improve handling of transient network issues (#58).

## 0.0.1-dev.26

 - **FIX**: use timestamp from message body for improved accuracy.

## 0.0.1-dev.25

 - Update a dependency to the latest release.

## 0.0.1-dev.24

 - Update a dependency to the latest release.

## 0.0.1-dev.23

 - Update a dependency to the latest release.

## 0.0.1-dev.22

 - **FIX**: stop sending chat presence messages on error (#52).

## 0.0.1-dev.21

 - **FIX**: ephemeral usage and log DIDComm problem report details (#47).

## 0.0.1-dev.20

 - Update a dependency to the latest release.

## 0.0.1-dev.19

 - Update a dependency to the latest release.

## 0.0.1-dev.18

 - **FIX**: protocol alignment with standard; replace vCard by contactCard (#42).

## 0.0.1-dev.17

 - Update a dependency to the latest release.

## 0.0.1-dev.16

 - **FIX**: handle notification errors when sending messages (#32).

## 0.0.1-dev.15

 - Update a dependency to the latest release.

## 0.0.1-dev.14

 - **FIX**: get latest version of channel entity on ChatSDK before updating (#28).

## 0.0.1-dev.13

 - **FIX**: upgrade to DIDComm v2.3.0; handle message deletion in mediator SDK (#26).

## 0.0.1-dev.12

 - **FIX**: use latest ssi version v2.17.1 (#23).

## 0.0.1-dev.11

 - **FIX**: allow offer acceptance if existing offer is finalised or if channel is not inaugurated (#18).

## 0.0.1-dev.10

 - **FIX**: apply configured retry count and return network_error code in case of connection error (#16).

## 0.0.1-dev.9

 - Update a dependency to the latest release.

## 0.0.1-dev.8

 - **DOCS**: added Meeting Place banner per SDK (#15).
 - **DOCS**: updated readme and pubspec desc (#13).

## 0.0.1-dev.7

 - **FIX**: update group on Chat SDK instance handling message (#12).
 - **DOCS**: updated readme and pubspec desc (#13).

## 0.0.1-dev.6

 - **FEAT**: add retry logic to control plane event handlers to prevent race conditions (#9).

## 0.0.1-dev.5

 - **FIX**: connection flow issues and add matchesType for event type checkin (#8).

## 0.0.1-dev.4

 - **FIX**: ensure offer description is passed and required; clean up misleading log (#7).

## 0.0.1-dev.3

 - Update a dependency to the latest release.

## 0.0.1-dev.2

 - **FIX**: improve pub.dev score by resolving analysis issues and updating example links (#4).

## 0.0.1-dev.1

 - **FIX**: use proper dev version format (#3).

## 0.0.1-dev.0

 - **FEAT**: initial release

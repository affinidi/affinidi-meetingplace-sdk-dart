## 0.0.1-dev.42

 - **FIX**: handle sync markers correctly (#246).

## 0.0.1-dev.41

 - **FIX**: add Matrix transport support alongside DIDComm.

## 0.0.1-dev.41

### Breaking Changes

- **MeetingPlaceCoreSDK.create()** — `config` parameter — The `create()` factory now accepts a `Config` object (specifically `MatrixConfig`) instead of separate `mediatorDid` and `controlPlaneDid` string parameters. Passing a non-`MatrixConfig` config throws `UnsupportedError`.
    - Previously: `MeetingPlaceCoreSDK.create(mediatorDid: '...', controlPlaneDid: '...', ...)`.
    - Migration: Replace the two string parameters with a single Config, optionally using `MatrixConfig` to enable Matrix protocol

- **sendMessage() / queueMessage() / sendGroupMessage()** — Replaced by unified `sendMessage(OutgoingMessage)` returning the server event ID.
  - Previously: Separate methods for plain text, queued, and group messages.
  - **Migration:** Construct the appropriate `OutgoingMessage` subclass (e.g. `TextMessageRoomEvent`, `ChatTypingNotification`) and pass to the unified `sendMessage()`.

- **fetchMessages() / subscribeToMediator()** — Replaced by `subscribe(IncomingMessageSubscription)` and `fetchHistory(HistoryQuery)`.
  - Previously: `fetchMessages(did: ..., mediatorDid: ...)` and `subscribeToMediator(...)`.
  - **Migration:** Use `subscribe(MatrixRoomSubscription(...))` or `subscribe(DidCommSubscription(...))` for live streams. Use `fetchHistory(MatrixRoomHistoryQuery(...))` or `fetchHistory(DidCommHistoryQuery(...))` for paginated history.

- **ConnectionOffer.transport** — New required field on `ConnectionOffer`.
  - Previously: No transport field.
  - **Migration:** Provide `transport: ChannelTransport.didcomm` (or `.matrix`) when constructing `ConnectionOffer`. Existing offers in storage will need a migration.

---

### Added

- **ChannelTransport enum** — `didcomm` | `matrix`. First-class on `Channel` and `ConnectionOffer`.

- **Channel.matrixSyncMarker** — Persisted cursor for Matrix room history pagination.

- **MatrixService** — Full Matrix transport implementation: room creation, encryption, message sending, history fetch, media upload/download, session management.

- **MatrixConfig / MatrixDatabaseFactory** — Configuration for the Matrix transport: homeserver URI, device ID, database factory for OLM/Megolm state.

- **MatrixSessionManager** — Manages matrix client sessions per DID with persistent database-backed OLM state. Prevents device-key conflicts on cold start.

- **MessagingService** — Internal unified messaging layer that resolves transport (Matrix vs DIDComm) per channel and normalises incoming/outgoing messages.

- **downloadMedia(Channel, MediaReference)** — Decrypt and download hosted media from Matrix rooms.

- **removeMemberFromGroup()** — Group owner can kick a member (Matrix room kick + control plane deregistration).

- **MeetingPlaceCoreSDKErrorCode.channelNotificationFailed** — New error code surfaced when push notification delivery fails but the message itself succeeded.

- **did:web identity support** — Permanent identities now use `did:web` backed by control-plane-hosted DID documents.

---

### Fixed

- **Forbidden response on member deregistration** — 403 responses during deregistration are handled gracefully instead of crashing.

- **Duplicate R-Cards** — Prevents duplicate R-Cards from multi-path VDIP delivery.

## 0.0.1-dev.40

 - **FIX**: non inaugurated channel activity (#200).

## 0.0.1-dev.39

 - **FIX**: OOB invitation parser pre-auth crash vulnerability (#198).

## 0.0.1-dev.39

 - **SECURITY**: fix OobInvitationMessage parser to throw FormatException instead of crashing on malformed input (Audit ref: F-7, TM-7).

## 0.0.1-dev.38

 - Update a dependency to the latest release.

## 0.0.1-dev.37

 - **FEAT**: add VRC/VDIP channel attachment support to meeting_place_core (#196).

## 0.0.1-dev.36

 - **REFACTOR**: database schema and update dependencies (#168).

## 0.0.1-dev.35

 - **FEAT**: increase HTTP idle timeout for control plane requests (FTL-27059) (#174).

## 0.0.1-dev.34

 - **FIX**: stop ChatActivityEventHandler from deleting mediator messages (#177).

## 0.0.1-dev.33

 - **FEAT**: convert contact card fields to json blob (#157).

## 0.0.1-dev.32

 - **FIX**: rename docs to doc in meeting_place_core for pub.dev compliance (#167).
 - **DOCS**: core package documentation (#156).

## 0.0.1-dev.31

 - **REFACTOR**: extract ChatSDK message handlers into dedicated classes (#138).

## 0.0.1-dev.30

 - **FIX**: add missing return type info (#142).

## 0.0.1-dev.29

 - **FIX**: improvements and bug fixes (#131).

## 0.0.1-dev.28

 - **FIX**: quality improvements and resolution of minor bugs (#108).

## 0.0.1-dev.27

 - **FIX**: prevent blocking by removing wait on notify channel (#66).

## 0.0.1-dev.26

 - **FIX**: run network requests in parallel when setting up OOB invitation (#61).

## 0.0.1-dev.25

 - **FIX**: improve handling of transient network issues (#58).

## 0.0.1-dev.24

 - Update a dependency to the latest release.

## 0.0.1-dev.23

 - **FIX**: prevent multiple approvals for the same connection request (#55).

## 0.0.1-dev.22

 - **FIX**: preserve SDK options for expected message wrapping types in mediator service (#54).

## 0.0.1-dev.21

 - **FIX**: stop sending chat presence messages on error (#52).

## 0.0.1-dev.20

 - **FIX**: ephemeral usage and log DIDComm problem report details (#47).

## 0.0.1-dev.19

 - Update a dependency to the latest release.

## 0.0.1-dev.18

 - **FIX**: handle update ACL error gracefully on leaving channel if mediator is not reachable (#43).

## 0.0.1-dev.17

 - **FIX**: protocol alignment with standard; replace vCard by contactCard (#42).
 - **FIX**: handle notify-channel error gracefully (#36).

## 0.0.1-dev.16

 - **FIX**: handle notify-channel error gracefully (#36).
 - **FIX**: add expectedMessageWrappingTypes to MeetingPlaceCoreSDKOptions (#35).

## 0.0.1-dev.15

 - **FIX**: handle notification errors when sending messages (#32).

## 0.0.1-dev.14

 - **FIX**: expose method to retrieve DID manager from DID (#30).

## 0.0.1-dev.13

 - **FIX**: upgrade to DIDComm v2.3.0; handle message deletion in mediator SDK (#26).

## 0.0.1-dev.12

 - **FIX**: use latest ssi version v2.17.1 (#23).

## 0.0.1-dev.11

 - **FIX**: allow offer acceptance if existing offer is finalised or if channel is not inaugurated (#18).

## 0.0.1-dev.10

 - **FIX**: apply configured retry count and return network_error code in case of connection error (#16).

## 0.0.1-dev.9

 - **FIX**: update connection offer if it exists when accepting group offer (#14).

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

 - **FIX**: generate DID for OOB flow even when DID is provided during creation  (#5).

## 0.0.1-dev.2

 - **FIX**: improve pub.dev score by resolving analysis issues and updating example links (#4).

## 0.0.1-dev.1

 - **FIX**: use proper dev version format (#3).
 - **FIX**: make core package public (#2).

## 0.0.1-dev.0

 - **FEAT**: initial release

## 0.0.1-dev.20

 - **FIX**: correct group call role, media type, duration and leave handling (#321).

## 0.0.1-dev.19

 - **FEAT**: add media-kind-filtered chat repository query (#323).

## 0.0.1-dev.18

 - **FIX**: resolve joined member DID from persisted group on lookup miss (#310).

## 0.0.1-dev.17

 - **FIX**: arm outgoing call watchdog at start so stalled setup cannot hang (#316).

## 0.0.1-dev.16

 - **FIX**: stop group approval failing when member updates overlap (#301).
 - **FIX**: end 1:1 call and send outcome when remote peer disconnects (#317).

## 0.0.1-dev.15

 - **FIX**: stop live Matrix subscription from advancing channel sync marker (#311).

## 0.0.1-dev.14

 - **FEAT**: persist named group-call participants (#309).

## 0.0.1-dev.13

 - **FIX**: prevent duplicate group join-request cards (#307).

## 0.0.1-dev.12

 - **FIX**: allow any room member to start and join calls (#302).

## 0.0.1-dev.11

 - **FIX**: correct ongoing-call observation membership stream docs (#299).

## 0.0.1-dev.10

 - **FIX**: advance matrix sync markers to newest event to stop unread badge recount (#279).

## 0.0.1-dev.9

 - **FEAT**: ring a single group member via targeted group-notify (#292).

## 0.0.1-dev.8

 - **FIX**: stop old cancelled calls from showing up again (#294).

## 0.0.1-dev.7

 - **FIX**: allow invited members to join Matrix group calls (#289).

## 0.0.1-dev.6

 - **FIX**: enable participant name and avatar lookup during active calls (#283).

## 0.0.1-dev.5

 - **FIX**: use matrix room watcher for reliable group call cancel (#284).

## 0.0.1-dev.4

 - Update a dependency to the latest release.

## 0.0.1-dev.3

 - **FIX**: surface busy auto-reject on cancelled-call stream (#275).

## 0.0.1-dev.2

 - **FIX**: report network errors (#276).

## 0.0.1-dev.1

 - Update a dependency to the latest release.

## 0.0.1-dev.0

### Added

- Dedicated `meeting_place_matrix` package for Matrix transport support that was previously embedded in `meeting_place_core` and `meeting_place_chat`.

- `MeetingPlaceMatrixSDK`, `MeetingPlaceMatrixChatSDK`, `MatrixService`, and transport APIs for Matrix-backed individual chats, group chats, room subscriptions, and room history.

- Matrix media upload/download, image/video/document/voice attachments, typing indicators, reactions, message edits, message deletion, delivery receipts, and member removal support.

- Optional LiveKit-backed audio/video calling support, including Matrix RTC signalling helpers and call session models.

- Package-specific examples, test configuration, and setup guidance for Matrix encryption runtime initialization with `vodozemac`.

### Changed

- Matrix-specific runtime dependencies, examples, and setup documentation now live in `meeting_place_matrix` instead of `meeting_place_core` or `meeting_place_chat`.

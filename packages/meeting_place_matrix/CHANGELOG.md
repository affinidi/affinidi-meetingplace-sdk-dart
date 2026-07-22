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

# Affinidi Meeting Place - Matrix SDK for Dart

![Affinidi Meeting Place](https://raw.githubusercontent.com/affinidi/affinidi-meetingplace-sdk-dart/main/assets/images/meetingplace-banner.png)

The Affinidi Meeting Place - Matrix SDK for Dart provides the Matrix transport implementation for the Meeting Place SDK. It enables Matrix-backed individual chats, group chats, encrypted room events, media transfer, room history, and optional audio/video calling using Matrix as the underlying transport.

The Matrix SDK is part of the Meeting Place SDK toolkit and enables a safe and secure method of discovering, connecting, and communicating between individuals, businesses, and AI agents.

> **DISCLAIMER:** Affinidi provides this SDK as a developer tool to facilitate decentralized messaging. Any personal data exchanged or stored via this tool is entirely initiated and controlled by end-users. Affinidi does not collect, access, or process such data. Implementing parties are responsible for ensuring that their applications comply with applicable privacy laws and user transparency obligations.

## Core Concepts

- **Decentralised Identifier (DID)** - A globally unique identifier used by Matrix to represent user identities in the Meeting Place. DIDs enable secure, decentralised identity management across the system.

- **Matrix** - An open standard for secure, decentralised, and interoperable real-time communication. In the Meeting Place SDK, Matrix powers richer chat features such as individual and group chats, media attachments, encrypted room events, room history, and optional audio/video calling.

- **Matrix Room** - A named space where messages and events are exchanged. Rooms can be private (for individual chats) or public (for group chats), and they support end-to-end encryption.

- **End-to-End Encryption** - Native Matrix encryption using the `vodozemac` library to ensure all messages are encrypted on the sender's device and can only be decrypted by the intended recipient(s).

- **LiveKit** - An open-source, scalable Selective Forwarding Unit (SFU) that handles real-time media transport for audio and video calls. In the Meeting Place SDK, LiveKit powers peer-to-peer and group calling with end-to-end encrypted signalling via Matrix.

## Key Features

- Matrix-backed transport for individual and group chats in the Meeting Place SDK.
- Native Matrix end-to-end encryption backed by `vodozemac`.
- Rich Matrix chat actions such as image attachments, video attachments, file/document attachments, voice messages, reactions, edit messages, delete messages, typing indicators, and delivery receipts.
- Matrix room setup, join, invite, remove, subscription, and history flows for Matrix-only chat session handling on top of Meeting Place channels.
- Optional LiveKit-based audio/video calls.

## Requirements

- Dart SDK `^3.8.0`
- A Matrix homeserver
- The Matrix encryption runtime must be initialized before the first Matrix login
- For audio/video calling: a LiveKit and LiveKit JWT service that issues call tokens


## Installation

Run:

```bash
dart pub add meeting_place_matrix
```

or manually, add the package into your `pubspec.yaml` file:

```yaml
dependencies:
  meeting_place_matrix: ^<version_number>
```

and then run the command below to install the package:

```bash
dart pub get
```

Visit the pub.dev [install page](https://pub.dev/packages/meeting_place_matrix) of the Dart package for more information.

## Initializing the encryption runtime

The SDK uses native Matrix end-to-end encryption, which is backed by the
[`vodozemac`](https://pub.dev/packages/vodozemac) library. Vodozemac must be
initialized **once, before** the first Matrix login; otherwise Matrix client
creation will fail.

**Flutter apps** - add [`flutter_vodozemac`](https://pub.dev/packages/flutter_vodozemac)
to your app's `pubspec.yaml` and initialize it from `main()`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_vodozemac/flutter_vodozemac.dart' as fvod;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await fvod.init();
  // ... create MeetingPlaceMatrixSDK
}
```

**Pure-Dart apps** - build the vodozemac library for your target platform (see
the [vodozemac README](https://pub.dev/packages/vodozemac) for the Rust build
steps) and initialize it directly:

```dart
import 'package:vodozemac/vodozemac.dart' as vod;

Future<void> main() async {
  await vod.init(libraryPath: '/path/to/vodozemac/dylib/dir');
  // ... create MeetingPlaceMatrixSDK
}
```

## Matrix Setup

This SDK version expects `MatrixConfig` when creating `MeetingPlaceMatrixSDK`.
It uses the Control Plane to obtain Matrix JWTs for DIDs, logs users in to the
configured homeserver, and uses Matrix rooms for Matrix-backed chat flows.

To enable Matrix, provide:

| Setting | What it is used for |
|---------|---------------------|
| `mediatorDid` | DIDComm mediator used for discovery and connection flows. |
| `controlPlaneDid` | Control Plane DID used for discovery and Matrix JWT login. |
| `homeserver` | Matrix homeserver URL. |
| `databaseFactory` | Opens the local Matrix database for sessions, sync state, and encryption data. |
| `deviceId` | Device identifier used for Matrix device binding. |
| `serverName` | Optional Matrix server name override when it differs from `homeserver.host`. |
| `livekitServiceUrl` | URL of the LiveKit JWT service for issuing call tokens. Required to enable audio/video calling; when omitted, the call plugin is not created. |
| `livekitSfuUrl` | WebSocket URL of the LiveKit SFU. Overrides the URL from the token response, useful for local development when the container-internal hostname is not reachable from the device. |
| `sfuAllowedHosts` | Allowlist of SFU hostnames permitted when the JWT service supplies the SFU URL (i.e. `livekitSfuUrl` is null). |

## Quick Start

Create a Matrix-enabled SDK first, then initialize a Matrix chat session from a
Matrix channel.

```dart
import 'package:meeting_place_matrix/meeting_place_matrix.dart';

final matrixSDK = await MeetingPlaceMatrixSDK.create(
  wallet: wallet,
  repositoryConfig: repositoryConfig,
  config: MatrixConfig(
    mediatorDid: 'did:web:samplemediator.affinidi.io:.well-known',
    controlPlaneDid: 'did:web:samplecontrolplane.affinidi.io',
    homeserver: Uri.parse('https://matrix.example.com'),
    databaseFactory: matrixDatabaseFactory,
    deviceId: 'device-id-1',
  ),
);

final chatSDK = await MeetingPlaceMatrixChatSDK.initialiseFromChannel(
  channel,
  coreSDK: matrixSDK,
  chatRepository: chatRepository,
  options: const MeetingPlaceChatSDKOptions(),
);

final chat = await chatSDK.startChatSession();
final messages = chat.messages;
```

For more sample usage, go to the [example folder](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/tree/main/packages/meeting_place_matrix/example).

## Matrix Chat Capabilities

`meeting_place_matrix` is the Matrix-focused package in the Meeting Place SDK.
Use it when you need richer Matrix-based chat features such as:

- Individual Matrix chats
- Group chats
- Room event subscriptions
- Room history loading
- Image, video, file, and voice attachments
- Reactions
- Message edit and delete
- Typing indicators
- Delivery receipts

`MeetingPlaceMatrixChatSDK.initialiseFromChannel(...)` only supports channels
whose transport is `ChannelTransport.matrix`.

## Optional Audio/Video Calls

Audio/video calling is available when you provide:

- `MatrixConfig.livekitServiceUrl` - URL of your LiveKit JWT service for obtaining call tokens
- `MatrixConfig.livekitSfuUrl` - WebSocket URL of the LiveKit SFU (required for local development and most deployments; omit only if your JWT service provides the SFU URL)
- `rtcDelegate` and `roomFactory` parameters to `MeetingPlaceMatrixSDK.create(...)`

This integration uses Matrix RTC signalling (via Matrix rooms) together with a LiveKit SFU for media transport.

### LiveKit Setup

Pass LiveKit configuration to `MatrixConfig` and RTC implementation to `.create()`:

```dart
final matrixSDK = await MeetingPlaceMatrixSDK.create(
  // ... other params ...
  config: MatrixConfig(
    // ... other config ...
    livekitServiceUrl: Uri.parse('https://livekit-jwt.example.com'),
    livekitSfuUrl: Uri.parse('wss://livekit.example.com'),
  ),
  rtcDelegate: webRtcDelegate,
  roomFactory: liveKitRoomFactory,
);
```

Once configured, audio/video calls work seamlessly within Matrix chat rooms using the same end-to-end encryption.

## Running tests locally

### Option 1: Running tests via `melos` (recommended for CI and automation)

This approach uses environment variables from your shell and does **not**
require a `test/.env` file.

To run tests in this package from the terminal:

1. **Export your environment variables in your terminal:**

   ```bash
   export CONTROL_PLANE_DID="your:control-plane:did"
   export MEDIATOR_DID="your:mediator:did"
   export MATRIX_HOMESERVER="https://matrix.example.com"
   ```

   On platforms without the bundled test binary, also export:

   ```bash
   export VODOZEMAC_LIBRARY_PATH="/path/to/libvodozemac"
   ```

2. **Run tests using Melos:**

   ```bash
   melos run test
   ```

---

### Option 2: Running tests directly from VS Code (with `test/.env` file for local development)

If you want to run tests directly from VS Code (using the `Run` button or `Test Explorer`), you can use a `test/.env` file for local configuration:

1. **Create `test/.env` with your local settings:**

   ```dotenv
   CONTROL_PLANE_DID=your:control-plane:did
   MEDIATOR_DID=your:mediator:did
   MATRIX_HOMESERVER=https://matrix.example.com
   VODOZEMAC_LIBRARY_PATH=/path/to/libvodozemac
   ```

2. **Run your test files directly in VS Code:**
   - The test utilities will automatically load variables from `test/.env`.

**Note:**

- `VODOZEMAC_LIBRARY_PATH` is optional on macOS and Linux when using the bundled test library in this package.
- The `.env` file should be placed in the `test` folder as `test/.env`.

---

## Support & feedback

If you face any issues or have suggestions, please don't hesitate to contact us using [this link](https://share.hsforms.com/1i-4HKZRXSsmENzXtPdIG4g8oa2v).

### Reporting technical issues

If you have a technical issue with the project's codebase, you can also create an issue directly in GitHub.

1. Ensure the bug was not already reported by searching on GitHub under
   [Issues](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/issues).

2. If you're unable to find an open issue addressing the problem,
   [open a new one](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/issues/new).
   Be sure to include a **title and clear description**, as much relevant information as possible,
   and a **code sample** or an **executable test case** demonstrating the expected behaviour that is not occurring.

## Contributing

Want to contribute?

Head over to our [CONTRIBUTING](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/blob/main/CONTRIBUTING.md) guidelines.

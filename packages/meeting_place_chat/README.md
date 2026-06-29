# Affinidi Meeting Place - Chat SDK for Dart

![Affinidi Meeting Place](https://raw.githubusercontent.com/affinidi/affinidi-meetingplace-sdk-dart/main/assets/images/meetingplace-banner.png)

Affinidi Meeting Place - Chat SDK for Dart provides libraries to send secure and private messages using Decentralised Identifiers (DIDs), DIDComm v2.1, and Matrix. Messages are protected with end-to-end encryption so only the intended recipient can read the content.

The Chat SDK is part of the Meeting Place SDK toolkit and enables a safe and secure method of discovering, connecting, and communicating between individuals, businesses, and AI agents.

> **DISCLAIMER:** Affinidi provides this SDK as a developer tool to facilitate decentralized messaging. Any personal data exchanged or stored via this tool is entirely initiated and controlled by end-users. Affinidi does not collect, access, or process such data. Implementing parties are responsible for ensuring that their applications comply with applicable privacy laws and user transparency obligations.

## Core Concepts

- **Decentralised Identifier (DID)** - A globally unique identifier that enables secure interactions. The DID is the cornerstone of Self-Sovereign Identity (SSI), a concept that aims to put individuals or entities in control of their digital identities.

- **DIDComm Message** - is a JSON Web Message (JWM), a lightweight, secure, and standardised format for structured communication using JSON. It represents headers, message types, routing metadata, and payloads designed to enable secure and interoperable communication across different systems.

- **Mediator** - A service that handles and routes messages sent between participants (e.g., users, organisations, another mediator, or even AI agents).

- **Out-Of-Band** - The protocol defined in DIDComm enables sharing a DIDComm message or invitation through a transport method other than a direct, established DIDComm channel, such as via a QR code or a URL.

- **Connection Offer (Invitation)** - An invite to connect containing description and ContactCard info of the publisher. Each connection offer is assigned with a unique passphrase that others can use to discover and accept the offer to connect.

## Key Features

- End-to-end encryption for secure and private communication.
- Support for individual chats over DIDComm or Matrix.
- Support for Matrix group chats.
- Matrix based chat features such as voice messages, reactions, edit messages, delete messages, typing indicators, delivery receipts, and media attachments.
- Notifies connections for contact details update (e.g., name change).
- Supports ContactCard in publishing a connection offer (invitation) and establishing connections with others to chat.
- Supports DIDComm Message v2.1 and Matrix based transports for sending and receiving messages.

## Transport Capabilities

Chats can run over DIDComm or Matrix based transport. Each transport supports a different set of features. Check `capabilities` before showing a feature in your app:

```dart
if (chatSDK.capabilities.supports(ChatFeature.messageEdit)) {
  // show the edit option
}
```

Individual chats can use DIDComm based transport or Matrix based transport. Group chats require Matrix based transport.

| Feature | DIDComm based transport | Matrix based transport |
|---------|-------------------------|------------------------|
| Individual chat | 🟢 | 🟢 |
| Group chat | 🔴 | 🟢 |
| Text messages | 🟢 | 🟢 |
| Image attachments | 🟢<br><sub>Auto downloads</sub> | 🟢 |
| File/document attachments | 🔴 | 🟢 |
| Audio/video attachments | 🔴 | 🟢 |
| Voice messages | 🔴 | 🟢 |
| Message edit/delete | 🔴 | 🟢 |
| Reactions | 🟢 | 🟢 |
| Typing indicators | 🟢 | 🟢 |
| Delivery receipts | 🟢 | 🟢 |
| Visual effects | 🟢 | 🟢 |
| Contact details update | 🟢 | 🟢 |
| Presence Indicator | 🟢 | 🔴 |

Each SDK declares its own set in its `capabilities` getter: `IndividualDidcommChatSDK`, `IndividualMatrixChatSDK`, and `GroupMatrixChatSDK`. See [Chat transport capabilities](doc/chat-transport-capabilities.md) for the full list.

## Choose a Transport

Most apps should not create a concrete chat SDK directly. Call `MeetingPlaceChatSDK.initialiseFromChannel(...)`; it reads the channel and returns the right implementation.

| SDK | When it is used |
|-----|-----------------|
| `IndividualDidcommChatSDK` | One-to-one DIDComm chats. Use this for DIDComm-only flows and presence. |
| `IndividualMatrixChatSDK` | One-to-one Matrix based chats. Use this for richer chat actions such as voice messages, edit, and delete. |
| `GroupMatrixChatSDK` | Group chats. Group chat always uses Matrix and also supports group membership actions. |

## Matrix Requirements

Matrix-backed chats need the Core SDK to be configured for Matrix first. The chat package uses Core for Matrix login, room access, media upload/download, and end-to-end encryption.

Before starting a Matrix based chat, make sure:

- The Core SDK was created with `MatrixConfig`.
- `MatrixConfig.homeserver` points to your Matrix homeserver.
- `MatrixConfig.databaseFactory` opens a local Matrix database.
- `MatrixConfig.deviceId` is stable for the device or app install.
- The Matrix encryption runtime is initialized before the first Matrix login. Flutter apps use `flutter_vodozemac`; pure Dart apps use `vodozemac`.

## Requirements

- Dart SDK `^3.8.0`

## Installation

Run:

```bash
dart pub add meeting_place_chat
```

or manually, add the package into your `pubspec.yaml` file:

```yaml
dependencies:
  meeting_place_chat: ^<version_number>
```

and then run the command below to install the package:

```bash
dart pub get
```

Visit the pub.dev [install page](https://pub.dev/packages/meeting_place_chat) of the Dart package for more information.

## Quick Start

Create a channel with the Core SDK first, then start a chat session from that channel.

```dart
import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

final chatSDK = await MeetingPlaceChatSDK.initialiseFromChannel(
  channel,
  coreSDK: coreSDK,
  chatRepository: chatRepository,
  options: const MeetingPlaceChatSDKOptions(),
);

final chat = await chatSDK.startChatSession();
final messages = chat.messages;
```

For more sample usage, go to [example folder](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/tree/main/packages/meeting_place_chat/example).

## Common Chat Actions

Use `capabilities` before showing transport-specific actions.

```dart
await chatSDK.sendTextMessage('Hello');
await chatSDK.sendChatActivity(); // typing/activity signal

if (chatSDK.capabilities.supports(ChatFeature.reactions)) {
  await chatSDK.reactOnMessage(message, reaction: '+1');
}

if (chatSDK.capabilities.supports(ChatFeature.messageEdit)) {
  await chatSDK.editTextMessage(message, 'Updated message');
}

if (chatSDK.capabilities.supports(ChatFeature.messageDelete)) {
  await chatSDK.deleteMessage(message);
}
```

## Running tests locally

### Option 1: Running tests via `melos` (recommended for CI and automation)

This approach uses environment variables from your shell and does **not** require an `.env` file.

To run tests in this package from the terminal:

1. **Export your environment variables in your terminal:**

   ```bash
   export CONTROL_PLANE_DID="your:control-plane:did"
   export MEDIATOR_DID="your:mediator:did"
   ```

   Replace these DIDs with your actual test values.

2. **Run tests using Melos:**

   ```bash
   melos run test
   ```

---

### Option 2: Running tests directly from VS Code (with `.env` file for local development)

If you want to run tests directly from VS Code (using the `Run` button or `Test Explorer`), you can use an `.env` file for local configuration:

1. **Create your local environment file:**

   _(Run this command in your terminal to copy the template and create `test/.env` for your tests.)_

   ```bash
   cp test/templates/.example.env test/.env
   ```

2. **Edit `test/.env`** and update the values for `CONTROL_PLANE_DID` and `MEDIATOR_DID` to match your test environment.

3. **Run your test files directly in VS Code:**
   - The test utilities will automatically load variables from `test/.env`.

**Note:**

- The `.env` file should be placed in the `test` folder as `test/.env`.
- The template file is provided at `test/templates/.example.env` for convenience.

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

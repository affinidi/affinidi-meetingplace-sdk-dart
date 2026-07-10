# Affinidi Meeting Place - Core SDK for Dart

![Affinidi Meeting Place](https://raw.githubusercontent.com/affinidi/affinidi-meetingplace-sdk-dart/main/assets/images/meetingplace-banner.png)

The Affinidi Meeting Place - Core SDK for Dart provides tools to build a secure messaging app for individuals, businesses, and AI agents. It supports Decentralised Identifiers (DIDs) and DIDComm v2.1. DIDs let users communicate without using an email address or phone number as their main identity.

The Core SDK facilitates seamless, secure, and authentic communication between parties, ensuring trust in digital interactions.

> **DISCLAIMER:** Affinidi provides this SDK as a developer tool to facilitate decentralized messaging. Any personal data exchanged or stored via this tool is entirely initiated and controlled by end-users. Affinidi does not collect, access, or process such data. Implementing parties are responsible for ensuring that their applications comply with applicable privacy laws and user transparency obligations.

## Core Concepts

- **Decentralised Identifier (DID)** - A globally unique identifier that enables secure interactions. The DID is the cornerstone of Self-Sovereign Identity (SSI), a concept that aims to put individuals or entities in control of their digital identities.

- **DIDComm Message** - is a JSON Web Message (JWM), a lightweight, secure, and standardised format for structured communication using JSON. It represents headers, message types, routing metadata, and payloads designed to enable secure and interoperable communication across different systems.

- **Mediator** - A service that handles and routes messages sent between participants (e.g., users, organisations, another mediator, or even AI agents).

- **Out-Of-Band** - The protocol defined in DIDComm enables sharing a DIDComm message or invitation through a transport method other than a direct, established DIDComm channel, such as via a QR code or a URL.

- **Connection Offer (Invitation)** - An invite to connect containing description and ContactCard info of the publisher. Each connection offer is assigned with a unique passphrase that others can use to discover and accept the offer to connect.

## Key Features

- Support for multiple digital identities, ensuring privacy and anonymity when interacting with different entities across systems.
- End-to-end encryption for secure and private communication.
- Reduces spam by requiring the user's consent when other users try to establish a connection through the discovery mechanism.
- Implements the DIDComm Message v2.1 protocol, and connects and authenticates with mediators that follow the same protocol.
- Seamlessly integrates with Self-Sovereign Identity (SSI), including Verifiable Credentials/Presentations.

## Core and Chat SDK Roles

Use the Core SDK to create identities, publish and accept offers, approve connection requests, and create channels. Use the Chat SDK after a channel exists to send messages and handle chat actions.

## Decentralised Identity

Using other chat applications, you usually register with your email address or phone number as your identifier, which exposes users to privacy risks. The Core SDK allows users to have multiple identities to represent themselves in digital interactions, depending on the context, using a Decentralised Identifier (DID). For example, you can have an identity for work or finance; each profile has its own DID and contains different credentials.

Leveraging the DID and DIDComm protocol, it guarantees:

- Authenticity – Messages come from who they claim to be.
- Confidentiality – End-to-end encryption prevents leaks.
- Non-repudiation – Sender can't deny sending a message.

## Requirements

- Dart SDK `^3.8.0`

## Installation

Run:

```bash
dart pub add meeting_place_core
```

or manually, add the package into your `pubspec.yaml` file:

```yaml
dependencies:
  meeting_place_core: ^<version_number>
```

and then run the command below to install the package:

```bash
dart pub get
```

Visit the pub.dev [install page](https://pub.dev/packages/meeting_place_core) of the Dart package for more information.

## Quick Start

The app provides the wallet and repositories.

```dart
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

final coreSDK = await MeetingPlaceCoreSDK.create(
  wallet: wallet,
  repositoryConfig: repositoryConfig,
  config: Config(
    mediatorDid: 'did:web:samplemediator.affinidi.io:.well-known',
    controlPlaneDid: 'did:web:samplecontrolplane.affinidi.io',
  ),
);

await coreSDK.registerForPushNotifications(const Uuid().v4());

final publishOfferResult = await coreSDK.publishOffer(
  offerName: 'Example offer',
  type: SDKConnectionOfferType.invitation,
  offerDescription: 'Example offer to test.',
  contactCard: ContactCard(
    did: 'did:test:alice',
    type: 'human',
    contactInfo: {
      'n': {'given': 'Alice'},
    },
  ),
  validUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
);
```

For more sample usage, go to [example folder](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/tree/main/packages/meeting_place_core/example).


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

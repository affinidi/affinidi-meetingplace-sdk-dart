# Affinidi Meeting Place - Mediator SDK for Dart

The Affinidi Meeting Place - Mediator SDK for Dart provides the libraries to connect, authenticate, and send messages through the mediator service, handling and routing messages to intended recipients. The Affinidi Meeting Place - Mediator SDK is the interface for integrating with different mediators (e.g., DIDComm Mediators) to send messages securely to other participants.

The Mediator SDK is part of the Meeting Place SDK toolkit and enables a safe and secure method of discovering, connecting, and communicating with others (individuals, businesses, and AI agents).

> **DISCLAIMER:** Affinidi provides this SDK as a developer tool to facilitate decentralized messaging. Any personal data exchanged or stored via this tool is entirely initiated and controlled by end-users. Affinidi does not collect, access, or process such data. Implementing parties are responsible for ensuring that their applications comply with applicable privacy laws and user transparency obligations.

## Core Concepts

- **Decentralised Identifier (DID)** - A globally unique identifier that enables secure interactions. The DID is the cornerstone of Self-Sovereign Identity (SSI), a concept that aims to put individuals or entities in control of their digital identities.

- **DIDComm Message** - is a JSON Web Message (JWM), a lightweight, secure, and standardised format for structured communication using JSON. It represents headers, message types, routing metadata, and payloads designed to enable secure and interoperable communication across different systems.

- **Mediator** - A service that handles and routes messages sent between participants (e.g., users, organisations, another mediator, or even AI agents).

- **Out-Of-Band** - The protocol defined in DIDComm enables sharing a DIDComm message or invitation through a transport method other than a direct, established DIDComm channel, such as via a QR code or a URL.

- **Connection Offer** - An invite to connect containing description and vCard info of the publisher. Each connection offer is assigned with a unique passphrase that others can use to discover and accept the offer to connect.

## Key Features

- Implements the DIDComm Message v2.1 protocol with Out-of-Band support.
- Support for Access Control Lists (ACLs) to manage the participants' permissions to send and receive messages over the mediator.
- Connect and authenticate with different mediator services that follow the DIDComm Message v2.1 protocol.

## Requirements

- Dart SDK `>=3.6.0 <4.0.0`

## Installation

Run:

```bash
dart pub add meeting_place_mediator
```

or manually, add the package into your `pubspec.yaml` file:

```yaml
dependencies:
  meeting_place_mediator: ^<version_number>
```

and then run the command below to install the package:

```bash
dart pub get
```

Visit the pub.dev install page of the Dart package for more information.

## Usage

```dart
import 'package:meeting_place_mediator/mediator_sdk.dart';
import 'package:ssi/ssi.dart';
import 'package:didcomm/didcomm.dart';

void main() async {
   // Provide concrete implementations
   final DidResolver didResolver = /* your DidResolver */;
   final DidManager ownerDidManager = /* owner DidManager */;
   final DidManager clientDidManager = /* client DidManager */;
   final DidDocument recipientDidDocument = /* recipient DID Document */;

   // Initialize SDK
   final sdk = MediatorSDK(
      mediatorDid: 'did:example:mediator',
      didResolver: didResolver,
   );

   // Authenticate (returns a MediatorSessionClient)
   final session = await sdk.authenticateWithDid(ownerDidManager);
   print('Authenticated to mediator');

   // Create an Out-Of-Band invitation (URI you can share)
   final Uri oobUri = await sdk.createOob(clientDidManager, null);
   print('OOB URI: $oobUri');

   // Retrieve OOB details from URI
   final oob = await sdk.getOob(oobUri, didManager: clientDidManager);
   print('OOB invitation received: $oob');

   // Send a plaintext DIDComm message
   final PlainTextMessage message = PlainTextMessage(
      /* fill message fields per your didcomm implementation, e.g. body/text */
   );

   await sdk.sendMessage(
      message,
      senderDidManager: ownerDidManager,
      recipientDidDocument: recipientDidDocument,
   );
  
   print('Message sent');

   // Fetch pending messages from mediator
   final messages = await sdk.fetchMessages(
      didManager: ownerDidManager,
      deleteOnRetrieve: true,
   );
  
   for (final m in messages) {
      print('Fetched message hash=${m.messageHash}, message=${m.message}');
   }
}
```

For more sample usage, go to [example folder](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/tree/main/example).

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

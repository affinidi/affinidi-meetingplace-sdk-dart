# Affinidi Meeting Place - Chat SDK for Dart

![Affinidi Meeting Place](https://raw.githubusercontent.com/affinidi/affinidi-meetingplace-sdk-dart/main/assets/images/meetingplace-banner.png)

Affinidi Meeting Place - Chat SDK for Dart provides the libraries to send a secure and private messages utilising Decentralised Identifiers (DIDs) and DIDComm v2.1 protocol for a safe digital interactions. The messages are protected with end-to-end encryption and only the intended recipient can read the content.

The Chat SDK is part of the Meeting Place SDK toolkit and enables a safe and secure method of discovering, connecting, and communicating between individuals, businesses, and AI agents.

> **DISCLAIMER:** Affinidi provides this SDK as a developer tool to facilitate decentralized messaging. Any personal data exchanged or stored via this tool is entirely initiated and controlled by end-users. Affinidi does not collect, access, or process such data. Implementing parties are responsible for ensuring that their applications comply with applicable privacy laws and user transparency obligations.

## Core Concepts

- **Decentralised Identifier (DID)** - A globally unique identifier that enables secure interactions. The DID is the cornerstone of Self-Sovereign Identity (SSI), a concept that aims to put individuals or entities in control of their digital identities.

- **DIDComm Message** - is a JSON Web Message (JWM), a lightweight, secure, and standardised format for structured communication using JSON. It represents headers, message types, routing metadata, and payloads designed to enable secure and interoperable communication across different systems.

- **Mediator** - A service that handles and routes messages sent between participants (e.g., users, organisations, another mediator, or even AI agents).

- **Out-Of-Band** - The protocol defined in DIDComm enables sharing a DIDComm message or invitation through a transport method other than a direct, established DIDComm channel, such as via a QR code or a URL.

- **Connection Offer (Invitation)** - An invite to connect containing description and ContactCard info of the publisher. Each connection offer is assigned with a unique passphrase that others can use to discover and accept the offer to connect.

## Key Features

- End-to-end encryption of messages for more secure and private communication.
- Support for individual or group chats, delivery receipt and chat presence.
- Notifies connections for contact details update (e.g., name change).
- Support ContactCard in publishing a connection offer (invitation) and establishing connections with others to chat.
- Implements the DIDComm Message v2.1 protocol for sending and receiving messages.

## Requirements

- Dart SDK `>=3.6.0 <4.0.0`

## Installation

Run:

```bash
dart pub add chat_sdk
```

or manually, add the package into your `pubspec.yaml` file:

```yaml
dependencies:
  chat_sdk: ^<version_number>
```

and then run the command below to install the package:

```bash
dart pub get
```

Visit the pub.dev install page of the Dart package for more information.

## Usage

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'lib/chat_sdk.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

void main() async {
   final storage = InMemoryStorage();

   final aliceSDK = MeetingPlaceCoreSDK.create(
      wallet: PersistentWallet(InMemoryKeyStore()),
      repositoryConfig: RepositoryConfig(
         connectionOfferRepository: ConnectionOfferRepositoryImpl(storage: storage),
         groupRepository: GroupRepositoryImpl(storage: storage),
         channelRepository: ChannelRepositoryImpl(storage: storage),
         keyRepository: KeyRepositoryImpl(storage: storage),
      ),
      mediatorDid: 'did:web:samplemediator.affinidi.io:.well-known',
      controlPlaneDid: 'did:web:samplecontrolplane.affinidi.io',
   );

   await aliceSDK.registerForPushNotifications(const Uuid().v4());

  final publishOfferResult = await aliceSDK.publishOffer(
    offerName: 'Example offer',
    offerDescription: 'Example offer to test.',
    contactCard: ContactCard(
      did: 'did:test:alice',
      type: 'human',
      contactInfo: {
        'n': {'given': 'Alice'},
      },
    ),
    publishAsGroup: false,
    validUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
  );

  final waitForInvitationAccept = Completer<ControlPlaneStreamEvent>();
  final waitForChannelActivity = Completer<ControlPlaneStreamEvent>();

  aliceSDK.discoveryEventsStream.listen((event) {
    if (event.type == DiscoveryEventType.InvitationAccept) {
      waitForInvitationAccept.complete(event);
    }
  });

  final receivedEvent = await waitForInvitationAccept.future;

  final channel = await aliceSDK.approveConnectionRequest(
    connectionOffer: publishOfferResult.connectionOffer,
    channel: receivedEvent.channel,
  );

  final aliceChatSDK = await ChatSDK.initialiseFromChannel(
      channel,
      coreSDK: aliceSDK,
      chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
  );
}
```

For more sample usage, go to [example folder](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/tree/main/packages/meeting_place_chat/example).

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

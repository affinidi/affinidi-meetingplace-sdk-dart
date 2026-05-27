# Affinidi Meeting Place - Relationship SDK for Dart

![Affinidi Meeting Place](https://raw.githubusercontent.com/affinidi/affinidi-meetingplace-sdk-dart/main/assets/images/meetingplace-banner.png)

The Affinidi Meeting Place - Relationship SDK for Dart provides domain models, credential builders, and repository interfaces for exchanging verifiable relationship credentials over the Meeting Place SDK. Supported types include Verifiable Relationship Credentials (VRC) and Relationship Cards (R-Cards), with an extensible design for adding new credential types.

The Relationship SDK is part of the Meeting Place SDK toolkit. It builds on top of `meeting_place_core` for DIDComm transport and protocol primitives. Storage implementations for `RCardRepository` and `VrcRepository` are required; `meeting_place_drift_repository` provides ready-made Drift-backed implementations.

> **DISCLAIMER:** Affinidi provides this SDK as a developer tool to facilitate decentralized messaging. Any personal data exchanged or stored via this tool is entirely initiated and controlled by end-users. Affinidi does not collect, access, or process such data. Implementing parties are responsible for ensuring that their applications comply with applicable privacy laws and user transparency obligations.

## Core Concepts

- **[Relationship Card (R-Card)](https://docs.google.com/document/d/1RtS86BqyVn3i3mXm48VhC-SRaYvW2W_MvR4w6x9KQWY/edit?tab=t.0#heading=h.cg17eeqde3ek)** - A Verifiable Credential encoding a user's contact information (name, email, phone, company, etc.) as a [jCard (RFC 7095)](https://www.rfc-editor.org/rfc/rfc7095) in the credential subject, exchangeable over DIDComm channels and exportable to [vCard 3.0 (RFC 6350)](https://www.rfc-editor.org/rfc/rfc6350).

- **[Verifiable Relationship Credential (VRC)](https://docs.google.com/document/d/1RtS86BqyVn3i3mXm48VhC-SRaYvW2W_MvR4w6x9KQWY/edit?tab=t.0#heading=h.siks62ntn9c5)** - A Verifiable Credential encoding a mutual relationship between two DIDs (`from` and `to` parties), exchanged via a two-step request-reciprocate handshake over the VDIP protocol.

- **[Verifiable Data Issuance Protocol (VDIP)](https://docs.affinidi.com/dev-tools/affinidi-tdk/dart/libraries/vdip/)** - The verifiable-data exchange protocol used to transport credentials and credential requests over an established DIDComm channel.

## Key Features

- Domain models for relationship credentials with full JSON serialisation.
- `CredentialBuilder` for signing R-Card and VRC credentials with `ecdsa-jcs-2019` Data Integrity proofs.
- Repository interfaces (`RCardRepository`, `VrcRepository`) with live-watch and snapshot query methods; Drift implementations are in `meeting_place_drift_repository`.
- `MeetingPlaceRelationshipSDK` façade that wires protocol handlers, stream managers, and repositories into a single injectable service.
- `RCardVCardExtension` for exporting R-Card subjects to vCard 3.0 strings.
- Extensible design that supports new relationship credential types without changing the core architecture.

## Requirements

- Dart SDK `>=3.8.0 <4.0.0`
- An initialised `MeetingPlaceSDK` instance from `meeting_place_core`.
- Storage implementations for `RCardRepository` and `VrcRepository` (e.g. from `meeting_place_drift_repository`).

## Installation

Run:

```bash
dart pub add meeting_place_relationship
```

or manually, add the package into your `pubspec.yaml` file:

```yaml
dependencies:
  meeting_place_relationship: ^0.0.1-dev.1
```

and then run the command below to install the package:

```bash
dart pub get
```

Visit the pub.dev install page of the Dart package for more information.

## Usage

```dart
import 'package:meeting_place_relationship/meeting_place_relationship.dart';

void main() async {
  // 1. Instantiate the SDK facade (inject your own repository implementations)
  final relationshipSDK = MeetingPlaceRelationshipSDK(
    coreSDK: coreSDK,              // MeetingPlaceCoreSDK from meeting_place_core
    rCardRepository: myRCardRepo,  // implements RCardRepository
    vrcRepository: myVrcRepo,      // implements VrcRepository
  );

  // 2. Listen for incoming R-Cards (channel inauguration and VDIP paths)
  relationshipSDK.receivedRCards.listen((RCard rCard) {
    final subject = RCardSubject.fromVcBlob(rCard.vcBlob);
    print('R-Card from ${rCard.subjectDid}: ${subject?.firstName}');
  });

  // 3. Listen for incoming VRC requests and received VRCs
  // Fires when a peer initiates an exchange; respond via handleReceivedVrcRequest.
  relationshipSDK.receivedVrcRequests.listen((VrcRequest request) {
    print('VRC request from ${request.senderDid}');
  });

  // Fires when the peer's signed VRC arrives; the credential is ready to persist.
  relationshipSDK.receivedVrcs.listen((VrcIssuance issuance) {
    print('VRC received from ${issuance.senderDid}');
  });

  // 4. Initiate a VRC exchange on an established channel
  await relationshipSDK.requestVrcExchange(
    channelDid: myChannelDid,
    identityDid: myDid,
    identityName: 'Alice',
  );
}
```

For more sample usage, go to [example folder](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/tree/main/packages/meeting_place_relationship/example).

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

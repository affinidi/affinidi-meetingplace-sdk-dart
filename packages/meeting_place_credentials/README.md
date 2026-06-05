# Affinidi Meeting Place - Credentials SDK for Dart

![Affinidi Meeting Place](https://raw.githubusercontent.com/affinidi/affinidi-meetingplace-sdk-dart/main/assets/images/meetingplace-banner.png)

The Affinidi Meeting Place - Credentials SDK for Dart provides the domain models, credential builders, and repository interfaces needed to exchange verifiable relationship credentials over the Meeting Place SDK. It supports Verifiable Relationship Credentials (VRC), Relationship Cards (R-Cards), and a modular Human ZKP pipeline based on Liveness Credentials. It builds on top of `meeting_place_core` for DIDComm transport and protocol primitives.

Storage implementations for `RCardRepository` and `VrcRepository` are required. The `meeting_place_drift_repository` package provides ready-made Drift-backed implementations.

> **DISCLAIMER:** Affinidi provides this SDK as a developer tool to facilitate decentralized messaging. Any personal data exchanged or stored via this tool is entirely initiated and controlled by end-users. Affinidi does not collect, access, or process such data. Implementing parties are responsible for ensuring that their applications comply with applicable privacy laws.

## Core Concepts

- **[Relationship Card (R-Card)](https://docs.google.com/document/d/1RtS86BqyVn3i3mXm48VhC-SRaYvW2W_MvR4w6x9KQWY/edit?tab=t.0#heading=h.cg17eeqde3ek)** - A Verifiable Credential encoding a user's contact information (name, email, phone, company, etc.) as a [jCard (RFC 7095)](https://www.rfc-editor.org/rfc/rfc7095) in the credential subject, exchangeable over DIDComm channels and exportable to [vCard 3.0 (RFC 6350)](https://www.rfc-editor.org/rfc/rfc6350).
- **[Verifiable Relationship Credential (VRC)](https://docs.google.com/document/d/1RtS86BqyVn3i3mXm48VhC-SRaYvW2W_MvR4w6x9KQWY/edit?tab=t.0#heading=h.siks62ntn9c5)** - A Verifiable Credential encoding a mutual relationship between two DIDs (`from` and `to` parties), exchanged via a two-step request-response handshake over the VDIP protocol.
- **[Verifiable Data Issuance Protocol (VDIP)](https://docs.affinidi.com/dev-tools/affinidi-tdk/dart/libraries/vdip/)** - The verifiable-data exchange protocol used to transport credentials and credential requests over an established DIDComm channel.
- **Liveness Credential** - A Verifiable Credential encoding a face liveness check result including provider, session ID, score, threshold, pass or fail, and timestamp.
- **Zero-Knowledge Proof (ZKP)** - A Groth16 proof derived from a Liveness Credential that proves liveness without revealing the underlying personal or biometric data.

## Key Features

- Full domain models for R-Cards, VRCs, and Liveness Credentials with JSON serialisation and Data Integrity proofs.
- `CredentialBuilder` signs R-Card and VRC credentials with `ecdsa-jcs-2019` Data Integrity proofs.
- `RCardRepository` and `VrcRepository` expose live-watch and snapshot query methods.
- `MeetingPlaceCredentialsSDK` wires protocol handlers, stream managers, and repositories into a single injectable service.
- `RCardVCardExtension` exports R-Card subjects to vCard 3.0 strings for contacts apps.
- The liveness flow exposes `LivenessEvidenceSource`, `LivenessVcIssuanceService`, and `LivenessCredentialSubject`.
- New credential types can be added without changing the core architecture or existing handling flows.

## Requirements

- Dart SDK `>=3.8.0 <4.0.0`
- An initialised `MeetingPlaceSDK` instance from `meeting_place_core`
- Storage implementations for `RCardRepository` and `VrcRepository`

## Installation

Run:

```bash
dart pub add meeting_place_credentials
```

or manually, add the package into your `pubspec.yaml` file:

```yaml
dependencies:
  meeting_place_credentials: ^<version_number>
```

and then run the command below to install the package:

```bash
dart pub get
```

Visit the pub.dev [install page](https://pub.dev/packages/vc_zkp) of the Dart package for more information.

## Usage

```dart
import 'package:meeting_place_credentials/meeting_place_credentials.dart';

void main() async {
  final credentialsSDK = MeetingPlaceCredentialsSDK(
    coreSDK: coreSDK,
    rCardRepository: myRCardRepo,
    vrcRepository: myVrcRepo,
  );

  credentialsSDK.receivedRCards.listen((RCard rCard) {
    final subject = RCardSubject.fromVcBlob(rCard.vcBlob);
    print('R-Card from ${rCard.subjectDid}: ${subject?.firstName}');
  });

  credentialsSDK.receivedVrcRequests.listen((VrcRequest request) {
    print('VRC request from ${request.senderDid}');
  });

  credentialsSDK.receivedVrcs.listen((VrcIssuance issuance) {
    print('VRC received from ${issuance.senderDid}');
  });

  await credentialsSDK.requestVrcExchange(
    channelDid: myChannelDid,
    identityDid: myDid,
    identityName: 'Alice',
  );
}
```

For more sample usage, go to the [example folder](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/tree/main/packages/meeting_place_credentials/example).

## Credentials Feature

### R-Card and VRC Feature

R-Cards and VRCs are the core relationship primitives in this SDK. They allow two participants to exchange verified contact information and record a mutual relationship over DIDComm channels.

Working code for both flows is included in the [Affinidi Meeting Place Reference App](https://github.com/affinidi/affinidi-meetingplace-reference-app).

#### R-Card Exchange

An R-Card is a signed W3C Verifiable Credential containing a jCard payload (RFC 7095). It is sent automatically on channel establishment and can be shared manually at any time.

- Receive incoming R-Cards with `credentialsSDK.receivedRCards`
- Parse contact fields with `RCardSubject.fromVcBlob(rCard.vcBlob)`
- Export to vCard 3.0 with `RCardVCardExtension.toVCard(subject)`
- Persist and query with `RCardRepository`

#### VRC Exchange

A VRC certifies a mutual verified relationship between two DIDs. It uses a two-step VDIP handshake where the initiating side requests and the responding side reciprocates.

- Initiate exchange with `credentialsSDK.requestVrcExchange(channelDid, identityDid, identityName)`
- Receive inbound requests from `credentialsSDK.receivedVrcRequests`
- Accept and reciprocate with `credentialsSDK.handleReceivedVrcRequest(request)`
- Receive finished credentials from `credentialsSDK.receivedVrcs`
- Persist and query with `VrcRepository`

### Human ZKP Feature

The Human ZKP flow lets one participant prove human liveness to another participant without sharing personal or biometric data.

The SDK's liveness flow is built around `LivenessEvidenceSource`, `LivenessVcIssuanceService`, and `LivenessCredentialSubject`.

#### Pipeline Stages

- Stage 1: `LivenessEvidenceSource` collects raw `LivenessEvidence` from an app or provider-specific implementation.
- Stage 2: `LivenessVcIssuanceService.issue()` signs a W3C Verifiable Credential from the normalised evidence.
- Stage 3: `LivenessCredentialSubject` models the signed credential subject for downstream transport or proof code.

This package issues the credential and models its subject. Proof generation and DIDComm transport are handled by the consuming application.

## Running tests locally

### Option 1: Running tests via `melos` (recommended for CI and automation)

This approach uses environment variables from your shell and does not require an `.env` file.

To run tests in this package from the terminal:

1. Export your environment variables in your terminal:

   ```bash
   export CONTROL_PLANE_DID="your:control-plane:did"
   export MEDIATOR_DID="your:mediator:did"
   ```

   Replace these DIDs with your actual DID values for your environment.

2. Run tests using Melos:

   ```bash
   melos run test
   ```

### Option 2: Running tests directly from VS Code (with `.env` file for local development)

If you want to run tests directly from VS Code using the Run button or Test Explorer, you can use an `.env` file for local configuration:

1. Create your local environment file:

   ```bash
   cp test/templates/.example.env test/.env
   ```

2. Edit `test/.env` and update the values for `CONTROL_PLANE_DID` and `MEDIATOR_DID` to match your test environment.

3. Run your test files directly in VS Code.

The test utilities automatically load variables from `test/.env`.

## Support & feedback

If you face any issues or have suggestions, please don't hesitate to contact us using [this link](https://share.hsforms.com/1i-4HKZRXSsmENzXtPdIG4g8oa2v).

### Reporting technical issues

If you have a technical issue with the project's codebase, you can also create an issue directly in GitHub.

1. Ensure the bug was not already reported by searching on GitHub under [Issues](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/issues).

2. If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/issues/new). Be sure to include a **title and clear description**, as much relevant information as possible, and a **code sample** or an **executable test case** demonstrating the expected behaviour that is not occurring.

## Contributing

Want to contribute?

Head over to our [CONTRIBUTING](https://github.com/affinidi/affinidi-meetingplace-sdk-dart/blob/main/CONTRIBUTING.md) guidelines.

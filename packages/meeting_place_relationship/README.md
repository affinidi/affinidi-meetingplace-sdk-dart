# meeting_place_relationship

Domain models, credential builders, and repository interfaces for
Verifiable Relationship Credentials (VRC) and Relationship Cards (R-Cards)
in the [Meeting Place SDK](https://github.com/affinidi/affinidi-meetingplace-sdk-dart).

## Overview

A pure-Dart library that any Meeting Place SDK consumer can depend on for
relationship credential domain logic.

### What's included

- **VRC models** — `RelationshipCredential`, `RelationshipCredentialSubject`, `VrcCredentialSubject`, `VrcExchangeRole`
- **R-Card models** — `RCardSubject`, `ReceivedRCard`, `RCardVC`, `RCardCredentialSubject`
- **R-Card vCard export** — `RCardVCardExtension.toVCard()`
- **Shared constants** — `RelationshipCredentialConstants`
- **SDK value objects** — `PersonaDid` (replaces app-level `MinimalPersona` / `Identity`)
- **Repository interfaces** — `RelationshipCredentialRepository`, `RCardRepository` (Subtask 3)
- **SDK extension** — `coreSDK.relationship.*` (Subtask 2)

## Usage

```dart
import 'package:meeting_place_relationship/meeting_place_relationship.dart';

// Parse an R-Card from a raw VC blob
final subject = RCardSubject.fromVcBlob(vcBlob);

// Export an R-Card as a vCard string
final vcard = subject?.toVCard(notes: 'Met at conference');

// Detect credential kind
if (vc.isCredentialVrc) { ... }
if (vc.isCredentialRCard) { ... }
```

## Package boundaries

- No Flutter dependency — pure Dart only.
- Repository interfaces are included; Drift implementations live in `meeting_place_drift_repository`.
- Credential builders live in this package; transport/protocol wiring lives in `meeting_place_core`.

## See also

- [meeting_place_core](../meeting_place_core)
- [meeting_place_chat](../meeting_place_chat)
- [meeting_place_drift_repository](../meeting_place_drift_repository)

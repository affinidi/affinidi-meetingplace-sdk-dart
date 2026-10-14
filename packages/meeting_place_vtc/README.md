# Meeting Place VTC

Verifiable Trust Community (VTC) support for the Meeting Place SDK.

This package implements the wallet side of OpenVTC Trust Tasks in Dart. It
starts with signed Trust Task documents (`eddsa-jcs-2022`) and
`digestMultibase`, the building blocks of the Key Grant sign-in flow.

## Usage

```dart
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';

final signer = Ed25519DidKeySigner.generate();
final claim = await TrustTaskDocument.create(
  type: 'https://trusttasks.org/spec/auth/oob/claim/0.1',
  issuer: signer.did,
  recipient: vtcDid,
  parentThreadId: requestId,
  payload: {'requestId': requestId},
).sign(signer, purpose: ProofPurpose.authentication);
```

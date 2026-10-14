# Meeting Place VTC

Verifiable Trust Community (VTC) support for the Meeting Place SDK.

This package implements the wallet side of [OpenVTC](https://openvtc.net)
Trust Tasks in Dart. It is interoperable with other OpenVTC wallets, such as
[Keyring](https://github.com/berkmancenter/keyring-wallet). It covers the Key
Grant sign-in: a member scans the sign-in code of a community's member portal
or operator console, and approves the sign-in on their phone.

## What it does

- **Trust Task documents** with `eddsa-jcs-2022` proofs and `digestMultibase`.
- **Trigger links**: reads one-scan sign-in codes offline. It passes the VTI
  trigger-link conformance vectors.
- **VTC resolution**: endpoints come only from the community's resolved DID
  document, never from the code.
- **Key Grant sign-in** (`auth/oob/*`): claim, prove, approve and cancel.
- **VTA client** over the REST binding: persona signing, the sign-in vault
  entry, device enrolment of the biometric approval key, and personas and
  stored membership cards.
- **Manual VTA link and community import** from membership cards that another
  app backed up to the VTA.

## Key custody

The member's persona keys stay in their VTA. The phone holds two keys:

- a **manager key**, which the VTA's access list grants and which signs
  requests to the VTA;
- a **biometric approval key** (a `TrustTaskSigner` the app provides), which
  approves each grant.

Each sign-in also uses a throwaway key that lives only in memory. Keep both
long-lived keys in secure storage on the device. Never back them up or log
them.

## Usage

```dart
import 'package:meeting_place_vtc/meeting_place_vtc.dart';

final sdk = MeetingPlaceVtcSDK();

// One-time: link the member's VTA. Show manager.did to the VTA admin, who runs
// `pnm --vta <name> acl create --did <did> --role admin`.
final manager = sdk.newManagerKey(); // store manager.seed securely
final vta = sdk.vtaClient(vtaDid: vtaDid, manager: manager);
final linked = await VtaLink.isGranted(vta);

// Each sign-in.
final link = sdk.readTriggerLink(scannedText);
if (link is! TriggerLinkAccepted ||
    link.uiFor(TriggerLinkConfig.meetingPlace) != null) {
  return; // show the matching TriggerLinkUi words
}

final signIn = sdk.signInClient(isKnownCommunity: isKnownCommunity);
final claimed = await signIn.claim(link); // the browser now shows a number

final membership = await sdk.communityImport(vta).find(claimed.vtc.did);
final persona = await sdk.prepareSignIn(
  vta: vta,
  membership: membership!,
  userVerificationDid: approvalKey.did,
  deviceName: 'Phone',
  platform: 'ios',
);

final proved = await signIn.prove(
  claimed,
  enteredNumber: typedNumber,
  persona: persona,
  agent: vta,
);
// Show proved.requester ("reported by the community"), then:
await signIn.approve(proved, agent: vta, userVerification: approvalKey);
// or, to decline: await signIn.cancel(claimed);
```

Failures are thrown as `SignInException`. Its `SignInFailure` value names the
outcome to word for the person. Never cancel a sign-in whose
`SignInException.responded` is true.

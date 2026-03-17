# Matrix DID Binding Architecture (Draft)

Proposed flow for binding a `permanentChannelDID` to a Matrix user ID using a trusted Issuance Service, so the receiver can cryptographically verify the binding.

```mermaid
sequenceDiagram
    box Channel Initiator (SDK on member's device)
        participant CI as Channel Initiator
    end

    box Issuance Service (external server)
        participant IS as Issuance Service
        participant MHS as Matrix Home Server
    end

    box Receiver (SDK on admin's device)
        participant RX as Receiver (Group Admin)
    end

    Note over CI: 1. Generate permanent channel DID
    CI->>IS: DIDComm: authenticate (prove ownership of DID)
    IS-->>CI: authentication confirmed

    CI->>IS: DIDComm: register-matrix-user (authenticated request)
    IS->>MHS: register user on behalf of verified DID
    MHS-->>IS: matrixUserId (@alice:example.com)

    CI->>IS: DIDComm VDIP: request credential
    IS-->>CI: issue VC (MatrixDIDBindingCredential)

    Note over CI: VC binds permanentChannelDID ↔ matrixUserId

    CI->>RX: DIDComm: InvitationAcceptanceGroup (with VC attached)

    Note over RX: 2. Verify VC before approving membership
    RX->>IS: look up issuer public keys (via DID resolution / well-known)
    IS-->>RX: public keys for VC verification
    RX->>RX: verify VC signature + credential subject

    Note over RX: 3. Continue flow only if VC is valid
    RX->>MHS: inviteUserToRoom(verifiedMatrixUserId, roomId)
```

## VC Structure (example)

```json
{
  "@context": ["https://www.w3.org/ns/credentials/v2"],
  "type": ["VerifiableCredential", "MatrixDIDBindingCredential"],
  "issuer": "did:web:control-plane-api.com",
  "issuanceDate": "2026-03-16T16:05:00Z",
  "credentialSubject": {
    "did": "did:key:permanent_channel_did",
    "matrix_user": "@alice:example.com"
  },
  "proof": {
    "type": "DataIntegrityProof",
    "cryptosuite": "eddsa-jcs-2022",
    "created": "2026-03-16T16:05:00Z",
    "verificationMethod": "did:web:issuer.example.com#key-1",
    "proofPurpose": "assertionMethod",
    "proofValue": "28x1ld9KpOSqWe..."
  }
}
```

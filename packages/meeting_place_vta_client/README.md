# VTA Dart Client

App-side Dart client SDK for interacting with local/hosted VTA.

## Phase 1 scope (MPX personal agent)

This package is the app facing VTA client SDK for MPX personal agent use cases.
Phase 1 focuses on personal agent flows, not the full VTA admin surface.

Planned Phase 1 areas:

1. Auth and session
2. DIDComm transport layer (DIDComm first with REST fallback)
3. Credential and integration startup
4. Core VTA identity operations needed by app flows
5. VTA domain APIs needed by MPX app flows
 
Current status:

- Auth and session: in progress (challenge, authenticate, refresh, whoami API surface and session manager are present)
- DIDComm transport layer: complete for Phase 1 client scope (DIDComm-first auth transport with REST fallback, websocket mediator channel, mediator connectivity, session handling, sender-authenticated inbound enforcement, correlation/thread matching, and step-up approval flow support are implemented in the base SDK plus optional `vta_dart_client_mobile_core` authcrypt adapter)
- Credential and integration startup: partially implemented (credential bundle and DID secrets models present)
- Core VTA identity operations: partially implemented (key/sign models present; step-up approval operation over trusted task submit path has been added; broader endpoint coverage is still incomplete)
- VTA domain APIs for MPX: not implemented yet


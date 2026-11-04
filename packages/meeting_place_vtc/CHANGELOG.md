## 0.1.0

 - Add Trust Task documents with `eddsa-jcs-2022` proofs and `digestMultibase`.
 - Add the VTI trigger-link reader for one-scan sign-in codes.
 - Add VTC endpoint resolution and the Trust Task HTTPS transport.
 - Add the Key Grant sign-in client (`auth/oob/*`).
 - Sign in with the `auth/oob` versions VTCs serve: claim 0.2, prove 0.3, respond 0.3 and grant 0.3, with RFC 3339 deadlines and the offered `signingScope`.
 - Add a minimal VTA client over the REST binding.
 - Check in an already registered phone with `device/heartbeat/0.3`, the version VTAs serve.
 - Add the manual VTA link and community import from backed-up membership cards.
 - Add the `MeetingPlaceVtcSDK` entry point.
 - Add the join client (`vtc/join-requests/*`), persona creation and credential storage on the VTA.
 - Include the underlying cause in `MeetingPlaceVtcSDKException.toString`.

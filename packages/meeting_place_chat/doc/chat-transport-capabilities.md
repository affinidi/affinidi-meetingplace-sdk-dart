# Chat Transport Capabilities

This page lists the chat features each transport supports, for DIDComm and Matrix.

The app reads each chat's capabilities and hides or disables any action the chat does not support. Capabilities come from the chat SDK and reflect both the transport and the chat type. Until a chat's capabilities are known, transport-dependent actions stay hidden.

The capability matrix below covers per-chat actions that differ between transports. These are the features the `ChatFeature` enum gates in the UI. Other identity and credential features that ride on top of chat (credential exchange, R-Card sharing) are not transport-gated; see [Identity and credential features](#identity-and-credential-features).

The `ChatFeature` enum and the `TransportCapabilities` type live in `transport_capabilities.dart`. Each chat SDK declares its own capability set and exposes it through `capabilities`.

## Capability matrix

| Feature | Description | DIDComm | Matrix |
| --- | --- | :---: | :---: |
| Text messaging | Send and receive plain text messages | Yes | Yes |
| Image attachments | Send and receive images (hosted media on Matrix, inline on DIDComm) | Yes | Yes |
| Video attachments | Send and receive video files | No | Yes |
| Document attachments | Send and receive non-media files such as PDF and office documents | No | Yes |
| Voice messages | Record and play voice notes as hosted media | No | Yes |
| Reactions | Add emoji reactions to messages | Yes | Yes |
| Typing indicators | Show a typing indicator to the other participant | Yes | Yes |
| Presence | Online and last-seen status | Yes | No |
| Delivery receipts | Sent, delivered, and read marks | Yes | Yes |
| Message edit | Edit an already-sent text message | No | Yes |
| Message delete | Delete a sent message, for everyone or just for yourself | No | Yes |
| Effects | Visual effects such as confetti | Yes | Yes |
| Contact details update | Propose and accept contact-card changes | Yes | Yes |
| Human ZKP liveness | Zero-knowledge liveness concierge exchange | Yes | No |

Group chat is not in this matrix on purpose. Whether a chat is individual or
group is set by the channel type, not gated as a per-chat action, so it is not
a `ChatFeature`. Group chats run on Matrix only and otherwise share the Matrix
feature set.

## DIDComm

Supported: text messaging, image attachments, reactions, typing indicators, presence, delivery receipts, effects, contact details update, human ZKP liveness.

Not supported: voice messages, message edit, message delete for everyone.

## Matrix

Supported: text messaging, image attachments, video attachments, document attachments, voice messages, reactions, typing indicators, delivery receipts, message edit, message delete for everyone, effects, contact details update.

Not supported: presence.

## Key differences

| Scope | Features |
| --- | --- |
| Matrix only | Video attachments, document attachments, voice messages, message edit, message delete |
| DIDComm only | Presence |
| Both transports | Text messaging, image attachments, reactions, typing indicators, delivery receipts, effects, contact details update |

## Identity and credential features

Alongside the per-chat actions above, the chat layer carries identity and credential features. These are not transport capabilities: they work on both DIDComm and Matrix, so the app does not gate them by transport.

| Feature | Description | DIDComm | Matrix | Notes |
| --- | --- | :---: | :---: | --- |
| Credential exchange (VRC / VDIP) | Request and receive verifiable credentials within a chat | Yes | Yes | Individual chats only, not group chats. On DIDComm the request-issuance and issued-credential messages arrive as chat events. On Matrix they route through the core VDIP stream. |
| R-Card sharing | Share and update relationship-card details | Yes | Yes | Built on the contact-details update flow, which both transports support. Handled in the app chat service, not gated per transport. |

Credential exchange and R-Card sharing stay out of the `ChatFeature` enum on purpose: they do not vary by transport. Credential exchange varies by chat type (individual versus group), so that distinction belongs to the per-chat-type design, not the transport capability set.

Human ZKP liveness is in the `ChatFeature` enum because it is supported on individual DIDComm chats only. The SDK still exposes liveness ZKP concierge mappers and derivers for apps that build the flow; query `ChatFeature.humanZkp` before offering or handling the exchange.

## Behaviour in the application

On loading a chat, the app stores the channel's transport and gates the UI to match. When the active transport does not support a feature, the app:

- Hides image attachment actions when image attachments are unsupported.
- Hides video attachment actions when video attachments are unsupported.
- Hides the voice message control when voice messages are unsupported.
- Hides both delete actions (delete for everyone and delete for me) when message delete is unsupported.
- Hides the presence indicator when presence is unsupported.

The chat session service also guards these operations, so an unsupported action fails fast instead of sending malformed data. Text, reactions, typing, and effects stay available on both transports.

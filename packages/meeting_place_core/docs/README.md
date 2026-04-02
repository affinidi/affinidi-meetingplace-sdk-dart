# Meeting Place Core Docs

### Protocol flows

- [Meeting Place DIDComm Connection Protocol](./protocol/meeting-place-group-protocol.mdmeeting-place-protocol.md)
	End-to-end protocol flow for individual connections, including offer publication, acceptance, approval, and channel inauguration.

- [Meeting Place Group DIDComm Connection Protocol](./protocol/meeting-place-group-protocol.md)
	End-to-end protocol flow for group invitations, membership approval, and member finalisation.

### Runtime models

- [Channel And Connection State Model](./runtime_models/channel-and-connection-state-model.md)
	How `ConnectionOffer`, `Channel`, and `Group.members` change over time and which fields are the practical source of truth.

- [Control Plane Event Handling Model](./runtime_models/control-plane-event-handling-model.md)
	What control-plane events exist, how handlers process them, and how updates are emitted through the SDK event stream.

- [Mediator ACL And Routing Model](./runtime_models/mediator-acl-and-routing-model.md)
	How the SDK uses DIDs, mediator ACLs, and routing transitions during handshake and steady-state messaging.

- [Notification And Sync Model](./runtime_models/notification-and-sync-model.md)
	How control-plane notifications, DIDComm notification registration, and channel sync bookkeeping fit together at runtime.

- [Repository And Persistence Model](./runtime_models/repository-and-persistence-model.md)
	What the SDK persists through repository interfaces and which entities and lookup paths matter across restarts.

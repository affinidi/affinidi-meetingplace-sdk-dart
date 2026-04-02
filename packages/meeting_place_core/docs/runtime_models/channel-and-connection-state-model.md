# Channel And Connection State Model

This document explains how the Core SDK persists and evolves three related pieces of state:

- `ConnectionOffer`
- `Channel`
- group membership state in `Group.members`

This is the model SDK consumers should use for UI state, retries, and local persistence.

## Why This Matters

The SDK does not represent the full lifecycle in a single object.

- `ConnectionOffer` tracks offer discovery and some acceptance/finalisation data.
- `Channel` tracks whether a peer or group channel is usable yet.
- `Group.members` tracks pending and approved members for group flows.

For that reason:

- an offer can remain `published` while there are already pending or completed connections derived from it
- the reliable signal that the private pairwise DIDComm channel is established is usually `Channel.status == inaugurated`
- for groups, the authoritative membership queue is `Group.members`, not `ConnectionOffer.status`

## Mental Model

The model is best understood as three related layers of state, each with a distinct responsibility:

- `ConnectionOffer` represents the invitation itself. It captures offer discovery, publication, acceptance metadata, and whether the local device should still treat the offer as active.
- `Channel` represents a concrete communication relationship derived from an offer. It shows whether the DIDComm handshake has progressed far enough for ongoing communication to use the established channel.
- `Group.members` represents membership state within a group. It is the authoritative local view of which members are pending review, approved, or removed.

Taken together, `ConnectionOffer` describes the invitation, `Channel` describes the communication path derived from that invitation, and `Group.members` describes group membership state.

## ConnectionOffer State Model

`ConnectionOfferStatus` declares these values:

- `published`
- `finalised`
- `accepted`
- `deleted`

### What Each Offer State Means

| State | Meaning in practice | Typical side |
| --- | --- | --- |
| `published` | The offer exists locally and remains available for discovery and future accepts. On the owner side, it can stay in this state even after one or more connection or membership requests already exist. | Offer owner, or a device that only discovered the offer |
| `accepted` | The local device accepted the offer and generated local DIDs for the handshake. The relationship is not yet usable. | Acceptor or joining group member |
| `finalised` | The acceptor-side flow received the final approval event and persisted enough data to complete the handshake. For groups, this means the member has received the inaugural group payload. | Acceptor or joining group member |
| `deleted` | The offer should no longer be treated as claimable or active in local state. | Either side |

### Important Asymmetry

`ConnectionOffer.status` is not a symmetric lifecycle across both sides.

The main reason is that an offer is not the same thing as a single connection. A published offer can be used multiple times, so the offer can legitimately stay `published` while per-connection progress is tracked in `Channel` records and, for groups, in `Group.members`.

For individual connections:

- the publisher publishes an offer as `published`
- when someone accepts it, the publisher receives `InvitationAccept` and a pending `Channel` is created
- when the publisher approves the request, the publisher-side updates DIDs but does not change `status`
- the publisher's offer can therefore remain `published` even after one connection has progressed, because the same offer may still be reused for later connections

For group offers:

- the admin's published `GroupConnectionOffer` also starts as `published`
- that published group offer can remain reusable for additional join requests
- pending and approved membership changes are reflected mainly in `Group.members` and approval channels
- the joining member's local copy moves through `accepted` and then `finalised`

This means UI should not treat `ConnectionOffer.status` as the only source of truth for invitation progress or whether the ongoing DIDComm channel has been established.

### Offer Transitions

#### Individual offer flow

| From | To | Trigger | What the SDK does |
| --- | --- | --- | --- |
| none | `published` | `publishOffer(...)` | Creates and persists a local offer owned by the publisher |
| none | `published` | `findOffer(...)` | Returns a discovered offer object; it is not necessarily persisted yet |
| `published` | `accepted` | `acceptOffer(...)` | Persists `acceptOfferDid`, `permanentChannelDid`, local contact card, and accepted state |
| `accepted` | `finalised` | `OfferFinalised` event processed by `OfferFinalisedEventHandler` | Fetches `ConnectionRequestApproval`, registers notifications, updates channel, and persists final offer data |
| any active state | `deleted` | `markConnectionOfferAsDeleted(...)`, unlink, leave, or deletion paths | Marks the local offer deleted or removes it entirely |

#### Group offer flow

| From | To | Trigger | What the SDK does |
| --- | --- | --- | --- |
| none | `published` | `publishOffer(...)` with group invitation type | Persists the admin-side `GroupConnectionOffer` |
| none | `published` | `findOffer(...)` for a group invitation | Returns discovered group offer details |
| `published` | `accepted` | `acceptGroupOffer(...)` | Persists the joining member's local DIDs and placeholder group membership |
| `accepted` | `finalised` | `GroupMembershipFinalised` processed by `GroupMembershipFinalisedEventHandler` | Replaces placeholder group metadata, registers notifications, updates channel, and marks the offer finalised |
| any active state | `deleted` | leave or delete paths | Marks the offer deleted locally |

### Offer Fields That Change Along The Way

These fields are more operationally useful than the status alone:

| Field | When it becomes meaningful |
| --- | --- |
| `acceptOfferDid` | After local acceptance |
| `permanentChannelDid` | After local acceptance |
| `otherPartyPermanentChannelDid` | After approval or finalisation data is received |
| `notificationToken` | After finalisation for the side that registers notifications |
| `otherPartyNotificationToken` | After the other side's notification token becomes known |

For UI, these fields are good evidence that a handshake progressed, even when `status` did not move in the way a consumer might expect.

## Channel State Model

`ChannelStatus` is the most useful model for whether the ongoing DIDComm channel has been established in the SDK.

The values are:

- `waitingForApproval`
- `approved`
- `inaugurated`

### What Each Channel State Means

| State | Meaning in practice | Availability for ongoing communication |
| --- | --- | --- |
| `waitingForApproval` | A request exists, but the final counterparty or group routing data is not fully established yet. | No |
| `approved` | Only used for connection initiators in individual or OOB flows. The initiator approved the request, but is still waiting for the peer's `ChannelInauguration`. | Not yet |
| `inaugurated` | The private pairwise DIDComm channel is established and the steady-state identifiers and notification data are in place. Ongoing communication can use this channel. | Yes |

### Channel Creation Patterns

There are three important ways channels appear locally.

#### 1. Individual request appears on the publisher side

When the publisher processes `InvitationAccept`, the SDK creates a new individual `Channel` with:

- `status = waitingForApproval`
- `isConnectionInitiator = true`
- `acceptOfferDid = message.from`
- `otherPartyPermanentChannelDid` set from `InvitationAcceptance.body.channelDid`

This is the object the publisher approves.

#### 2. Individual request is created on the acceptor side

When the acceptor calls `acceptOffer(...)`, the SDK creates a new individual `Channel` with:

- `status = waitingForApproval`
- `isConnectionInitiator = false`
- local `permanentChannelDid`
- local `acceptOfferDid`

This channel exists before the publisher approves it.

#### 3. Group membership request creates both a membership channel and a group record

When a user accepts a group invitation:

- the joining member gets a placeholder local `Group`
- the joining member gets a group `Channel` in `waitingForApproval`

When the admin receives `InvitationGroupAccept`:

- the admin's main group channel remains the already-established admin-to-group channel
- the SDK also creates an additional group `Channel` in `waitingForApproval` representing the pending membership request
- the admin's `Group.members` list gains a `pendingApproval` member

That pending-request channel is the object passed into `approveConnectionRequest(...)` for group approval.

### Channel Transitions

#### Individual channels

| From | To | Trigger | Side |
| --- | --- | --- | --- |
| none | `waitingForApproval` | `InvitationAcceptedEventHandler` after `InvitationAccept` | Publisher |
| none | `waitingForApproval` | `acceptOffer(...)` | Acceptor |
| `waitingForApproval` | `approved` | `approveConnectionRequest(...)` and `markChannelApprovedForConnectionInitiator(...)` | Publisher |
| `waitingForApproval` | `inaugurated` | `OfferFinalised` processed and `markChannelInauguratedForNonConnectionInitiator(...)` | Acceptor |
| `approved` | `inaugurated` | `ChannelActivity` carrying `ChannelInauguration`, processed by `ChannelInaugurationEventHandler` | Publisher |

#### Group channels

| From | To | Trigger | Side |
| --- | --- | --- | --- |
| none | `inaugurated` | Group creation by admin | Admin |
| none | `waitingForApproval` | `acceptGroupOffer(...)` | Joining member |
| none | `waitingForApproval` | `InvitationGroupAcceptedEventHandler` | Admin pending request channel |
| `waitingForApproval` | `inaugurated` | `GroupMembershipFinalised` processed and `markGroupChannelInauguratedFromWaitingForApproval(...)` | Joining member |

## Group Membership State Model

Group membership is persisted in `Group.members`, where each `GroupMember` has a `GroupMemberStatus`.

### Group Membership Flow

The enum declares:

- `pendingApproval`
- `pendingInauguration`
- `approved`
- `rejected`
- `error`
- `deleted`

### What The Current Implementation Actually Uses

In the current code paths, the SDK actively persists:

- `pendingApproval`
- `approved`

The remaining enum values exist but are not currently advanced by the main membership workflow.

In particular:

- `pendingInauguration` is declared but not assigned by the current handlers or services
- `rejected` is not written when the admin rejects a request; the member is removed from the `Group.members` list instead
- `error` and `deleted` are declared but not part of the active membership transition logic

Consumers should treat those unused values as reserved for future behavior, not as states they should expect to observe today.

### Membership Transitions

| From | To | Trigger | What the SDK does |
| --- | --- | --- | --- |
| none | `pendingApproval` | Joining member accepts a group invite | Creates placeholder group and inserts the local member as pending |
| none | `pendingApproval` | Admin processes `InvitationGroupAccept` | Adds the candidate member to the admin's local group as pending |
| `pendingApproval` | `approved` | Admin approves membership | Marks the member approved in the admin's local group |
| `pendingApproval` | `approved` | Joining member processes `GroupMembershipFinalised` | Marks the local member approved and syncs members from the admin snapshot |
| `pendingApproval` | removed from list | Admin rejects membership | Removes the member instead of setting `rejected` |

### Placeholder Group Behavior

The joining member does not wait for finalisation before a group exists locally.

Placeholder values are used at this stage because the final group identifiers and metadata are only received later via the `GroupMemberInauguration` DIDComm message.

During `acceptGroupOffer(...)`, the SDK creates or updates a local placeholder `Group` with:

- a temporary `id`
- a temporary `did`
- the accepted member persisted as `pendingApproval`

Later, when `GroupMembershipFinalised` is processed, the SDK replaces that placeholder data with the actual:

- `groupId`
- `groupDid`
- `groupPublicKey`
- `ownerDid`
- approved membership snapshot from `GroupMemberInauguration`

This allows the SDK to persist local group state immediately, then replace the placeholder values once the DIDComm message provides the authoritative group data.

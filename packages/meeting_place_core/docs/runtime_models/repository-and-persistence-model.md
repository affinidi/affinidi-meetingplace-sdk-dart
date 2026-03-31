# Repository And Persistence Model

This document explains what `meeting_place_core` stores through its repository interfaces and which write paths exist in the current implementation.

## Why This Matters

The Core SDK delegates nearly all durable local state to repository implementations supplied through `RepositoryConfig`.

That means the repository layer is responsible for preserving:

- connection and group offer state
- channel state
- group aggregates and membership state
- DID derivation metadata and group encryption key material

The SDK itself does not ship with a single built-in persistence model. Instead, it uses repository interfaces for entity storage, lookup paths, and updates across application restarts.

## Repository Set

`RepositoryConfig` defines four repository dependencies:

| Repository | Presence in `RepositoryConfig` | Stores |
| --- | --- | --- |
| `ConnectionOfferRepository` | Required | `ConnectionOffer` and `GroupConnectionOffer` records |
| `ChannelRepository` | Required | `Channel` records |
| `KeyRepository` | Required | DID derivation metadata and persisted key pairs |
| `GroupRepository` | Optional in the config | `Group` aggregates, including `Group.members` |

If `groupRepository` is not supplied, `RepositoryConfig` falls back to `GroupNotImplementedRepository`, which throws on every call.

## Core Persistence Model

The current implementation persists whole records, not partial patches.

- create methods persist a complete entity snapshot
- update methods replace the stored snapshot with the latest entity state
- delete or remove methods delete the stored snapshot entirely

The example repositories in `meeting_place_core/example` use an upsert-like model for `create*` and `update*`.

## What Each Repository Stores

### ConnectionOfferRepository

This repository stores the full serialized offer entity.

- individual offers are stored as `ConnectionOffer`
- group offers are stored as `GroupConnectionOffer`
- both share the same repository surface

Lookup patterns used by the SDK:

- by `offerLink`
- by `permanentChannelDid`
- by `groupDid`
- full listing via `listConnectionOffers()`

Observed record shape and lookup role:

- `offerLink` acts as the primary stable identity
- `permanentChannelDid` and `groupDid` act as secondary lookup values once those fields become available
- stored group offers are read back as `GroupConnectionOffer`

### ChannelRepository

This repository stores the full serialized `Channel` entity.

Lookup patterns used by the SDK:

- `findChannelByDid(String did)`
- `findChannelByOtherPartyPermanentChannelDid(String did)`

In the runtime model, a channel may need to be found by:

- the local `permanentChannelDid`
- the remote `otherPartyPermanentChannelDid`
- for group channels, the `group.did` stored as `otherPartyPermanentChannelDid`

The example implementation indexes both the local and other-party DID values and rewrites the full record on update.

### GroupRepository

This repository stores the full `Group` aggregate, including:

- `id`
- `did`
- `offerLink`
- `publicKey`
- `ownerDid`
- `members`
- other group metadata fields

Lookup patterns used by the SDK:

- by `groupId`
- by `offerLink`

Observed aggregate shape:

- `members` is persisted as part of the `Group` record, not in a separate repository
- during membership finalisation, a placeholder group record is replaced by a final group record

That last point matters because the current group-join flow can persist a placeholder group with a temporary `id` and `did`, then later create a new final `Group` and remove the placeholder record.

### KeyRepository

This repository does not store domain entities. It stores key-management metadata required to reconstruct DIDs and group encryption state.

The interface covers four categories of data:

| Data | Interface methods | Purpose |
| --- | --- | --- |
| DID derivation counter | `getLastAccountIndex`, `setLastAccountIndex` | Generates new DID derivation paths without collisions |
| DID-to-keyId mapping | `saveKeyIdForDid`, `getKeyIdByDid` | Allows `ConnectionManager` to reconstruct a `DidManager` for a previously generated DID |
| Group and member key pairs | `saveKeyPair`, `getKeyPair` | Persists recrypt key pairs for group owner DIDs, member DIDs, and group DIDs |

Observed runtime usage:

- `getLastAccountIndex()` is used as the source for the next DID derivation index
- `saveKeyIdForDid()` stores the mapping later used to reconstruct a `DidManager` for an existing DID
- `saveKeyPair()` stores raw key bytes used by group encryption flows

## What Is Not Persisted Through These Repositories

The Core SDK does not expect these repositories to persist every runtime concern.

The following are handled elsewhere or only reflected indirectly:

- control-plane pending notifications and event queue state
- mediator ACL state
- DIDComm message bodies fetched from the mediator
- control-plane device registration state, except where notification tokens are copied onto `ConnectionOffer` or `Channel`
- OOB session objects used during interactive flows

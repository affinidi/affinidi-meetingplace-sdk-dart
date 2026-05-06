# Affinidi Meeting Place - Drift Repository SDK for Dart

![Affinidi Meeting Place](https://raw.githubusercontent.com/affinidi/affinidi-meetingplace-sdk-dart/main/assets/images/meetingplace-banner.png)

The Affinidi Meeting Place - Drift Repository SDK is a package that implements the [Drift database](https://pub.dev/packages/drift) to persist and manage channels, connection offers, groups, and chat history in the device's local storage.

## Key Features

- **Manage channels**
    - Create a channel
    - Retrieve a channel via either your DID or the other party DID
    - Retrieve a channel via the other party DID
    - Retrieve a channel via an offerLink
    - Update a channel
    - Delete a channel

- **Manage connections**
  - Create a connection offer
  - Retrieve a connection via an offerLink
  - Retrieve a connection via a permanent channel DID
  - Retrieve a connection via a group DID
  - Retrieve all connection offers
  - Update a connection offer
  - Delete a connection offer
  
- **Manage groups**
  - Create a group
  - Retrieve a group by id
  - Retrieve a group by offerLink
  - Update a group
  - Delete a group

- **Manage chat history**
  - Create a message
  - Retrieve all messages associated to a chatId
  - Retrieve a message within a chat by Id
  - Update a message

## Requirements

- Dart SDK version ^3.9.2

## Installation

Run:

```bash
dart pub add meeting_place_drift_repository
```

or manually add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  meeting_place_drift_repository: ^<version_number>
```

and then run the command below to install the package:

```bash
dart pub get
```

For more information, visit the pub.dev install page of the package.

## Regenerate Database Classes

The package uses drift code generation. To regenerate database classes, run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Schema Migrations

This package uses [Drift schema snapshots](https://drift.simonbinder.eu/migrations/tests/)
to verify that each migration produces the exact schema the Dart model expects.

### Files

| Path                                 | Description                                                                                                      |
| ------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `drift_schemas/drift_schema_vN.json` | JSON snapshot of the database schema at version `N`. Committed to source control.                                |
| `test/utils/schema_versions.dart/`   | Dart helpers generated from the snapshots, used by `SchemaVerifier` in migration tests. **Do not edit by hand.** |

`test/utils/schema_versions.dart/` contains three generated files:

- `schema.dart` — exports `GeneratedHelper`, the entry point for `SchemaVerifier`.
- `schema_vN.dart` — a minimal generated database class mirroring the table structure at version N (no app logic). `SchemaVerifier` uses these to create an in-memory database at any historical version, run the actual `onUpgrade` callback against it, then diff the result against the snapshot.

### When to update

Bump `schemaVersion` in `ChatItemsDatabase` whenever the table structure changes,
then run the two commands below from the package root.

**1. Dump the new snapshot:**

```bash
dart run drift_dev schema dump \
  lib/src/repositories/chat_items_repository/chat_items_database.dart \
  drift_schemas/drift_schema_v<new_version>.json
```

**2. Regenerate the test helpers:**

```bash
dart run drift_dev schema generate \
  drift_schemas/ \
  test/utils/schema_versions.dart/
```

Commit both the new `drift_schema_vN.json` and the regenerated
`test/utils/schema_versions.dart/` files. Then add a migration test block
in `test/chat_items_migration_test.dart` for the new version.

### Canary test

`test/chat_items_migration_test.dart` contains a canary test that verifies
`GeneratedHelper.versions` includes the current `schemaVersion`. If the two
commands above are not run after bumping the version, CI will fail immediately
with a message like:

```
Expected: contains <3>
  Actual: [1, 2]
```

This catches the missing snapshot steps before the migration tests even run.

## Encrypted databases with sqlite3 v3

`package:sqlite3` v3 no longer ships SQLCipher. To keep encrypted database
support, configure `sqlite3` to use SQLite3MultipleCiphers in your `pubspec`:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc
```

Existing SQLCipher databases remain compatible when the database is opened with
the SQLCipher compatibility pragmas before the key is applied:

```sql
PRAGMA cipher = 'sqlcipher';
PRAGMA legacy = 4;
PRAGMA key = '...';
```

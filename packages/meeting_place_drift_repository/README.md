# Affinidi Meeting Place - Drift Repository SDK for Dart

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
dart pub add affinidi_mpx_sdk_repositories_drift
```

or manually add the package to your `pubspec.yaml` file:

```yaml
dependencies:
  affinidi_mpx_sdk_repositories_drift: ^<version_number>
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

## Workaround to open sqlcipher on old Android versions.

On old Android versions, this method can help if you're having issues opening sqlite3 (e.g. if you're seeing crashes about libsqlcipher.so not being available). To be safe, call this method before using apis from package:sqlite3 or package:moor/ffi.dart.

```dart
Future<void> setupSqlCipher() async {
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
}
```

Declared in `package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart`.

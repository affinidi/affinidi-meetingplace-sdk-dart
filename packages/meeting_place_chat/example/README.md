## Chat SDK Examples

Check the sample code to learn how to use Affinidi Meeting Place - Chat SDK package to enable chatting with others using Decentralised Identifiers (DIDs) and the DIDComm v2.1 protocol.

| File path | What it demonstrates |
|------|----------------------|
| chat/alice.dart| Publishes connection offer (invitation) and initialises individual chat.|
| chat/bob.dart | Finds and accepts the connection offer, initialises individual chat. |
| group_chat/alice.dart | Publishes connection offer, approves connection request and initialises group chat. |
| group_chat/bob.dart | Finds and accepts the connection offer, initialises the group chat after group owner approves connection request. Sends the message. |
| group_chat/charlie.dart | Finds and accepts the connection offer, initialises the group chat after group owner approves connection request. Receives message on chat stream and sends message back. |

### Running the Examples

Execute the example Dart scripts from the `packages/meeting_place_chat/example` folder. To run them, you need to provide environment variables for `CONTROL_PLANE_DID` and `MEDIATOR_DID`. The examples use the [dotenv](https://pub.dev/packages/dotenv) package to load these values from a local `.env` file for convenience.

1. **Create your local environment file**

   Run this command in your terminal to copy the template and create `.env` in the root of the `example` folder:

   ```bash
   cp templates/.example.env .env
   ```

   Edit `.env` and update the values for `CONTROL_PLANE_DID` and `MEDIATOR_DID` to match your test environment.

2. **Run the example scripts**

   You can now run the examples directly using Dart:

   ```bash
   # Chat example
   dart run chat/alice.dart
   dart run chat/bob.dart
   ```

   ```bash
   # Group chat example
   dart run group_chat/alice.dart
   dart run group_chat/bob.dart
   dart run group_chat/charlie.dart
   ```

   The example utilities will automatically load variables from `.env` in the root of the example folder.

**Notes:**

- The `.env` file should be placed in the root of the example folder as `.env`.
- The template file is provided at `templates/.example.env` for convenience.
- If `.env` is missing, the code will fall back to environment variables from the platform (useful for CI or manual export).

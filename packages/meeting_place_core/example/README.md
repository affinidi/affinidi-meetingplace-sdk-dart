## Core SDK Examples

Check the sample code to learn how to use the Affinidi Meeting Place - Core
SDK package to discover, connect, and communicate with others using
Decentralised Identifiers (DIDs), DIDComm v2.1, and Matrix.

| File path | What it demonstrates |
|------|----------------------|
| group_matrix/alice.dart | Publishes a group offer, provisions the owner Matrix user via JWT login, creates the shared Matrix room, receives the joining member, and sends a Matrix text message after approval. |
| group_matrix/bob.dart | Finds and accepts the group offer, provisions the member Matrix user via JWT login, receives the shared room ID over DIDComm, joins the room after approval, and sends a Matrix text message. |
| offer/alice.dart | Publishes connection offer (invitation) and approve connection request after the offer was accepted. initialises the chat. |
| offer/bob.dart | Finds and accepts the connection offer, sends notification about acceptance of the connection request. initialises the chat. |
| oob/alice.dart | Creates an out-of-band flow and waits for the other party to connect. |
| oob/bob.dart | Accepts the out-of-band flow shared by Alice. |
| outreach/alice.dart | Publishes an outreach invitation. |
| outreach/bob.dart | Finds and accepts the outreach invitation. |

### Running the Examples

Execute the example Dart scripts from the
`packages/meeting_place_core/example` folder. To run them, you need to
provide environment variables for `CONTROL_PLANE_DID`, `MEDIATOR_DID`, and
`MATRIX_HOMESERVER`. The examples use the
[dotenv](https://pub.dev/packages/dotenv) package to load these values from a
local `.env` file for convenience.

1. **Create your local environment file**

   Run this command in your terminal to copy the template and create `.env` in the root of the `example` folder:

   ```bash
   cp templates/.example.env .env
   ```

   Edit `.env` and update the values for `CONTROL_PLANE_DID`,
   `MEDIATOR_DID`, and `MATRIX_HOMESERVER` to match your test environment.

2. **Run the example scripts**

   You can now run the examples directly using Dart:

   ```bash
    # Offer example
    dart run offer/alice.dart
    dart run offer/bob.dart
    ```

    ```bash
    # OOB example
   dart run oob/alice.dart
   dart run oob/bob.dart
    ```

    ```bash
    # Group Matrix example
    dart run group_matrix/alice.dart
    dart run group_matrix/bob.dart
    ```

    ```bash
    # Outreach example
    dart run outreach/alice.dart
    dart run outreach/bob.dart
    ```

   The example utilities will automatically load variables from `.env` in the root of the example folder.

**Notes:**

- The `.env` file should be placed in the root of the example folder as `.env`.
- The template file is provided at `templates/.example.env` for convenience.
- If `.env` is missing, the code will fall back to environment variables from the platform (useful for CI or manual export).

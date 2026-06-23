## Core SDK Examples

Check the sample code to learn how to use the Affinidi Meeting Place - Core
SDK package to discover, connect, and communicate with others using
Decentralised Identifiers (DIDs), DIDComm v2.1, and Matrix.

| File path | What it demonstrates |
|------|----------------------|
| group/alice.dart | Publishes a group offer, provisions the owner Matrix user via JWT login, creates the shared Matrix room, and receives the joining member before approval. |
| group/bob.dart | Finds and accepts the group offer, provisions the member Matrix user via JWT login, receives the shared room ID over DIDComm, and joins the room after approval. |
| offer/alice.dart | Publishes connection offer (invitation) and approve connection request after the offer was accepted. initialises the chat. |
| offer/bob.dart | Finds and accepts the connection offer, sends notification about acceptance of the connection request. initialises the chat. |
| oob/alice.dart | Creates an out-of-band flow and waits for the other party to connect. |
| oob/bob.dart | Accepts the out-of-band flow shared by Alice. |
| outreach/alice.dart | Publishes an outreach invitation. |
| outreach/bob.dart | Finds and accepts the outreach invitation. |
| media/alice.dart | Publishes a connection offer, approves Bob's request, and once the channel is inaugurated sends a small file as a media message on the resulting Matrix channel. |
| media/bob.dart | Accepts Alice's offer, waits for the offer-finalised event (which joins the Matrix room), then downloads the media she posted using `MatrixEventMediaReference`. |

### Running the Examples

Execute the example Dart scripts from the
`packages/meeting_place_core/example` folder. To run them, you need to
provide environment variables for `CONTROL_PLANE_DID`, `MEDIATOR_DID`,
`MATRIX_HOMESERVER`, and `VODOZEMAC_LIBRARY_PATH`. The examples use the
[dotenv](https://pub.dev/packages/dotenv) package to load these values from a
local `.env` file for convenience.

1. **Create your local environment file**

   Run this command in your terminal to copy the template and create `.env` in the root of the `example` folder:

   ```bash
   cp templates/.example.env .env
   ```

   Edit `.env` and update the values for `CONTROL_PLANE_DID`,
   `MEDIATOR_DID`, `MATRIX_HOMESERVER`, and `VODOZEMAC_LIBRARY_PATH`
   to match your test environment.

   `VODOZEMAC_LIBRARY_PATH` must point to the directory containing your
   compiled vodozemac native library.

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
     # Group example
     dart run group/alice.dart
     dart run group/bob.dart
    ```

    ```bash
    # Outreach example
    dart run outreach/alice.dart
    dart run outreach/bob.dart
    ```

    ```bash
    # Media example (run after the OOB flow completes)
    dart run media/alice.dart
    dart run media/bob.dart
    ```

   The example utilities will automatically load variables from `.env` in the root of the example folder.

**Notes:**

- The `.env` file should be placed in the root of the example folder as `.env`.
- The template file is provided at `templates/.example.env` for convenience.
- If `.env` is missing, the code will fall back to environment variables from the platform (useful for CI or manual export).

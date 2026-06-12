# meeting_place_credentials examples

Check the sample code to learn how to use the Affinidi Meeting Place - Credentials SDK package to exchange R-Cards and Verifiable Relationship Credentials (VRCs) with peers over DIDComm v2.

| File path                | What it demonstrates                                                                                                         |
| ------------------------ | ---------------------------------------------------------------------------------------------------------------------------- |
| `credentials/alice.dart` | Publishes a connection offer, approves Bob's request, sends an R-Card, initiates a VRC exchange, and reciprocates Bob's VRC. |
| `credentials/bob.dart`   | Finds and accepts Alice's offer, sends an R-Card, and responds to Alice's VRC request.                                       |
| `r_card/alice.dart`      | Builds and signs a standalone R-Card VC using `CredentialBuilder.buildRCard`. Writes the blob for Bob to read.               |
| `r_card/bob.dart`        | Parses and inspects a received R-Card blob using `RCardSubject.fromVcBlob`.                                                  |
| `vrc/alice.dart`         | Builds and signs a standalone VRC using `CredentialBuilder.buildVrc`. Writes the blob for Bob to read.                       |
| `vrc/bob.dart`           | Parses Alice's VRC using `VrcCredentialSubject.fromVcBlob` and issues a reciprocal VRC.                                      |

### Running the Examples

Execute the example Dart scripts from the `packages/meeting_place_credentials/example` folder. The wired examples (`credentials/`) require environment variables for `CONTROL_PLANE_DID` and `MEDIATOR_DID`. The examples use the [dotenv](https://pub.dev/packages/dotenv) package to load these values from a local `.env` file for convenience.

1. **Create your local environment file**

   Run this command in your terminal to copy the template and create `.env` in the root of the `example` folder:

   ```bash
   cp templates/.example.env .env
   ```

   Edit `.env` and update the values for `CONTROL_PLANE_DID` and `MEDIATOR_DID` to match your test environment.

2. **Run the example scripts**

   You can now run the examples directly using Dart:

   ```bash
   # Wired credentials example (run in two separate terminals simultaneously)
   dart run credentials/alice.dart
   dart run credentials/bob.dart
   ```

   Alice writes a mnemonic to `.example-output/credentials-storage.txt` and waits. Start Bob once Alice is waiting.

   ```bash
   # Standalone R-Card example (no live connection required)
   dart run r_card/alice.dart
   dart run r_card/bob.dart
   ```

   ```bash
   # Standalone VRC example (no live connection required)
   dart run vrc/alice.dart
   dart run vrc/bob.dart
   ```

   The example utilities will automatically load variables from `.env` in the root of the example folder.

**Notes:**

- The `.env` file should be placed in the root of the example folder as `.env`.
- The template file is provided at `templates/.example.env` for convenience.
- If `.env` is missing, the code will fall back to environment variables from the platform (useful for CI or manual export).
- The `r_card/` and `vrc/` standalone examples do not require `.env` — they use an in-memory wallet and write output to `.example-output/`.
- Scripts that produce files write them to `.example-output/` (git-ignored). Run Alice before Bob in each pair.

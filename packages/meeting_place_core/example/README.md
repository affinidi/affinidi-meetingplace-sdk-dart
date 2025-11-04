## Core SDK Examples

Check the sample code to learn how to use the Affinidi Meeting Place - Core SDK package to discover, connect, and communicate with others using Decentralised Identifiers (DIDs) and the DIDComm v2.1 protocol.

| File path | What it demonstrates |
|------|----------------------|
| chat/alice.dart| Publishes connection offer and initializes individual chat.|
| chat/bob.dart | Finds and accepts the connection offer, initializes individual chat. |
| group_chat/alice.dart | Publishes connection offer, approves connection request and initializes group chat. |
| group_chat/bob.dart | Finds and accepts the connection offer, initializes the group chat after group owner approves connection request. Sends the message. |
| group_chat/charlie.dart | Finds and accepts the connection offer, initializes the group chat after group owner approves connection request. Receives message on chat stream and sends message back. |
| offer/alice.dart | Publishes connection offer and approve connection request after the offer was accepted. Initializes the chat. |
| offer/bob.dart | Finds and accepts the connection offer, sends notification about acceptance of the connection request. Initializes the chat. |

### Running the Examples

Execute the example Dart script from the packages/meeting_place_core/examples folder:

```
# Offer example
dart run offer/alice.dart
dart run offer/bob.dart
```

```
# OOB example
dart run oob/alice.dart
dart run oob/bob.dart
```

```
# Outreach example
dart run outreach/bob.dart
dart run outreach/bob.dart
```

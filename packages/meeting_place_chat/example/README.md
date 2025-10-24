## MPX_SDK Examples

Check the sample code to learn how to use Meeting Place Chat package to enable chatting with others using Decentralised Identifiers (DIDs) and DIDComm v2.1 protocol.

| File path | What it demonstrates |
|------|----------------------|
| chat/alice.dart| Publishes connection offer and initializes individual chat.|
| chat/bob.dart | Finds and accepts the connection offer, initializes individual chat. |
| group_chat/alice.dart | Publishes connection offer, approves connection request and initializes group chat. |
| group_chat/bob.dart | Finds and accepts the connection offer, initializes the group chat after group owner approves connection request. Sends the message. |
| group_chat/charlie.dart | Finds and accepts the connection offer, initializes the group chat after group owner approves connection request. Receives message on chat stream and sends message back. |

### Running the Examples

Execute the example Dart script from the packages/meeting_place_chat/examples folder:

```
# Chat example
dart run chat/alice.dart
dart run chat/bob.dart
```

```
# Group chat example
dart run group_chat/alice.dart
dart run group_chat/bob.dart
dart run group_chat/charlie.dart
```

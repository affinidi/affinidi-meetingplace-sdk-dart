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

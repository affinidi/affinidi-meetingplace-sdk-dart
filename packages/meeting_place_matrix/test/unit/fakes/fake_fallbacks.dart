import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_core/meeting_place_core.dart'
    show Channel, DidManager, OutgoingMessage;
import 'package:meeting_place_matrix/src/meeting_place_livekit_call_plugin.dart'
    show LiveKitRoomFactory;
import 'package:mocktail/mocktail.dart';

import 'fake_livekit_service.dart';

class FakeDidManager extends Fake implements DidManager {}

class FakeChannel extends Fake implements Channel {}

class FakeOutgoingMessage extends Fake implements OutgoingMessage {}

class FakeOpenIdCredentials extends Fake implements matrix.OpenIdCredentials {}

class FakeWebRTCDelegate extends Fake implements matrix.WebRTCDelegate {}

LiveKitRoomFactory fakeLiveKitRoomFactory() =>
    (String _) => FakeLiveKitRoom();

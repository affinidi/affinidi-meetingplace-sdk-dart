import 'package:matrix/matrix.dart' show OpenIdCredentials;
import 'package:meeting_place_core/meeting_place_core.dart'
    show Channel, DidManager, OutgoingMessage, WebRTCDelegate;
import 'package:mocktail/mocktail.dart';

class FakeDidManager extends Fake implements DidManager {}

class FakeChannel extends Fake implements Channel {}

class FakeOutgoingMessage extends Fake implements OutgoingMessage {}

class FakeOpenIdCredentials extends Fake implements OpenIdCredentials {}

class FakeWebRTCDelegate extends Fake implements WebRTCDelegate {}

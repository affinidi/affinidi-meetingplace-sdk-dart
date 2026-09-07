import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:mocktail/mocktail.dart';

class FakeFinaliseAcceptanceRequest extends Fake
    implements FinaliseAcceptanceRequest {}

class FakeGetOobRequest extends Fake implements GetOobRequest {}

class FakeGroupAddMemberRequest extends Fake implements GroupAddMemberRequest {}

class FakeGroupNotifyChannelRequest extends Fake
    implements GroupNotifyChannelRequest {}

class FakeNotifyChannelRequest extends Fake implements NotifyChannelRequest {}

class FakeRegisterNotificationRequest extends Fake
    implements RegisterNotificationRequest {}

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/identity/identity_service.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';

class MockMediatorService extends Mock implements MediatorService {}

class MockDidManager extends Mock implements DidManager {
  MockDidManager({required this.did});

  final String did;

  @override
  Future<DidDocument> getDidDocument() async {
    return DidDocument.create(id: did);
  }
}

class MockWallet extends Mock implements Wallet {}

class MockControlPlaneSDK extends Mock implements ControlPlaneSDK {}

class MockIdentityService extends Mock implements IdentityService {}

class MockMeetingPlaceTransport extends Mock implements MeetingPlaceTransport {}

class MockDidResolver extends Mock implements DidResolver {}

class MockChannelService extends Mock implements ChannelService {}

class MockConnectionOfferRepository extends Mock
    implements ConnectionOfferRepository {}

class MockConnectionManager extends Mock implements ConnectionManager {}

class MockLogger extends Mock implements MeetingPlaceCoreSDKLogger {}

class MockVdipClient extends Mock implements VdipClient {}

class MockChannelRepository extends Mock implements ChannelRepository {}

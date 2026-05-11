import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_core/src/loggers/meeting_place_core_sdk_logger.dart';
import 'package:meeting_place_core/src/repository/connection_offer_repository.dart';
import 'package:meeting_place_core/src/service/channel/channel_service.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_service.dart';
import 'package:meeting_place_core/src/vdip/vdip_client.dart';
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

class MockConnectionOfferRepository extends Mock
    implements ConnectionOfferRepository {}

class MockChannelService extends Mock implements ChannelService {}

class MockConnectionManager extends Mock implements ConnectionManager {}

class MockLogger extends Mock implements MeetingPlaceCoreSDKLogger {}

class MockVdipClient extends Mock implements VdipClient {}

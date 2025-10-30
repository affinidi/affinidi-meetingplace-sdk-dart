import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
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

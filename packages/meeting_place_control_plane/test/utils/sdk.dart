import 'dart:io';

import 'package:meeting_place_control_plane/src/control_plane_sdk.dart';
import 'package:ssi/ssi.dart';

Future<ControlPlaneSDK> initSDKInstance() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(
    wallet: wallet,
    store: InMemoryDidStore(),
  );

  await didManager.addVerificationMethod(
    (await wallet.generateKey()).id,
  );

  return ControlPlaneSDK(
    didManager: didManager,
    controlPlaneDid: getControlPlaneDid(),
    mediatorDid: getMediatorDid(),
    didResolver: UniversalDIDResolver(),
  );
}

String getControlPlaneDid() =>
    Platform.environment['CONTROL_PLANE_DID'] ??
    (throw Exception('CONTROL_PLANE_DID not set in environment'));

String getMediatorDid() =>
    Platform.environment['MEDIATOR_DID'] ??
    (throw Exception('MEDIATOR_DID not set in environment'));

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

void main() async {
  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());

  final keyPair = await wallet.generateKey();
  await didManager.addVerificationMethod(keyPair.id);

  final controlPlaneSDK = ControlPlaneSDK(
    didManager: didManager,
    controlPlaneDid: '',
    mediatorDid: '',
    didResolver: UniversalDIDResolver(),
  );

  // ignore: avoid_print
  print(controlPlaneSDK.hashCode);
}

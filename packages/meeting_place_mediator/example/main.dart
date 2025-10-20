import 'package:meeting_place_mediator/src/mediator_sdk.dart';
import 'package:ssi/ssi.dart';

void main() {
  final mediatorDid = '';

  final mediatorSDK = MediatorSDK(
    mediatorDid: mediatorDid,
    didResolver: UniversalDIDResolver(),
  );

  // ignore: avoid_print
  print(mediatorSDK.hashCode);
}

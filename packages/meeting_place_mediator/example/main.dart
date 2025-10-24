import 'package:meeting_place_mediator/src/meeting_place_mediator_sdk.dart';
import 'package:ssi/ssi.dart';

void main() {
  final mediatorDid = '';

  final mediatorSDK = MeetingPlaceMediatorSDK(
    mediatorDid: mediatorDid,
    didResolver: UniversalDIDResolver(),
  );

  // ignore: avoid_print
  print(mediatorSDK.hashCode);
}

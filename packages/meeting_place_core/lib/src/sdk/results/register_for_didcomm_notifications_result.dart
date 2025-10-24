import '../../../meeting_place_core.dart';

class RegisterForDidcommNotificationsResult {
  RegisterForDidcommNotificationsResult({
    required this.recipientDid,
    required this.device,
  });
  final DidManager recipientDid;
  final Device device;
}

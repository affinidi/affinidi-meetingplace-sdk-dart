import '../../../meeting_place_core.dart';

class RegisterForDidcommNotificationsResult {
  RegisterForDidcommNotificationsResult({
    required this.recipientDidManager,
    required this.device,
  });
  final DidManager recipientDidManager;
  final Device device;
}

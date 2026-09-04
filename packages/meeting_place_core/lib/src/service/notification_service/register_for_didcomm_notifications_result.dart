import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:ssi/ssi.dart';

class RegisterForDidcommNotificationsResult {
  RegisterForDidcommNotificationsResult({
    required this.recipientDidManager,
    required this.device,
  });

  final DidManager recipientDidManager;
  final Device device;
}

import '../../../meeting_place_core.dart';

/// The result of registering for DIDComm notifications via the mediator.
class RegisterForDidcommNotificationsResult {
  /// Creates a [RegisterForDidcommNotificationsResult].
  RegisterForDidcommNotificationsResult({
    required this.recipientDidManager,
    required this.device,
  });

  /// The DID manager for the DID registered to receive notifications.
  final DidManager recipientDidManager;

  /// The device registered to receive the notifications.
  final Device device;
}

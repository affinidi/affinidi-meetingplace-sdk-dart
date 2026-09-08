import '../../core/command/command.dart';
import 'authenticate_result.dart';

/// Model that represents the request sent for the [AuthenticateRequest]
/// operation.
class AuthenticateRequest extends DiscoveryCommand<AuthenticateResult> {
  /// Creates a new instance of [AuthenticateRequest] with the given
  /// [controlPlaneDid], the control plane DID string.
  AuthenticateRequest({required this.controlPlaneDid});

  /// The DID used to authenticate with the control plane.
  final String controlPlaneDid;
}

import '../../core/command/command.dart';
import 'authenticate_output.dart';

/// Model that represents the request sent for the [AuthenticateCommand]
/// operation.
class AuthenticateCommand extends DiscoveryCommand<AuthenticateCommandOutput> {
  /// Creates a new instance of [AuthenticateCommand] with the given
  /// [controlPlaneDid], the control plane DID string.
  AuthenticateCommand({required this.controlPlaneDid});

  /// The DID used to authenticate with the control plane.
  final String controlPlaneDid;
}

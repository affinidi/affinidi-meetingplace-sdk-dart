import '../../core/command/command.dart';
import 'authenticate_output.dart';

/// Model that represents the request sent for the [AuthenticateCommand]
/// operation.
class AuthenticateCommand extends DiscoveryCommand<AuthenticateCommandOutput> {
  /// Creates a new instance of [AuthenticateCommand].
  ///
  /// **Paramaeters:**
  /// - [controlPlaneDid]: The control plane DID string.
  ///
  /// **Returns:**
  /// - AuthenticateCommand instance.
  AuthenticateCommand({required this.controlPlaneDid});
  final String controlPlaneDid;
}

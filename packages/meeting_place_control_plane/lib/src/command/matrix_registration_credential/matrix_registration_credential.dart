import '../../core/command/command.dart';
import 'matrix_registration_credential_output.dart';

/// Fetches a long-lived Matrix registration permission JWT from Control Plane.
///
/// This is used to register Matrix users/devices against a configured homeserver.
class MatrixRegistrationCredentialCommand
    extends DiscoveryCommand<MatrixRegistrationCredentialCommandOutput> {
  MatrixRegistrationCredentialCommand({required this.homeserver});

  /// Matrix homeserver host (e.g. `matrix.example.com`).
  final String homeserver;
}

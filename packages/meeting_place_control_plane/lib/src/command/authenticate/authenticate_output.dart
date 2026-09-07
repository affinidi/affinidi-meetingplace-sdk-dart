import '../../api/auth_credentials.dart';
import 'authenticate.dart' show AuthenticateRequest;

/// Model that represents the output data returned from a successful execution
/// of [AuthenticateRequest] operation.
class AuthenticateCommandOutput {
  /// Creates a new instance of [AuthenticateCommandOutput].
  AuthenticateCommandOutput({required this.credentials});

  /// The credentials obtained from a successful authentication.
  final AuthCredentials credentials;
}

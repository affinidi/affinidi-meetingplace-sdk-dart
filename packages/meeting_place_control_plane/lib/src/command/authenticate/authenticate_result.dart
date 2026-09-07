import '../../api/auth_credentials.dart';
import 'authenticate_request.dart' show AuthenticateRequest;

/// Model that represents the output data returned from a successful execution
/// of [AuthenticateRequest] operation.
class AuthenticateResult {
  /// Creates a new instance of [AuthenticateResult].
  AuthenticateResult({required this.credentials});

  /// The credentials obtained from a successful authentication.
  final AuthCredentials credentials;
}

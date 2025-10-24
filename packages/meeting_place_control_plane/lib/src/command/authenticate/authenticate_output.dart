import '../../api/auth_credentials.dart';

/// Model that represents the output data returned from a successful execution
/// of [AuthenticateCommandOutput] operation.
class AuthenticateCommandOutput {
  /// Creates a new instance of [AuthenticateCommandOutput].
  AuthenticateCommandOutput({required this.credentials});
  final AuthCredentials credentials;
}

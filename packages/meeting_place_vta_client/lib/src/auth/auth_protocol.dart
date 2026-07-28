import '../models/session_info.dart';
import '../models/vta_authenticate_result.dart';
import 'auth_models.dart';

enum VtaProofRequirement { none, required }

abstract class VtaAuthSigner {
  const VtaAuthSigner();

  Future<Map<String, dynamic>> createProof({
    required Map<String, dynamic> trustTask,
    required String operation,
  });
}

class VtaNoopAuthSigner implements VtaAuthSigner {
  const VtaNoopAuthSigner();

  @override
  Future<Map<String, dynamic>> createProof({
    required Map<String, dynamic> trustTask,
    required String operation,
  }) {
    throw UnsupportedError(
      'A signer is required for $operation trust-task documents.',
    );
  }
}

/// Protocol engine that serializes/deserializes trust-task auth documents.
abstract class VtaAuthProtocol {
  Future<String> buildAuthenticateDocument(VtaAuthenticateRequest request);

  Future<VtaAuthenticateResult> parseAuthenticateResponse(String responseBody);

  Future<String> buildRefreshDocument(VtaRefreshRequest request);

  Future<VtaAuthenticateResult> parseRefreshResponse(String responseBody);

  Future<String> buildWhoAmIDocument(VtaWhoAmIRequest request);

  Future<SessionInfo> parseWhoAmIResponse(String responseBody);
}

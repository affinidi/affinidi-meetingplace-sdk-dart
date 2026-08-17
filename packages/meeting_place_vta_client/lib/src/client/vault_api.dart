import 'vta_client.dart';

class VtaVaultApi {
  VtaVaultApi({required VtaClient client}) : _client = client;

  final VtaClient _client;

  /// Lists vault entry metadata (no secrets). Requires the `VaultRead`
  /// capability (admin role on the caller's ACL entry).
  Future<Map<String, dynamic>> listEntries() => _client.postJson(
    '/api/trust-tasks',
    body: <String, dynamic>{
      'id': 'urn:uuid:${DateTime.now().millisecondsSinceEpoch}',
      'type': 'https://trusttasks.org/spec/vault/list/0.1',
      'payload': <String, dynamic>{},
    },
  );
}

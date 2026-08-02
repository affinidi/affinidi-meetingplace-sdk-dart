import 'vta_client.dart';

class VtaStepUpPolicyApi {
  VtaStepUpPolicyApi({required VtaClient client}) : _client = client;

  final VtaClient _client;

  Future<Map<String, dynamic>> getPolicy() =>
      _client.getJson('/step-up/policy');

  Future<Map<String, dynamic>> setPolicy({
    required bool enabled,
    List<Map<String, dynamic>> floors = const [],
  }) => _client.putJson(
    '/step-up/policy',
    body: {'enabled': enabled, 'floors': floors},
  );
}

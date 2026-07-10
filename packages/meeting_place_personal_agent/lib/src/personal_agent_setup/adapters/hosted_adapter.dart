import 'package:vta_dart_client/vta_dart_client.dart';

import '../models.dart';
import 'adapter.dart';

class RestPersonalAgentSetupRemote implements PersonalAgentSetupRemote {
  const RestPersonalAgentSetupRemote({
    required this.client,
    this.endpoint = '/personal-agent/setup',
  });

  final VtaClient client;
  final String endpoint;

  @override
  Future<Map<String, dynamic>> ensurePersonalAgentSetup({
    required PersonalAgentSetupRequest request,
  }) {
    return client.postJson(endpoint, body: request.toJson());
  }

  @override
  Future<Map<String, dynamic>> fetchPersonalAgentOffer({
    required String setupId,
  }) {
    final normalizedBase = endpoint.endsWith('/setup')
        ? endpoint
        : '$endpoint/setup';
    final encodedSetupId = Uri.encodeComponent(setupId);
    return client.getJson('$normalizedBase/$encodedSetupId/offer');
  }

  @override
  Future<Map<String, dynamic>> uploadPersonalAgentContext({
    required String setupId,
    required String content,
  }) {
    final normalizedBase = endpoint.endsWith('/setup')
        ? endpoint
        : '$endpoint/setup';
    final encodedSetupId = Uri.encodeComponent(setupId);
    return client.postJson(
      '$normalizedBase/$encodedSetupId/context',
      body: {'content': content},
    );
  }

  @override
  Future<Map<String, dynamic>> fetchPersonalAgentContextStatus({
    required String setupId,
  }) {
    final normalizedBase = endpoint.endsWith('/setup')
        ? endpoint
        : '$endpoint/setup';
    final encodedSetupId = Uri.encodeComponent(setupId);
    return client.getJson('$normalizedBase/$encodedSetupId/context/status');
  }
}

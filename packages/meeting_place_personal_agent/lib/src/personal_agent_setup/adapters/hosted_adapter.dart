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

  String get _setupBase =>
      endpoint.endsWith('/setup') ? endpoint : '$endpoint/setup';

  String _setupResourcePath(String setupId, String suffix) {
    final encodedSetupId = Uri.encodeComponent(setupId);
    return '$_setupBase/$encodedSetupId$suffix';
  }

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
    return client.getJson(_setupResourcePath(setupId, '/offer'));
  }

  @override
  Future<Map<String, dynamic>> uploadPersonalAgentContext({
    required String setupId,
    required String content,
    String? contextKey,
  }) {
    final normalizedContextKey = contextKey?.trim();
    return client.postJson(
      _setupResourcePath(setupId, '/context'),
      body: {
        'content': content,
        if (normalizedContextKey != null && normalizedContextKey.isNotEmpty)
          'context_key': normalizedContextKey,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> fetchPersonalAgentContextStatus({
    required String setupId,
  }) {
    return client.getJson(_setupResourcePath(setupId, '/context/status'));
  }

  @override
  Future<Map<String, dynamic>> fetchPersonalAgentAuthorizationSnapshot({
    required String setupId,
  }) {
    return client.getJson(_setupResourcePath(setupId, '/authorization'));
  }
}

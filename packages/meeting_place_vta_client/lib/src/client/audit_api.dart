import 'vta_client.dart';

class VtaAuditApi {
  VtaAuditApi({required this._client});

  final VtaClient _client;

  Future<Map<String, dynamic>> listLogs({
    String? action,
    String? actor,
    String? outcome,
    String? contextId,
    int? from,
    int? to,
    int page = 1,
    int pageSize = 50,
  }) => _client.getJson(
    '/audit/logs',
    queryParameters: {
      if (action != null) 'action': action,
      if (actor != null) 'actor': actor,
      if (outcome != null) 'outcome': outcome,
      if (contextId != null) 'context_id': contextId,
      if (from != null) 'from': from.toString(),
      if (to != null) 'to': to.toString(),
      'page': page.toString(),
      'page_size': pageSize.toString(),
    },
  );
}

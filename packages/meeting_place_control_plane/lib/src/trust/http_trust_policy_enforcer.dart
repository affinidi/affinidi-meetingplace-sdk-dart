import 'package:dio/dio.dart';

import 'trust_authorization_request.dart';
import 'trust_policy_denied_exception.dart';
import 'trust_policy_enforcer.dart';

class HttpTrustPolicyEnforcer implements TrustPolicyEnforcer {
  HttpTrustPolicyEnforcer({
    required Dio dio,
    required String baseUrl,
    this.endpointPath = '/v1/authorize',
    this.onBeforeRequest,
  }) : _dio = dio,
       _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;
  final String endpointPath;
  final Future<void> Function(RequestOptions options)? onBeforeRequest;

  @override
  Future<void> enforceOrThrow(TrustAuthorizationRequest request) async {
    final url = '$_baseUrl$endpointPath';
    final options = Options(headers: {'content-type': 'application/json'});
    final requestOptions = RequestOptions(path: url);
    if (onBeforeRequest != null) {
      await onBeforeRequest!(requestOptions);
      options.headers?.addAll(requestOptions.headers);
    }

    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: request.toJson(),
      options: options,
    );

    final body = response.data ?? const <String, dynamic>{};
    final allowed = body['allow'] == true || body['allowed'] == true;
    if (!allowed) {
      throw TrustPolicyDeniedException(
        action: request.action.name,
        groupId: request.groupId,
      );
    }
  }
}

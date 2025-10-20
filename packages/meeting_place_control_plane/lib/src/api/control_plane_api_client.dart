import 'package:collection/collection.dart';
import 'package:dio/dio.dart';
import '../constants/sdk_constants.dart';
import 'api_client.dart' as api_client;
import 'package:ssi/ssi.dart';

import '../../meeting_place_control_plane.dart';
import 'control_plane_api_client_options.dart';
import 'refresh_auth_credentials_interceptor.dart';
import 'retry_interceptor.dart';

/// A class that is used to handle the API calls for [ControlPlaneSDK] using [Dio].
class ControlPlaneApiClient {
  /// Create an instance of the [ControlPlaneApiClient] class.
  ///
  /// This also creates the instance of [ControlPlaneApiClient] class.
  ControlPlaneApiClient._({
    required Dio dio,
    required String basePath,
    required ControlPlaneSDK controlPlaneSDK,
    required String controlPlaneDid,
    required ControlPlaneSDKLogger logger,
  })  : _mpxClient = api_client.ControlPlaneApi(
          basePath: basePath,
          dio: dio,
          interceptors: [
            api_client.ApiKeyAuthInterceptor(),
            RefreshAuthCredentialsInterceptor(
              dio: dio,
              controlPlaneSDK: controlPlaneSDK,
              controlPlaneDid: controlPlaneDid,
              logger: logger,
            ),
          ],
        ),
        _logger = logger;
  static final String _apiKeyName = 'DidCommTokenAuth';
  static const String _className = 'DiscoveryApiClient';

  final api_client.ControlPlaneApi _mpxClient;
  final ControlPlaneSDKLogger _logger;

  api_client.DefaultApi get client => _mpxClient.getDefaultApi();

  /// Creates and initializes an instance of [ControlPlaneApiClient].
  ///
  /// This static method sets up all necessary member variables and configurations
  /// required for a fully functional [ControlPlaneApiClient] instance.
  static Future<ControlPlaneApiClient> init({
    required ControlPlaneApiClientOptions options,
    required ControlPlaneSDK controlPlaneSDK,
    DidResolver? didResolver,
    ControlPlaneSDKLogger? logger,
  }) async {
    final methodName = 'init';
    final effectiveLogger = logger ??
        DefaultControlPlaneSDKLogger(className: _className, sdkName: sdkName);

    effectiveLogger.info(
      'Started initializing DiscoveryApiClient with options: ${options.toJson()}',
      name: methodName,
    );

    final basePath = await _getApiBasePath(
      options.controlPlaneDid,
      didResolver ?? UniversalDIDResolver(),
    );

    final dio = Dio(
      BaseOptions(
        baseUrl: basePath,
        connectTimeout: options.connectTimeout,
        receiveTimeout: options.receiveTimeout,
      ),
    );

    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        maxRetries: options.maxRetries,
        retryDelay: options.maxRetriesDelay,
      ),
    );

    effectiveLogger.info(
      'Completed initializing DiscoveryApiClient with basePath: $basePath',
      name: methodName,
    );
    return ControlPlaneApiClient._(
      dio: dio,
      basePath: basePath,
      controlPlaneDid: options.controlPlaneDid,
      controlPlaneSDK: controlPlaneSDK,
      logger: effectiveLogger,
    );
  }

  void setApiKey(String apiKey) {
    final methodName = 'setApiKey';
    _logger.info('Setting API key for $_apiKeyName', name: methodName);
    _mpxClient.setApiKey(_apiKeyName, apiKey);
  }

  /// A method used to fetch the base api path.
  ///
  /// **Parameters:**
  /// - [controlPlaneDid]: The control plane DID string.
  /// - [didResolver]: THe didResolver object.
  ///
  /// **Returns:**
  /// - [apiBasePath]: the base api path as string.
  static Future<String> _getApiBasePath(
    String controlPlaneDid,
    DidResolver didResolver,
  ) async {
    final didDocument = await didResolver.resolveDid(controlPlaneDid);
    final apiBasePath = didDocument.service.firstWhereOrNull(
      (service) => service.type == 'RestAPI',
    );

    if (apiBasePath == null) {
      return didDocument.id.replaceAll('did:web:', 'https://');
    }

    final url = (apiBasePath.serviceEndpoint as StringEndpoint).url;
    return url.replaceFirst('/v1', '');
  }
}

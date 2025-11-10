import 'package:dio/dio.dart';

import '../../api/retry_interceptor.dart';
import '../../constants/sdk_constants.dart';
import '../../loggers/default_meeting_place_mediator_sdk_logger.dart';
import '../../loggers/meeting_place_mediator_sdk_logger.dart';
import 'mediator_exception.dart';

/// The [MediatorResolver] is responsible for turning external
/// references (such as URLs) into usable mediator identifiers
/// or metadata.
class MediatorResolver {
  MediatorResolver({MeetingPlaceMediatorSDKLogger? logger, Dio? dio})
      : _logger = logger ??
            DefaultMeetingPlaceMediatorSDKLogger(
                className: _className, sdkName: sdkName),
        _dio = dio ??
            (() {
              final baseDio = Dio(
                BaseOptions(
                  connectTimeout: const Duration(seconds: 10),
                  receiveTimeout: const Duration(seconds: 10),
                ),
              );
              baseDio.interceptors.add(RetryInterceptor(dio: baseDio));
              return baseDio;
            }());
  static const String _className = 'MediatorResolver';

  final MeetingPlaceMediatorSDKLogger _logger;
  final Dio _dio;

  /// Resolves the mediator DID from a given [mediatorEndpoint].
  ///
  /// Performs an HTTP GET request to `/.well-known/did.json` at the
  /// provided endpoint and extracts the DID value from the response.
  ///
  /// [mediatorEndpoint] - The base URL of the mediator service.
  /// Trailing slashes are automatically removed.
  ///
  /// Returns the mediator DID as a [String].
  ///
  /// Throws a [MediatorException.getMediatorDidError] if the
  /// request fails or returns an invalid response.
  Future<String?> getMediatorDidFromUrl(String mediatorEndpoint) async {
    final methodName = 'getMediatorDidFromUrl';
    _logger.info(
      'Started resolving mediator DID from endpoint: $mediatorEndpoint',
      name: methodName,
    );
    if (mediatorEndpoint.endsWith('/')) {
      mediatorEndpoint = mediatorEndpoint.substring(
        0,
        mediatorEndpoint.length - 1,
      );
    }

    final didUrl = mediatorEndpoint.endsWith('.well-known/did.json')
        ? mediatorEndpoint
        : '$mediatorEndpoint/.well-known/did.json';

    try {
      final response = await _dio.get(
        didUrl,
        options: Options(headers: {'CONTENT-TYPE': 'application/json'}),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('id')) {
          final mediatorDid = data['id'] as String;
          _logger.info(
            'Completed resolving Mediator DID from DID Document: $mediatorDid',
          );
          return mediatorDid;
        }

        if (data.containsKey('data')) {
          final mediatorDid = data['data'] as String;
          _logger.info(
            'Completed resolving Mediator DID from wrapper: $mediatorDid',
          );
          return mediatorDid;
        }
      }
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to resolve DID from $mediatorEndpoint: ',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );

      Error.throwWithStackTrace(
        MediatorException.getMediatorDidError(
          mediatorEndpoint: mediatorEndpoint,
          innerException: e,
        ),
        stackTrace,
      );
    }

    _logger.warning(
      'Invalid response format when resolving DID from $mediatorEndpoint',
      name: methodName,
    );
    return null;
  }
}

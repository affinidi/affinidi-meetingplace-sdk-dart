import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/plugin_logger_provider.dart';
import '../providers/plugin_options_provider.dart';
import '../services/sfu_token_service.dart';

part 'sfu_token_service_provider.g.dart';

/// [SfuTokenService] instance for the current plugin session.
///
/// Override in tests to return a mock without making real HTTP requests.
@riverpod
SfuTokenService sfuTokenService(Ref ref) {
  return SfuTokenService(
    serviceUrl: ref.read(pluginOptionsProvider).livekitServiceUrl,
    logger: ref.read(pluginLoggerProvider),
  );
}

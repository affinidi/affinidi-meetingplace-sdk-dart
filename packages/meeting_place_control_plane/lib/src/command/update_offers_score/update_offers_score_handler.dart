import 'package:dio/dio.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'update_offers_score.dart';
import 'update_offers_score_output.dart';

/// Handles the update offers score API call. Success is determined by HTTP
/// status; the response body is not parsed.
class UpdateOffersScoreHandler
    extends
        CommandHandler<
          UpdateOffersScoreCommand,
          UpdateOffersScoreCommandOutput
        > {
  UpdateOffersScoreHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );

  static const String _className = 'UpdateOffersScoreHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  @override
  Future<UpdateOffersScoreCommandOutput> handle(
    UpdateOffersScoreCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info(
      'Updating offers score to ${command.score} for '
      '${command.offerLinksOrMnemonics.length} offers',
      name: methodName,
    );

    final response = await _apiClient.client.updateOffersScore(
      score: command.score,
      offerLinksOrMnemonics: command.offerLinksOrMnemonics,
    );

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }

    _logger.info('Updated offers score', name: methodName);
    return UpdateOffersScoreCommandOutput(
      updatedCount: command.offerLinksOrMnemonics.length,
    );
  }
}

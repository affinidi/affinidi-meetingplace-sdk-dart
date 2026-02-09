import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import 'failed_offer.dart';
import 'update_offers_score.dart';
import 'update_offers_score_output.dart';

/// Handles the update offers score API call. Parses response body for
/// [updatedOffers] and [failedOffers].
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
      '${command.mnemonics.length} offers',
      name: methodName,
    );

    final response = await _apiClient.client.updateOffersScore(
      score: command.score,
      mnemonics: command.mnemonics,
    );

    final body = response.data!;
    final map = Map<String, dynamic>.from(body.asMap);

    final updatedOffers = List<String>.from(map['updatedOffers'] as List);

    final failedOffers = (map['failedOffers'] as List)
        .map(
          (item) => FailedOffer(
            mnemonic: item['mnemonic'] as String,
            reason: item['reason'] as String?,
          ),
        )
        .toList();

    _logger.info('Updated offers score', name: methodName);
    return UpdateOffersScoreCommandOutput(
      updatedOffers: updatedOffers,
      failedOffers: failedOffers,
    );
  }
}

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../api/api_client/model/update_offers_score_input.dart';
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

    final input = UpdateOffersScoreInput(
      (b) => b
        ..score = command.score
        ..mnemonics.replace(command.mnemonics),
    );

    final response = await _apiClient.client.updateOffersScore(
      updateOffersScoreInput: input,
    );

    final body = response.data!;
    final updatedOffers = body.updatedOffers.toList();
    final failedOffers = body.failedOffers
        .map((f) => FailedOffer(mnemonic: f.mnemonic ?? '', reason: f.reason))
        .toList();

    _logger.info('Updated offers score', name: methodName);
    return UpdateOffersScoreCommandOutput(
      updatedOffers: updatedOffers.cast<String>(),
      failedOffers: failedOffers,
    );
  }
}

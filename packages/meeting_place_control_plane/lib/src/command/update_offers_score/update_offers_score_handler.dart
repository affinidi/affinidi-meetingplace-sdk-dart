import 'package:built_value/json_object.dart';
import 'package:dio/dio.dart';

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

    final code = response.statusCode ?? 0;
    if (code < 200 || code >= 300) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    }

    final updatedOffers = <String>[];
    final failedOffers = <FailedOffer>[];

    final data = response.data;
    Map<String, dynamic>? map;
    if (data is Map<String, dynamic>) {
      map = data as Map<String, dynamic>;
    } else if (data is JsonObject && data.isMap) {
      map = Map<String, dynamic>.from(data.asMap);
    }
    if (map != null) {
      final updated = map['updatedOffers'];
      if (updated is List) {
        for (final e in updated) {
          if (e is String) {
            updatedOffers.add(e);
          } else if (e is JsonObject && e.isString) {
            updatedOffers.add(e.asString);
          }
        }
      }
      final failed = map['failedOffers'];
      if (failed is List) {
        for (final item in failed) {
          Map<String, dynamic>? entry;
          if (item is Map<String, dynamic>) {
            entry = item;
          } else if (item is JsonObject && item.isMap) {
            entry = Map<String, dynamic>.from(item.asMap);
          }
          if (entry != null) {
            final mnemonic = entry['mnemonic'];
            if (mnemonic is String) {
              failedOffers.add(FailedOffer(mnemonic: mnemonic));
            }
          }
        }
      }
    }

    _logger.info('Updated offers score', name: methodName);
    return UpdateOffersScoreCommandOutput(
      updatedOffers: updatedOffers,
      failedOffers: failedOffers,
    );
  }
}

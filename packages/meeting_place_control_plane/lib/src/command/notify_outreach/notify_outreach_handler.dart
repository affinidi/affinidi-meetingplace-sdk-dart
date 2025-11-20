import 'dart:async';

import '../../../meeting_place_control_plane.dart';
import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import 'notify_outreach_exception.dart';

class NotifyOutreachHandler
    implements
        CommandHandler<NotifyOutreachCommand, NotifyOutreachCommandOutput> {
  NotifyOutreachHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  })  : _apiClient = apiClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);

  static const String _className = 'NotifyChannelHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  @override
  Future<NotifyOutreachCommandOutput> handle(
    NotifyOutreachCommand command,
  ) async {
    final builder = NotifyOutreachInputBuilder()
      ..mnemonic = command.mnemonic
      ..senderInfo = command.senderInfo;

    try {
      _logger.info('[MPX API] calling /notify-outreach');
      await _apiClient.client.notifyOutreach(
        notifyOutreachInput: builder.build(),
      );
      return NotifyOutreachCommandOutput(success: true);
    } catch (e, stackTrace) {
      _logger.warning('Notify outreach failed -> ${e.toString()}');
      Error.throwWithStackTrace(
        NotifyOutreachException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}

import 'dart:async';

import '../../api/api_client.dart';

import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../utils/string.dart';
import 'group_add_member.dart';
import 'group_add_member_exception.dart';
import 'group_add_member_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Group Add Member
/// operation.
class GroupAddMemberHandler
    implements
        CommandHandler<GroupAddMemberCommand, GroupAddMemberCommandOutput> {
  /// Returns an instance of [FinaliseAcceGroupAddMemberHandlerptanceHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  GroupAddMemberHandler({
    required ControlPlaneApiClient apiClient,
    ControlPlaneSDKLogger? logger,
  })  : _apiClient = apiClient,
        _logger = logger ??
            DefaultControlPlaneSDKLogger(
                className: _className, sdkName: sdkName);
  static const String _className = 'GroupAddMemberHandler';

  final ControlPlaneApiClient _apiClient;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Group Add Member command object.
  ///
  /// **Returns:**
  /// - [GroupAddMemberCommandOutput]: The group add member command output object.
  ///
  /// **Throws:**
  /// - [GroupAddMemberException]: Exception thrown by the group add member operation.
  @override
  Future<GroupAddMemberCommandOutput> handle(
    GroupAddMemberCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started adding member to group', name: methodName);

    final builder = GroupAddMemberInputBuilder()
      ..mnemonic = command.mnemonic
      ..groupId = command.groupId
      ..memberDid = command.memberDid
      ..acceptOfferAsDid = command.acceptOfferDid
      ..offerLink = command.offerLink
      ..publicKey = command.publicKey
      ..contactCard = command.contactCard?.toBase64()
      ..reencryptionKey = command.reencryptionKey;

    try {
      _logger.info(
        '[MPX API] Calling /group-add-member for groupId: ${command.groupId}, memberDid: ${command.memberDid.topAndTail()}',
        name: methodName,
      );
      await _apiClient.client.groupAddMember(
        groupAddMemberInput: builder.build(),
      );

      _logger.info('Completed adding member to group', name: methodName);
      return GroupAddMemberCommandOutput(success: true);
    } catch (e, stackTrace) {
      _logger.error(
        'Failed to add member to group',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      Error.throwWithStackTrace(
        GroupAddMemberException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../api/api_client.dart';
import '../../api/control_plane_api_client.dart';
import '../../constants/sdk_constants.dart';
import '../../core/command/command_handler.dart';
import '../../loggers/control_plane_sdk_logger.dart';
import '../../loggers/default_control_plane_sdk_logger.dart';
import '../../trust/trust_action.dart';
import '../../trust/trust_authorization_request.dart';
import '../../trust/trust_policy_enforcer.dart';
import 'group_deregister_member.dart';
import 'group_deregister_member_exception.dart';
import 'group_deregister_member_output.dart';

/// A concreate implementation of the [CommandHandler] interface.
///
/// Handles communication with the API server, including sending requests,
/// receiving responses, and validating the returned data for Group Deregister
/// Member operation.
class GroupDeregisterMemberHandler
    implements
        CommandHandler<
          GroupDeregisterMemberCommand,
          GroupDeregisterMemberCommandOutput
        > {
  /// Returns an instance of [GroupDeregisterMemberHandler].
  ///
  /// **Parameters:**
  /// - [apiClient] - An instance of discovery api client object.
  GroupDeregisterMemberHandler({
    required ControlPlaneApiClient apiClient,
    required TrustPolicyEnforcer trustPolicyEnforcer,
    ControlPlaneSDKLogger? logger,
  }) : _apiClient = apiClient,
       _trustPolicyEnforcer = trustPolicyEnforcer,
       _logger =
           logger ??
           DefaultControlPlaneSDKLogger(
             className: _className,
             sdkName: sdkName,
           );
  static const String _className = 'GroupDeregisterMemberHandler';

  final ControlPlaneApiClient _apiClient;
  final TrustPolicyEnforcer _trustPolicyEnforcer;
  final ControlPlaneSDKLogger _logger;

  /// Overrides the method [CommandHandler.handle].
  ///
  /// This prepares the request that will be sent to the API server and
  /// validates the response. This also handles the exception that are returned
  /// by the API server.
  ///
  /// **Parameters:**
  /// - [command]: Group Deregister Member command object.
  ///
  /// **Returns:**
  /// - [GroupDeregisterMemberCommandOutput]: The group deregister member
  /// command output object.
  ///
  /// **Throws:**
  /// - [GroupDeregisterException]: Exception thrown by the group deregister
  /// member operation.
  @override
  Future<GroupDeregisterMemberCommandOutput> handle(
    GroupDeregisterMemberCommand command,
  ) async {
    final methodName = 'handle';
    _logger.info('Started deregistering member', name: methodName);
    await _trustPolicyEnforcer.enforceOrThrow(
      TrustAuthorizationRequest(
        action: TrustAction.removeGroupMember,
        groupId: command.groupId,
        actorDid: command.actorDid,
        subjectDid: command.memberId,
        credentialProof: command.trustCredentialProof,
        scope: command.trustScope,
        issuerDid: command.trustIssuerDid,
      ),
    );

    final builder = GroupDeregisterMemberInputBuilder()
      ..groupId = command.groupId
      ..memberDid = command.memberId
      ..messageToRelay = command.messageBase64;

    try {
      _logger.info(
        '[MPX API] Calling /group-deregister-member for member: ${command.memberId} from group: ${command.groupId}',
        name: methodName,
      );
      await _apiClient.client.groupMemberDeregister(
        groupDeregisterMemberInput: builder.build(),
      );

      _logger.info('Completed deregistering member', name: methodName);
      return GroupDeregisterMemberCommandOutput(success: true);
    } on DioException catch (e) {
      final data = e.response?.data as Map<String, dynamic>?;

      if (e.response?.statusCode == HttpStatus.gone &&
          data?['errorCode'] == 'group_deleted') {
        _logger.warning(
          '[MPX API] Group already deleted: member ${command.memberId} could '
          'not be deregistered from group ${command.groupId}',
          name: methodName,
        );
        // Return success as group has been deleted already.
        // No further action required.
        return GroupDeregisterMemberCommandOutput(success: true);
      }

      rethrow;
    } catch (e, stackTrace) {
      _logger.error(
        'Failed deregistering member: $e',
        name: methodName,
        error: e,
        stackTrace: stackTrace,
      );
      Error.throwWithStackTrace(
        GroupDeregisterException.generic(innerException: e),
        stackTrace,
      );
    }
  }
}

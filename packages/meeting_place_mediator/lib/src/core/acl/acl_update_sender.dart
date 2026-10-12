import 'dart:io';

import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../../loggers/meeting_place_mediator_sdk_logger.dart';
import 'acl_body.dart';
import 'acl_management.dart';
import 'acl_time_utils.dart';
import 'trust_task_acl_body.dart';

/// Runs [operation], retrying it on transient errors.
typedef RetryRunner = Future<void> Function(Future<void> Function() operation);

/// Sends an [AclManagement] message with [client].
typedef AclManagementSender =
    Future<void> Function(MediatorClient client, AclManagement message);

/// Sends ACL updates to a mediator as Trust Tasks, falling back to the legacy
/// acl-management protocol for mediators that do not serve the ACL Trust
/// Tasks.
///
/// Mediators before 0.17.13 answer an ACL Trust Task with HTTP 501, and
/// mediators 0.31 and later answer acl-management with HTTP 501, so a 501
/// for the Trust Task selects acl-management. The choice is remembered per
/// mediator until acl-management is answered with 501, e.g. after the
/// mediator was upgraded.
class AclUpdateSender {
  /// Creates an [AclUpdateSender].
  ///
  /// [sendAclManagementMessage] replaces the didcomm extension method, which
  /// cannot be mocked, in tests.
  AclUpdateSender({
    required MeetingPlaceMediatorSDKLogger logger,
    AclManagementSender? sendAclManagementMessage,
  }) : _logger = logger,
       _sendAclManagementMessage =
           sendAclManagementMessage ?? _sendWithExtension;

  final MeetingPlaceMediatorSDKLogger _logger;
  final AclManagementSender _sendAclManagementMessage;
  final Set<String> _legacyMediatorDids = {};

  /// Sends [acl] for [issuerDid] to the mediator [client] is connected to.
  ///
  /// An action that changes nothing is skipped. An [AclBody] the SDK cannot
  /// send as a Trust Task is sent with acl-management.
  Future<void> send({
    required MediatorClient client,
    required String issuerDid,
    required AclBody acl,
    required int expiresInSeconds,
    required RetryRunner retry,
  }) async {
    final methodName = 'send';
    final mediatorDid = client.mediatorDidDocument.id;

    Future<void> sendAclManagement() => retry(
      () => _sendAclManagementMessage(
        client,
        AclManagement(
          from: issuerDid,
          to: [mediatorDid],
          body: acl,
          expiresInSeconds: expiresInSeconds,
        ),
      ),
    );

    if (acl is! TrustTaskAclBody) return sendAclManagement();

    // Each call yields a fresh task id, as mediators refuse replayed ids.
    TrustTaskDocument? buildTask() =>
        acl.toTrustTask(issuer: issuerDid, mediatorDid: mediatorDid);

    if (buildTask() == null) {
      _logger.info('Skipped ACL update that changes nothing', name: methodName);
      return;
    }

    if (_legacyMediatorDids.contains(mediatorDid)) {
      try {
        return await sendAclManagement();
      } on MediatorClientException catch (e) {
        if (!_isNotImplemented(e)) rethrow;

        _logger.info(
          'Mediator no longer serves acl-management, using Trust Tasks',
          name: methodName,
        );
        _legacyMediatorDids.remove(mediatorDid);
      }
    }

    try {
      await retry(() async {
        final createdTime = getCreatedTime();
        await client.sendTrustTask(
          TrustTaskMessage(
            id: const Uuid().v4(),
            document: buildTask()!,
            createdTime: createdTime,
            expiresTime: createdTime.add(Duration(seconds: expiresInSeconds)),
          ),
        );
      });
    } on MediatorClientException catch (e) {
      if (!_isNotImplemented(e)) rethrow;

      _logger.info(
        'Mediator does not serve ACL Trust Tasks, using acl-management',
        name: methodName,
      );
      _legacyMediatorDids.add(mediatorDid);
      await sendAclManagement();
    }
  }

  static bool _isNotImplemented(MediatorClientException e) =>
      e.response?.statusCode == HttpStatus.notImplemented;

  static Future<void> _sendWithExtension(
    MediatorClient client,
    AclManagement message,
  ) {
    // Only reached for mediators that do not serve the ACL Trust Tasks.
    // ignore: deprecated_member_use
    return client.sendAclManagementMessage(message);
  }
}

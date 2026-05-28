import 'dart:convert';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:retry/retry.dart';

import '../meeting_place_credentials_sdk_exception.dart';
import '../shared/credential_builder.dart';
import '../shared/credential_sdk_constants.dart';
import 'model/vrc_constants.dart';
import 'model/vrc_credential_subject.dart';
import 'model/vrc_party.dart';

/// Handles outbound VRC operations over VDIP, with retry/backoff on
/// mediator ACL denials.
class VrcExchangeClient {
  /// Creates a [VrcExchangeClient] backed by [coreSDK] for outbound VDIP
  /// operations.
  VrcExchangeClient({
    required MeetingPlaceCoreSDK coreSDK,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _coreSDK = coreSDK,
       _logger = logger;

  static const _retryOptions = RetryOptions(
    maxAttempts: 6,
    delayFactor: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 16),
  );

  final MeetingPlaceCoreSDK _coreSDK;
  final MeetingPlaceCoreSDKLogger _logger;

  /// Sends a VDIP VRC-exchange request for [channelDid].
  Future<void> requestExchange({
    required String channelDid,
    required String identityDid,
    required String identityName,
  }) async {
    final channel = await _coreSDK.getChannelByOtherPartyPermanentDid(
      channelDid,
    );
    final senderDid = channel?.permanentChannelDid;
    if (channel == null || senderDid == null || senderDid.isEmpty) {
      _logger.warning(
        'Cannot request VRC exchange: channel or sender DID missing',
      );
      return;
    }

    await _runWithRetry(
      operationName: 'request VRC exchange',
      action: () => _coreSDK.vdip.requestIssuance(
        senderDid: senderDid,
        recipientDid: channelDid,
        options: RequestCredentialsOptions(
          proposalId: channel.id,
          credentialMeta: CredentialMeta(
            data: {
              VrcConstants.requestMetadataKeyRelationshipType:
                  VrcConstants.requestCredentialTypeChatParticipant,
              VrcConstants.requestMetadataKeyChannelId: channel.id,
              VrcConstants.requestMetadataKeySelectedIdentity: identityDid,
              VrcConstants.requestMetadataKeyIdentityDid: identityDid,
              VrcConstants.requestMetadataKeyIdentityName: identityName,
            },
          ),
        ),
      ),
    );
  }

  /// Builds, signs, and sends a VRC over VDIP for [channelDid].
  ///
  /// Returns the serialised VC JSON string (vcBlob) so callers can
  /// render the sent VRC as a chat attachment.
  Future<String> sendVrc({
    required String channelDid,
    required String issuerDid,
    required String issuerName,
    required String peerDid,
    required String peerName,
  }) async {
    final channel = await _coreSDK.getChannelByOtherPartyPermanentDid(
      channelDid,
    );
    final senderDid = channel?.permanentChannelDid;
    if (channel == null || senderDid == null || senderDid.isEmpty) {
      throw MeetingPlaceCredentialsSDKException.sendVrcMissingChannel(
        channelDid: channelDid,
      );
    }

    final didManager = await _coreSDK.getDidManager(issuerDid);
    final vc = await CredentialBuilder.buildVrc(
      issuerDid: issuerDid,
      subject: VrcCredentialSubject(
        from: VrcParty(did: issuerDid, name: issuerName),
        to: VrcParty(did: peerDid, name: peerName),
      ),
      issuerDidManager: didManager,
    );

    final vcBlob = jsonEncode(vc.toJson());
    await _runWithRetry(
      operationName: 'send VRC',
      action: () => _coreSDK.vdip.sendIssuedCredential(
        senderDid: senderDid,
        recipientDid: channelDid,
        body: VdipIssuedCredentialBody.fromJson({
          'credential': vcBlob,
          'credential_format': CredentialsSDKConstants.w3cV2,
        }),
      ),
    );
    return vcBlob;
  }

  Future<void> _runWithRetry({
    required String operationName,
    required Future<void> Function() action,
  }) async {
    try {
      await _retryOptions.retry(
        action,
        retryIf: _isMediatorAclDenied,
        onRetry: (e) => _logger.warning(
          'Mediator ACL denied during $operationName, retrying...',
        ),
      );
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to $operationName',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  bool _isMediatorAclDenied(Exception error) {
    final errorString = error.toString();
    return errorString.contains('Status code: 403') ||
        errorString.contains('access_list denied') ||
        errorString.contains('e.p.authorization.access_list.denied');
  }
}

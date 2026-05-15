import 'package:meeting_place_core/meeting_place_core.dart';

import 'model/received_vrc_request.dart';
import 'model/vrc_credential_subject.dart';
import 'model/vrc_party.dart';
import 'model/vrc_received_outcome.dart';
import 'model/vrc_request_received_outcome.dart';
import 'parser/vrc_parser.dart';
import 'vrc_exchange_client.dart';

/// Evaluates incoming VRC events and determines the correct
/// relationship-protocol response.
///
/// Protocol decisions (reciprocate, complete, wait, prompt) are based solely
/// on the local exchange state and the ADR channel-ownership tie-breaker rule.
/// Actual VDIP sends are delegated to [VrcExchangeClient].
class VrcProtocolHandler {
  VrcProtocolHandler({
    required VrcExchangeClient client,
    required VrcParser parser,
    required MeetingPlaceCoreSDKLogger logger,
  }) : _client = client,
       _parser = parser,
       _logger = logger;

  final VrcExchangeClient _client;
  final VrcParser _parser;
  final MeetingPlaceCoreSDKLogger _logger;

  /// Determines the outcome for an incoming VRC issuance request.
  ///
  /// In a simultaneous-request scenario the channel owner (initiator) issues
  /// immediately; the accepter waits. Otherwise, the consumer should prompt
  /// the user.
  Future<VrcRequestReceivedOutcome> handleReceivedVrcRequest({
    required String channelDid,
    required ReceivedVrcRequest request,
    required bool hasVrcExchangeInitiated,
    required bool isConnectionInitiator,
    String? localIdentityDid,
    String? localIdentityName,
    void Function(String vcBlob)? onVrcSent,
  }) async {
    if (!hasVrcExchangeInitiated) {
      return VrcRequestReceivedOutcome.prompt;
    }

    if (!isConnectionInitiator) {
      return VrcRequestReceivedOutcome.waiting;
    }

    if (localIdentityDid == null || localIdentityDid.isEmpty) {
      _logger.warning(
        'Cannot auto-issue VRC for simultaneous request: '
        'local initiator identity is missing',
      );
      return VrcRequestReceivedOutcome.prompt;
    }

    final peerDid = request.selectedPersona ?? request.identityDid;
    if (peerDid == null || peerDid.isEmpty) {
      _logger.warning(
        'Cannot auto-issue VRC for simultaneous request: '
        'peer persona DID is missing',
      );
      return VrcRequestReceivedOutcome.prompt;
    }

    final sentVcBlob = await _client.sendVrc(
      channelDid: channelDid,
      issuerDid: localIdentityDid,
      issuerName: localIdentityName ?? '',
      peerDid: peerDid,
      peerName: request.identityName ?? '',
    );
    onVrcSent?.call(sentVcBlob);
    return VrcRequestReceivedOutcome.issued;
  }

  /// Determines the outcome for an incoming VRC.
  ///
  /// If the local party initiated the exchange, this reciprocates by issuing a
  /// VRC back to the peer. If the local party had already received a VRC
  /// request, this marks the exchange as completed without sending another VRC.
  Future<VrcReceivedOutcome> handleReceivedVrc({
    required String channelDid,
    required String vcBlob,
    required bool hasVrcExchangeCompleted,
    required bool hasVrcExchangeInitiated,
    required bool hasVrcRequestReceived,
    required bool isConnectionInitiator,
    String? localIdentityDid,
    String? localIdentityName,
    void Function(String vcBlob)? onVrcSent,
  }) async {
    if (hasVrcExchangeCompleted) {
      return VrcReceivedOutcome.ignored;
    }

    if (hasVrcExchangeInitiated && hasVrcRequestReceived) {
      if (isConnectionInitiator) {
        return VrcReceivedOutcome.completed;
      }

      return await _reciprocate(
        channelDid: channelDid,
        vcBlob: vcBlob,
        localIdentityDid: localIdentityDid,
        localIdentityName: localIdentityName,
        warningContext: 'after waiting',
        onVrcSent: onVrcSent,
      );
    }

    if (hasVrcExchangeInitiated) {
      return await _reciprocate(
        channelDid: channelDid,
        vcBlob: vcBlob,
        localIdentityDid: localIdentityDid,
        localIdentityName: localIdentityName,
        warningContext: '',
        onVrcSent: onVrcSent,
      );
    }

    if (hasVrcRequestReceived) {
      return VrcReceivedOutcome.completed;
    }

    return VrcReceivedOutcome.ignored;
  }

  Future<VrcReceivedOutcome> _reciprocate({
    required String channelDid,
    required String vcBlob,
    required String? localIdentityDid,
    required String? localIdentityName,
    required String warningContext,
    void Function(String vcBlob)? onVrcSent,
  }) async {
    final suffix = warningContext.isEmpty ? '' : ' $warningContext';
    if (localIdentityDid == null || localIdentityDid.isEmpty) {
      _logger.warning(
        'Cannot reciprocate VRC$suffix: local initiator identity is missing',
      );
      return VrcReceivedOutcome.ignored;
    }

    final peerParty = await _extractIssuerParty(vcBlob: vcBlob);
    if (peerParty == null) {
      _logger.warning(
        'Cannot reciprocate VRC$suffix: failed to extract peer party',
      );
      return VrcReceivedOutcome.ignored;
    }

    await _client
        .sendVrc(
          channelDid: channelDid,
          issuerDid: localIdentityDid,
          issuerName: localIdentityName ?? '',
          peerDid: peerParty.did,
          peerName: peerParty.name,
        )
        .then(onVrcSent ?? (_) {});
    return VrcReceivedOutcome.reciprocated;
  }

  Future<VrcParty?> _extractIssuerParty({required String vcBlob}) async {
    final parsed = await _parser.parse(vcBlob: vcBlob);
    if (parsed == null || parsed.credentialSubject.isEmpty) return null;

    final subject = VrcCredentialSubject.fromJson(
      Map<String, dynamic>.from(parsed.credentialSubject.first),
    );
    return subject.from;
  }
}

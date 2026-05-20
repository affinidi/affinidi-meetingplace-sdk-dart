import 'package:meeting_place_core/meeting_place_core.dart';

import 'model/vrc_credential_subject.dart';
import 'model/vrc_exchange_state.dart';
import 'model/vrc_party.dart';
import 'model/vrc_processing_result.dart';
import 'model/vrc_request.dart';
import 'model/vrc_request_processing_result.dart';
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
  Future<VrcRequestProcessingResult> handleReceivedVrcRequest({
    required String permanentChannelDid,
    required VrcRequest request,
    required bool hasVrcExchangeInitiated,
    required bool isConnectionInitiator,
    String? issuerDid,
    String? issuerName,
    void Function(String vcBlob)? onVrcSent,
  }) async {
    if (!hasVrcExchangeInitiated) {
      return VrcRequestProcessingResult.prompt;
    }

    if (!isConnectionInitiator) {
      return VrcRequestProcessingResult.waiting;
    }

    if (issuerDid == null || issuerDid.isEmpty) {
      _logger.warning(
        'Cannot auto-issue VRC for simultaneous request: '
        'local initiator identity is missing',
      );
      return VrcRequestProcessingResult.prompt;
    }

    final peerDid = request.identityDid;
    if (peerDid == null || peerDid.isEmpty) {
      _logger.warning(
        'Cannot auto-issue VRC for simultaneous request: '
        'peer identity DID is missing',
      );
      return VrcRequestProcessingResult.prompt;
    }

    final sentVcBlob = await _client.sendVrc(
      channelDid: permanentChannelDid,
      issuerDid: issuerDid,
      issuerName: issuerName ?? '',
      peerDid: peerDid,
      peerName: request.identityName ?? '',
    );
    onVrcSent?.call(sentVcBlob);
    return VrcRequestProcessingResult.issued;
  }

  /// Determines the outcome for an incoming VRC.
  ///
  /// If the local party initiated the exchange, this reciprocates by issuing a
  /// VRC back to the peer. If the local party had already received a VRC
  /// request, this marks the exchange as completed without sending another VRC.
  ///
  /// The caller is responsible for not invoking this method when the exchange
  /// is already completed.
  Future<VrcProcessingResult> handleReceivedVrc({
    required String permanentChannelDid,
    required String vcBlob,
    required VrcExchangeState exchangeState,
    String? issuerDid,
    String? issuerName,
    void Function(String vcBlob)? onVrcSent,
  }) async {
    if (exchangeState.hasVrcExchangeInitiated &&
        exchangeState.hasVrcRequestReceived) {
      if (exchangeState.isConnectionInitiator) {
        return VrcProcessingResult.completed;
      }

      return await _reciprocate(
        permanentChannelDid: permanentChannelDid,
        vcBlob: vcBlob,
        issuerDid: issuerDid,
        issuerName: issuerName,
        warningContext: 'after waiting',
        onVrcSent: onVrcSent,
      );
    }

    if (exchangeState.hasVrcExchangeInitiated) {
      return await _reciprocate(
        permanentChannelDid: permanentChannelDid,
        vcBlob: vcBlob,
        issuerDid: issuerDid,
        issuerName: issuerName,
        warningContext: '',
        onVrcSent: onVrcSent,
      );
    }

    if (exchangeState.hasVrcRequestReceived) {
      return VrcProcessingResult.completed;
    }

    return VrcProcessingResult.ignored;
  }

  Future<VrcProcessingResult> _reciprocate({
    required String permanentChannelDid,
    required String vcBlob,
    required String? issuerDid,
    required String? issuerName,
    required String warningContext,
    void Function(String vcBlob)? onVrcSent,
  }) async {
    final suffix = warningContext.isEmpty ? '' : ' $warningContext';
    if (issuerDid == null || issuerDid.isEmpty) {
      _logger.warning(
        'Cannot reciprocate VRC$suffix: local initiator identity is missing',
      );
      return VrcProcessingResult.ignored;
    }

    final peerParty = await _extractIssuerParty(vcBlob: vcBlob);
    if (peerParty == null) {
      _logger.warning(
        'Cannot reciprocate VRC$suffix: failed to extract peer party',
      );
      return VrcProcessingResult.ignored;
    }

    await _client
        .sendVrc(
          channelDid: permanentChannelDid,
          issuerDid: issuerDid,
          issuerName: issuerName ?? '',
          peerDid: peerParty.did,
          peerName: peerParty.name,
        )
        .then(onVrcSent ?? (_) {});
    return VrcProcessingResult.reciprocated;
  }

  Future<VrcParty?> _extractIssuerParty({required String vcBlob}) async {
    final parsed = await _parser.parse(vcBlob: vcBlob);
    if (parsed == null) return null;
    final raw = parsed.credentialSubject.firstOrNull as Map<String, dynamic>?;
    if (raw == null) return null;
    final subject = VrcCredentialSubject.fromJson(raw);
    return subject.from;
  }
}

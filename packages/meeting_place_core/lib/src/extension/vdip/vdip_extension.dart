import 'package:affinidi_tdk_didcomm_mediator_client/affinidi_tdk_didcomm_mediator_client.dart';
import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:ssi/ssi.dart';

import '../../../meeting_place_core.dart';
import 'service/vdip_service.dart';

class VdipExtension {
  VdipExtension({required MeetingPlaceCoreSDK sdk})
    : _sdk = sdk,
      _vdipService = VdipService(sdk: sdk);

  final MeetingPlaceCoreSDK _sdk;
  final VdipService _vdipService;

  /// Requests credential issuance from the other party on the given [channel].
  ///
  /// This method initiates a VDIP (Verifiable Data Issuance Protocol)
  /// credential request flow. The holder subscribes to the mediator channel
  /// and listens for the credential issuance response from the issuer.
  ///
  /// **Parameters:**
  /// - [holderDid]: The DID of the credential holder requesting the credential.
  /// - [channel]: The communication channel established between holder and issuer.
  ///   Must have both `permanentChannelDid` and `otherPartyPermanentChannelDid` set.
  /// - [options]: Configuration options for the credential request, including
  ///   proposal ID, credential format, and any credential metadata.
  ///
  /// Returns a [RequestCredentialResponse] containing the issued credential
  /// response from the issuer.
  ///
  Future<RequestCredentialResponse> requestCredential(
    String holderDid, {
    required Channel channel,
    required RequestCredentialsOptions options,
    List<Attachment>? attachments,
  }) async {
    return _sdk.withSdkExceptionHandling(() {
      return _vdipService.requestCredential(
        holderDid,
        channel: channel,
        attachments: attachments,
        options: options,
      );
    });
  }

  /// Issues a verifiable credential to the holder on the given [channel].
  ///
  /// This method sends a previously signed verifiable credential to the holder
  /// via the VDIP (Verifiable Data Issuance Protocol). The issuer must have
  /// already created and signed the credential before calling this method.
  ///
  /// **Parameters:**
  /// - [channel]: The communication channel established between issuer and
  ///   holder. Must have both `permanentChannelDid` and
  ///   `otherPartyPermanentChannelDid` set.
  /// - [verifiableCredential]: The signed verifiable credential to send to the
  ///   holder. Must be a valid W3C Verifiable Credential.
  ///
  Future<void> issueCredential(
    VerifiableCredential verifiableCredential, {
    required Channel channel,
    List<Attachment>? attachments,
  }) async {
    return _sdk.withSdkExceptionHandling(() {
      return _vdipService.issueCredential(
        verifiableCredential,
        channel: channel,
        attachments: attachments,
      );
    });
  }

  /// Sends a problem report message to the other party on the given [channel].
  ///
  /// This method is used to communicate errors or issues during the VDIP
  /// (Verifiable Data Issuance Protocol) flow. The problem report is linked
  /// to the original request issuance message via its thread ID.
  ///
  /// **Parameters:**
  /// - [channel]: The communication channel to send the problem report on.
  ///   Must have both `permanentChannelDid` and `otherPartyPermanentChannelDid`
  ///   set.
  /// - [code]: The problem code indicating the type of error that occurred
  ///   (e.g., invalid request, unsupported credential format, etc.).
  /// - [requestIssuanceMessage]: The original VDIP request issuance message
  ///   that encountered the problem. Used to establish the message thread
  ///   relationship.
  ///
  Future<void> sendProblemReport(
    Channel channel, {
    required ProblemCode code,
    required PlainTextMessage requestIssuanceMessage,
  }) {
    return _sdk.withSdkExceptionHandling(() {
      return _vdipService.sendProblemReport(
        channel,
        code: code,
        requestIssuanceMessage: requestIssuanceMessage,
      );
    });
  }
}

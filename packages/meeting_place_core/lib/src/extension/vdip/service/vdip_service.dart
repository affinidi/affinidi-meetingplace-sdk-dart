import 'dart:async';
import 'dart:convert';

import 'package:affinidi_tdk_didcomm_mediator_client/affinidi_tdk_didcomm_mediator_client.dart';
import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:retry/retry.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';
import '../../../../meeting_place_core.dart';
import '../../../protocol/attachment/sequence_no_attachment.dart';
import '../../../utils/error_handler_utils.dart';
import '../meeting_place_core_sdk_vdip_exception.dart';

class VdipService {
  VdipService({required MeetingPlaceCoreSDK sdk}) : _sdk = sdk;

  final MeetingPlaceCoreSDK _sdk;

  Future<RequestCredentialResponse> requestCredential(
    String holderDid, {
    required Channel channel,
    required RequestCredentialsOptions options,
    List<Attachment>? attachments,
  }) async {
    final (:permanentChannelDid, :otherPartyPermanentChannelDid) =
        _validateChannelDids(channel);

    final waitForCredential = Completer<RequestCredentialResponse>();
    final vdipHolder = await _initVdipHolderClient(
      permanentChannelDid: permanentChannelDid,
      mediatorDid: channel.mediatorDid,
    );

    // TODO: use onProblemReport callback?

    vdipHolder.listenForIncomingMessages(
      onCredentialsIssuanceResponse: (message) async {
        VdipIssuedCredentialBody body = VdipIssuedCredentialBody.fromJson(
          message.body!,
        );

        _sdk.logger.info(
          'Received issued credential: ${jsonEncode(body)}',
          name: 'issueCredential',
        );
        await vdipHolder.mediatorClient.disconnect();

        waitForCredential.complete(
          RequestCredentialResponse(
            credential: body.credential,
            credentialFormat: body.credentialFormat,
            attachments: message.attachments,
          ),
        );
      },
    );

    await ConnectionPool.instance.startConnections();

    final holderDidManager = await _sdk.getDidManager(holderDid);
    final assertionSigner = await holderDidManager.getSigner(
      holderDidManager.assertionMethod.first,
    );

    channel.increaseSeqNo();

    await retry(
      () async {
        final message = await vdipHolder.requestCredentialForHolder(
          holderDid,
          issuerDid: otherPartyPermanentChannelDid,
          assertionSigner: assertionSigner,
          options: options,
          attachments: [
            ...?attachments,
            SequenceNoAttachment.create(seqNo: channel.seqNo),
          ],
        );

        _sdk.logger.info(
          'Sent credential request message with ID: ${jsonEncode(message.body)}',
          name: 'requestCredential',
        );

        await _sdk.updateChannel(channel);
      },
      retryIf: (e) => ErrorHandlerUtils.isRetryableError(e),
      onRetry: (e) => _sdk.logger.warning(
        'Retrying requestCredential due to error: $e',
        name: 'requestCredential',
      ),
    );

    unawaited(_notifyChannel(channel));
    return waitForCredential.future;
  }

  // TODO: How to bind problem report to a specific issuance flow?
  // TODO: general SDK method?
  // TODO: can we abstract one more way?
  Future<void> sendProblemReport(
    Channel channel, {
    required ProblemCode code,
    required PlainTextMessage requestIssuanceMessage,
  }) {
    final (:permanentChannelDid, :otherPartyPermanentChannelDid) =
        _validateChannelDids(channel);

    return _sdk.sendMessage(
      ProblemReportMessage(
        id: const Uuid().v4(),
        parentThreadId:
            requestIssuanceMessage.threadId ?? requestIssuanceMessage.id,
        body: ProblemReportBody(code: code),
      ),
      senderDid: permanentChannelDid,
      recipientDid: otherPartyPermanentChannelDid,
    );
  }

  Future<void> issueCredential(
    VerifiableCredential verifiableCredential, {
    required Channel channel,
    List<Attachment>? attachments,
  }) async {
    final (:permanentChannelDid, :otherPartyPermanentChannelDid) =
        _validateChannelDids(channel);

    final issuerDidManager = await _sdk.getDidManager(permanentChannelDid);
    final mediatorClient = await _sdk.mediator.authenticateWithDid(
      issuerDidManager,
      mediatorDid: channel.mediatorDid,
    );

    _sdk.logger.info(
      'Initialized VDIP issuer client for DID: $permanentChannelDid',
    );

    final vdipIssuer = await VdipIssuer.init(
      didManager: issuerDidManager,
      mediatorDidDocument: mediatorClient.mediatorDidDocument,
      authorizationProvider: await AffinidiAuthorizationProvider.init(
        mediatorDidDocument: mediatorClient.mediatorDidDocument,
        didManager: issuerDidManager,
      ),
      clientOptions: const AffinidiClientOptions(),
      featureDisclosures: [],
    );

    channel.increaseSeqNo();

    await retry(
      () async {
        final message = await vdipIssuer.sendIssuedCredentials(
          holderDid: otherPartyPermanentChannelDid,
          verifiableCredential: verifiableCredential,
          attachments: [
            ...?attachments,
            SequenceNoAttachment.create(seqNo: channel.seqNo),
          ],
        );

        _sdk.logger.info(
          'Issued credential message sent with ID: ${jsonEncode(message.body)}',
          name: 'issueCredential',
        );

        await _sdk.updateChannel(channel);
      },
      retryIf: (e) => ErrorHandlerUtils.isRetryableError(e),
      onRetry: (e) => _sdk.logger.warning(
        'Retrying sendIssuedCredentials due to error: $e',
        name: 'issueCredential',
      ),
    );

    unawaited(_notifyChannel(channel));
  }

  Future<VdipHolder> _initVdipHolderClient({
    required String permanentChannelDid,
    required String mediatorDid,
  }) async {
    final permanentChannelDidManager = await _sdk.getDidManager(
      permanentChannelDid,
    );
    final mediatorClient = await _sdk.mediator.authenticateWithDid(
      permanentChannelDidManager,
      mediatorDid: mediatorDid,
    );

    _sdk.logger.info(
      'Initialized VDIP holder client for DID: $permanentChannelDid',
    );
    return VdipHolder.init(
      didManager: permanentChannelDidManager,
      mediatorDidDocument: mediatorClient.mediatorDidDocument,
      authorizationProvider: await AffinidiAuthorizationProvider.init(
        mediatorDidDocument: mediatorClient.mediatorDidDocument,
        didManager: permanentChannelDidManager,
      ),
      clientOptions: const AffinidiClientOptions(),
    );
  }

  /// Validates and returns non-null permanent channel DIDs.
  ///
  /// Throws [MeetingPlaceCoreSDKException] if either DID is null.
  ({String permanentChannelDid, String otherPartyPermanentChannelDid})
  _validateChannelDids(Channel channel) {
    final permanentChannelDid = channel.permanentChannelDid;
    final otherPartyPermanentChannelDid = channel.otherPartyPermanentChannelDid;

    if (permanentChannelDid == null || otherPartyPermanentChannelDid == null) {
      throw MeetingPlaceCoreSDKVdipException.missingChannelDids();
    }

    return (
      permanentChannelDid: permanentChannelDid,
      otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
    );
  }

  Future<void> _notifyChannel(Channel channel) async {
    try {
      if (channel.otherPartyNotificationToken == null) return;

      await _sdk.discovery.notifyChannel(
        notificationToken: channel.otherPartyNotificationToken!,
        did: channel.otherPartyPermanentChannelDid!,
        type: NotifyChannelType.chatActivity,
      );
    } on MeetingPlaceCoreSDKException catch (e, stackTrace) {
      final isNotificationError =
          e.code ==
          MeetingPlaceCoreSDKErrorCode.channelNotificationFailed.value;

      if (!isNotificationError) {
        _sdk.logger.error(
          'Failed to send message with notification',
          error: e,
          name: '_notifyChannel',
          stackTrace: stackTrace,
        );
        rethrow;
      }

      _sdk.logger.warning(
        'Failed to send notification ',
        name: '_notifyChannel',
      );
    }
  }
}

import 'dart:async';

import 'package:affinidi_tdk_didcomm_mediator_client/affinidi_tdk_didcomm_mediator_client.dart';
import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../../../meeting_place_core.dart';
import '../meeting_place_core_sdk_vdip_exception.dart';

class VdipService {
  VdipService({required MeetingPlaceCoreSDK sdk}) : _sdk = sdk;

  final MeetingPlaceCoreSDK _sdk;

  Future<RequestCredentialResponse> requestCredential(
    String holderDid, {
    required Channel channel,
    required RequestCredentialsOptions options,
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

        await ConnectionPool.instance.stopConnections();
        waitForCredential.complete(
          RequestCredentialResponse(
            credential: body.credential,
            credentialFormat: body.credentialFormat,
          ),
        );
      },
    );

    await ConnectionPool.instance.startConnections();

    final holderDidManager = await _sdk.getDidManager(holderDid);
    final assertionSigner = await holderDidManager.getSigner(
      holderDidManager.assertionMethod.first,
    );

    await vdipHolder.requestCredentialForHolder(
      holderDid,
      issuerDid: otherPartyPermanentChannelDid,
      assertionSigner: assertionSigner,
      options: options,
    );

    // TODO: improve
    await _sdk.discovery.notifyChannel(
      notificationToken: channel.otherPartyNotificationToken!,
      did: channel.otherPartyPermanentChannelDid!,
      type: NotifyChannelType.chatActivity,
    );

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
    Channel channel,
    VerifiableCredential verifiableCredential,
  ) async {
    final (:permanentChannelDid, :otherPartyPermanentChannelDid) =
        _validateChannelDids(channel);

    // TODO: assertion needed on issuer?

    final issuerDidManager = await _sdk.getDidManager(permanentChannelDid);
    final mediatorDidDocument = await _sdk.didResolver.resolveDid(
      channel.mediatorDid,
    );

    // === VDIP for issuer starts here ===
    final vdipIssuer = await VdipIssuer.init(
      mediatorDidDocument: mediatorDidDocument,
      didManager: issuerDidManager,
      featureDisclosures: [],
      authorizationProvider: await AffinidiAuthorizationProvider.init(
        mediatorDidDocument: mediatorDidDocument,
        didManager: issuerDidManager,
      ),
      clientOptions: const AffinidiClientOptions(),
    );

    await vdipIssuer.sendIssuedCredentials(
      holderDid: otherPartyPermanentChannelDid,
      verifiableCredential: verifiableCredential,
    );

    await _notifyChannel(channel);
  }

  Future<VdipHolder> _initVdipHolderClient({
    required String permanentChannelDid,
    required String mediatorDid,
  }) async {
    final permanentChannelDidManager = await _sdk.getDidManager(
      permanentChannelDid,
    );
    final mediatorDidDocument = await _sdk.didResolver.resolveDid(mediatorDid);

    // TODO: How to get initialized mediator client from Mediator SDK?
    // VdipHolder(didManager: permanentChannelDidManager, mediatorClient: '');

    return VdipHolder.init(
      mediatorDidDocument: mediatorDidDocument,
      didManager: permanentChannelDidManager,
      authorizationProvider: await AffinidiAuthorizationProvider.init(
        mediatorDidDocument: mediatorDidDocument,
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
      await _sdk.discovery.notifyChannel(
        notificationToken: channel.otherPartyNotificationToken!,
        did: channel.otherPartyPermanentChannelDid!,
        type: NotifyChannelType.chatActivity,
      );
    } on MeetingPlaceCoreSDKException catch (e) {
      final isNotificationError =
          e.code ==
          MeetingPlaceCoreSDKErrorCode.channelNotificationFailed.value;

      if (!isNotificationError) {
        _sdk.logger.error(
          'Failed to send message with notification',
          error: e,
          name: '_notifyChannel',
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

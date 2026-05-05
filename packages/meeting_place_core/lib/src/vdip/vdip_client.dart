import 'dart:async';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:didcomm/didcomm.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../service/channel/channel_service.dart';
import '../service/connection_manager/connection_manager.dart';
import '../service/message/message_service.dart';
import 'channel_activity_type.dart';

/// Client for sending and receiving VDIP (Verifiable Data Issuance Protocol)
/// messages over the shared DIDComm connection managed by
/// `MeetingPlaceCoreSDK`.
///
/// Obtain an instance via `MeetingPlaceCoreSDK.vdip` — do not construct
/// directly.
class VdipClient {
  VdipClient({
    required MessageService messageService,
    required ChannelService channelService,
    required ConnectionManager connectionManager,
    required Wallet wallet,
  }) : _messageService = messageService,
       _channelService = channelService,
       _connectionManager = connectionManager,
       _wallet = wallet;

  final MessageService _messageService;
  final ChannelService _channelService;
  final ConnectionManager _connectionManager;
  final Wallet _wallet;

  final _incomingController = StreamController<PlainTextMessage>.broadcast();

  /// A broadcast stream that emits incoming VDIP [PlainTextMessage]s.
  ///
  /// Emits messages of type [VdipRequestIssuanceMessage] and
  /// [VdipIssuedCredentialMessage] as they arrive over the shared
  /// DIDComm connection.
  ///
  /// Subscribe to this stream to react to incoming VRC requests or
  /// issued credentials sent by the other party.
  Stream<PlainTextMessage> get incomingMessages => _incomingController.stream;

  /// Sends a VDIP credential issuance request to [recipientDid].
  ///
  /// Encrypts and delivers a [VdipRequestIssuanceMessage] over the shared
  /// DIDComm connection, then notifies the Control Plane so the recipient's
  /// device is woken if offline.
  ///
  /// **Parameters:**
  /// - [senderDid]: The DID of the local identity sending the request.
  /// - [recipientDid]: The channel DID of the issuer to request credentials
  ///   from.
  /// - [options]: Parameters for the issuance request such as
  ///   [RequestCredentialsOptions.proposalId] and credential format.
  ///
  /// **Returns:**
  /// - `Future<void>` completes when the message is delivered and the
  ///   Control Plane has been notified.
  Future<void> requestIssuance({
    required String senderDid,
    required String recipientDid,
    required RequestCredentialsOptions options,
  }) async {
    final senderDidManager = await _connectionManager.getDidManagerForDid(
      _wallet,
      senderDid,
    );
    final channel = await _channelService.findChannelByDid(recipientDid);
    final message = VdipRequestIssuanceMessage(
      id: const Uuid().v4(),
      to: [recipientDid],
      body: VdipRequestIssuanceMessageBody(
        proposalId: options.proposalId,
        challenge: options.challenge,
        credentialFormat: options.credentialFormat,
        jsonWebSignatureAlgorithm: options.jsonWebSignatureAlgorithm,
        comment: options.comment,
        credentialMeta: options.credentialMeta,
      ),
    );
    await _messageService.sendMessage(
      message,
      senderDidManager: senderDidManager,
      recipientDid: recipientDid,
      mediatorDid: channel.mediatorDid,
      notifyChannelType: ChannelActivityType.vdipRequestIssuance,
    );
  }

  /// Sends an issued credential to [recipientDid] over VDIP.
  ///
  /// Encrypts and delivers a [VdipIssuedCredentialMessage] over the shared
  /// DIDComm connection, then notifies the Control Plane so the recipient's
  /// device is woken if offline.
  ///
  /// **Parameters:**
  /// - [senderDid]: The DID of the local identity sending the credential.
  /// - [recipientDid]: The channel DID of the holder receiving the credential.
  /// - [body]: The [VdipIssuedCredentialBody] containing the serialized
  ///   credential and format metadata.
  ///
  /// **Returns:**
  /// - `Future<void>` completes when the message is delivered and the
  ///   Control Plane has been notified.
  Future<void> sendIssuedCredential({
    required String senderDid,
    required String recipientDid,
    required VdipIssuedCredentialBody body,
  }) async {
    final senderDidManager = await _connectionManager.getDidManagerForDid(
      _wallet,
      senderDid,
    );
    final channel = await _channelService.findChannelByDid(recipientDid);
    final message = VdipIssuedCredentialMessage(
      id: const Uuid().v4(),
      to: [recipientDid],
      body: body.toJson(),
    );
    await _messageService.sendMessage(
      message,
      senderDidManager: senderDidManager,
      recipientDid: recipientDid,
      mediatorDid: channel.mediatorDid,
      notifyChannelType: ChannelActivityType.vdipIssuedCredentials,
    );
  }

  /// Dispatches an incoming [message] to the [incomingMessages] stream.
  ///
  /// Called internally by ChannelActivityEventHandler when a VDIP
  /// message arrives via the Control Plane push wake path.
  void dispatch(PlainTextMessage message) {
    _incomingController.add(message);
  }

  /// Disposes the [VdipClient] and closes the [incomingMessages] stream.
  Future<void> dispose() async {
    await _incomingController.close();
  }
}

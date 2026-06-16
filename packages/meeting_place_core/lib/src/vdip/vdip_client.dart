import 'dart:async';

import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_core.dart';
import '../service/channel/channel_service.dart';
import '../service/connection_manager/connection_manager.dart';
import '../service/mediator/mediator_service.dart';
import '../service/mediator/mediator_stream_subscription_wrapper.dart';
import '../service/message/message_service.dart';

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
    required MediatorService mediatorService,
  }) : _messageService = messageService,
       _channelService = channelService,
       _connectionManager = connectionManager,
       _wallet = wallet,
       _mediatorService = mediatorService;

  /// DIDComm message type for a VDIP issued-credential message.
  static final String issuedCredentialMessageType = VdipIssuedCredentialMessage
      .messageType
      .toString();

  /// DIDComm message type for a VDIP request-issuance message.
  static final String requestIssuanceMessageType = VdipRequestIssuanceMessage
      .messageType
      .toString();

  final MessageService _messageService;
  final ChannelService _channelService;
  final ConnectionManager _connectionManager;
  final Wallet _wallet;
  final MediatorService _mediatorService;

  final _incomingController = StreamController<PlainTextMessage>.broadcast();
  final _messageProcessors = <Future<void> Function(PlainTextMessage)>[];
  MediatorStreamSubscriptionWrapper? _mediatorSubscription;
  StreamSubscription? _mediatorStreamSubscription;
  var _isDisposed = false;

  /// Registers a [processor] that is called for every VDIP message handled
  /// by `VdipActivityEventHandler`, **before** the message is deleted from
  /// the mediator.
  ///
  /// Unlike [incomingMessages], processors are guaranteed to be called even
  /// when no stream subscriber is present — making them the correct hook for
  /// reliable persistence (e.g. R-Card upsert) that must not depend on lazy
  /// SDK initialisation timing.
  void registerMessageProcessor(
    Future<void> Function(PlainTextMessage) processor,
  ) {
    _messageProcessors.add(processor);
  }

  /// The list of processors registered via [registerMessageProcessor].
  ///
  /// Called sequentially by `VdipActivityEventHandler` for each incoming
  /// VDIP message before that message is deleted from the mediator.
  List<Future<void> Function(PlainTextMessage)> get messageProcessors =>
      List.unmodifiable(_messageProcessors);

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
      from: senderDid,
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
      from: senderDid,
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

  /// Issues a signed [credential] to the other party in [channel] via VDIP.
  ///
  /// High-level convenience wrapper around [sendIssuedCredential]. Extracts
  /// the sender and recipient DIDs from [channel], constructs the
  /// [VdipIssuedCredentialBody], and delivers the message.
  ///
  /// Throws [StateError] if the channel DIDs are missing.
  Future<void> issueCredential({
    required Channel channel,
    required VcDataModelV2 credential,
  }) async {
    final senderDid = channel.permanentChannelDid;
    final recipientDid = channel.otherPartyPermanentChannelDid;
    if (senderDid == null || senderDid.isEmpty) {
      throw StateError(
        'Channel is missing permanentChannelDid — cannot issue credential.',
      );
    }
    if (recipientDid == null || recipientDid.isEmpty) {
      throw StateError(
        'Channel is missing otherPartyPermanentChannelDid — cannot issue'
        ' credential.',
      );
    }

    final body = VdipIssuedCredentialBody.w3cV2(credential: credential);

    await sendIssuedCredential(
      senderDid: senderDid,
      recipientDid: recipientDid,
      body: body,
    );
  }

  /// Dispatches an incoming [message] to the [incomingMessages] stream.
  ///
  /// Called internally by ChannelActivityEventHandler when a VDIP
  /// message arrives via the Control Plane push wake path.
  void dispatch(PlainTextMessage message) {
    if (_isDisposed || _incomingController.isClosed) return;
    _incomingController.add(message);
  }

  /// Opens a streaming WebSocket subscription to the mediator for the given
  /// [Channel], filtering for VDIP message types only.
  ///
  /// Incoming VDIP messages are forwarded to [incomingMessages] and processed
  /// by any registered [messageProcessors]. Messages are deleted from the
  /// mediator after processing.
  ///
  /// This is optional — VDIP messages are also delivered via the Control Plane
  /// push path (see [dispatch]). Use this for lower-latency delivery when the
  /// app is in the foreground.
  ///
  /// Call [unsubscribe] to close the WebSocket connection.
  Future<
    CoreSDKStreamSubscription<MediatorMessage, MediatorStreamProcessingResult>
  >
  subscribe(Channel channel) async {
    if (_mediatorSubscription != null) return _mediatorSubscription!;

    final permanentChannelDid = channel.permanentChannelDid;
    if (permanentChannelDid == null) {
      throw StateError(
        'Channel is missing permanentChannelDid — cannot subscribe to VDIP',
      );
    }

    final didManager = await _connectionManager.getDidManagerForDid(
      _wallet,
      permanentChannelDid,
    );

    _mediatorSubscription = await _mediatorService.subscribe(
      didManager: didManager,
      mediatorDid: channel.mediatorDid,
    );

    _mediatorStreamSubscription = _mediatorSubscription!.listen((
      mediatorMessage,
    ) {
      final message = mediatorMessage.plainTextMessage;
      final type = message.type.toString();

      if (type != requestIssuanceMessageType &&
          type != issuedCredentialMessageType) {
        return MediatorStreamProcessingResult(keepMessage: true);
      }

      dispatch(message);

      for (final processor in _messageProcessors) {
        processor(message);
      }

      return MediatorStreamProcessingResult(keepMessage: false);
    });

    return _mediatorSubscription!;
  }

  /// Closes the streaming WebSocket subscription opened by [subscribe].
  Future<void> unsubscribe() async {
    await _mediatorStreamSubscription?.cancel();
    _mediatorStreamSubscription = null;
    await _mediatorSubscription?.dispose();
    _mediatorSubscription = null;
  }

  /// Disposes the [VdipClient] and closes the [incomingMessages] stream.
  Future<void> dispose() async {
    if (_isDisposed || _incomingController.isClosed) return;
    _isDisposed = true;
    await unsubscribe();
    await _incomingController.close();
  }
}

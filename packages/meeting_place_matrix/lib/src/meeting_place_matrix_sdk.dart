import 'dart:async';
import 'dart:typed_data';

import 'package:matrix/matrix.dart' as matrix;
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart'
    show ChannelActivity, ControlPlaneSDK;

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../meeting_place_matrix.dart';
import 'call/call_signal_mapper.dart';
import 'matrix_incoming_message.dart';
import 'matrix_outgoing_message.dart';
import 'matrix_room_history_query.dart';
import 'matrix_room_subscription.dart';
import 'matrix_sender_did_resolver.dart';
import 'matrix_service.dart';
import 'matrix_transport.dart';
import 'meeting_place_livekit_call_plugin.dart';

/// A [MeetingPlaceCoreSDK] backed by a Matrix homeserver.
///
/// Implements [MeetingPlaceCoreSDK] via composition, delegating all core
/// behaviour to an inner [_coreSDK] instance and intercepting only
/// Matrix-specific transport calls. The additional [matrixService] field
/// exposes matrix-specific APIs for consumers that need them
/// (e.g. `meeting_place_matrix`).
///
/// Use [MeetingPlaceMatrixSDK.create] to instantiate.
class MeetingPlaceMatrixSDK implements MeetingPlaceCoreSDK {
  MeetingPlaceMatrixSDK._({
    required MeetingPlaceCoreSDK coreSDK,
    required this.matrixService,
    required MeetingPlaceMatrixSdkOptions options,
    MeetingPlaceLiveKitCallPlugin? callPlugin,
  }) : _coreSDK = coreSDK,
       _callPlugin = callPlugin,
       _senderDidResolver = MatrixSenderDidResolver(
         coreSDK: coreSDK,
         matrixService: matrixService,
       ),
       _callSignalMapper = CallSignalMapper(coreSDK.controlPlaneEventsStream),
       _options = options;

  final MeetingPlaceCoreSDK _coreSDK;
  final MatrixSenderDidResolver _senderDidResolver;
  final CallSignalMapper _callSignalMapper;
  final MeetingPlaceLiveKitCallPlugin? _callPlugin;
  final MeetingPlaceMatrixSdkOptions _options;

  /// The underlying [MatrixService] — exposed for matrix-specific consumers
  /// (e.g. `meeting_place_matrix`) that need VoIP or OpenID token
  /// operations without those APIs leaking through [MeetingPlaceCoreSDK].
  final MatrixService matrixService;

  /// Whether audio/video calling is available.
  ///
  /// Returns `false` when no call plugin was configured (i.e.
  /// [MatrixConfig.livekitServiceUrl] was not set or no
  /// rtcDelegate / roomFactory were passed to [create]).
  bool get isCallSupported => _callPlugin != null;

  /// Stream of incoming call events. Empty when no plugin is configured.
  Stream<IncomingAudioVideoCallEvent> get incomingCalls =>
      _callPlugin?.incomingCalls ?? const Stream.empty();

  /// Stream of cancelled incoming-call events. Empty when no plugin
  /// is configured.
  Stream<IncomingAudioVideoCallEvent> get cancelledCalls =>
      _callPlugin?.cancelledCalls ?? const Stream.empty();

  /// Starts an outbound call and returns a live session handle.
  ///
  /// Throws [MeetingPlaceLiveKitCallOperationException] when no call plugin is
  /// configured. Check [isCallSupported] before calling.
  Future<AudioVideoCallSession> startCall({
    required String otherPartyChannelDid,
    required CallMediaType mediaType,
  }) {
    final plugin = _callPlugin;
    if (plugin == null) {
      throw const MeetingPlaceLiveKitCallOperationException(
        'Call plugin not configured — set livekitServiceUrl, rtcDelegate, and roomFactory in MatrixConfig/create()',
      );
    }
    return plugin.startCall(
      otherPartyChannelDid: otherPartyChannelDid,
      mediaType: mediaType,
    );
  }

  /// Accepts an incoming call by its [callId].
  ///
  /// Throws [MeetingPlaceLiveKitCallOperationException] when no call plugin is
  /// configured.
  Future<void> acceptCall({required String callId}) {
    final plugin = _callPlugin;
    if (plugin == null) {
      throw const MeetingPlaceLiveKitCallOperationException(
        'Call plugin not configured',
      );
    }
    return plugin.acceptCall(callId: callId);
  }

  /// Declines an incoming call by its [callId].
  ///
  /// Throws [MeetingPlaceLiveKitCallOperationException] when no call plugin is
  /// configured.
  Future<void> declineCall({required String callId}) {
    final plugin = _callPlugin;
    if (plugin == null) {
      throw const MeetingPlaceLiveKitCallOperationException(
        'Call plugin not configured',
      );
    }
    return plugin.declineCall(callId: callId);
  }

  /// Leaves the current active call. No-op when no plugin is configured.
  Future<void> leaveCurrentCall() =>
      _callPlugin?.leaveCurrentCall() ?? Future.value();

  /// The active call session, or `null` when no call is in progress.
  LiveKitCallSession? get activeCallSession => _callPlugin?.activeSession;

  static Future<MeetingPlaceMatrixSDK> create({
    required Wallet wallet,
    required RepositoryConfig repositoryConfig,
    required MatrixConfig config,
    MeetingPlaceMatrixSdkOptions options = const MeetingPlaceMatrixSdkOptions(),
    MeetingPlaceCoreSDKLogger? logger,
    matrix.WebRTCDelegate? rtcDelegate,
    LiveKitRoomFactory? roomFactory,
  }) async {
    MatrixService? matrixServiceRef;

    final coreSDK = await MeetingPlaceCoreSDK.create(
      wallet: wallet,
      repositoryConfig: repositoryConfig,
      config: config,
      options: options,
      logger: logger,
      channelTransportFactory: (controlPlaneSDK) {
        final svc = MatrixService(
          config: config,
          controlPlaneSDK: controlPlaneSDK,
          // TODO(SR): Inject correct logger instance.
          logger: DefaultMeetingPlaceMatrixSDKLogger(
            className: 'MatrixService',
          ),
        );
        matrixServiceRef = svc;
        return MatrixTransport(matrixService: svc);
      },
    );

    final sdk = MeetingPlaceMatrixSDK._(
      coreSDK: coreSDK,
      matrixService: matrixServiceRef!,
      options: options,
    );

    final livekitUrl = config.livekitServiceUrl;
    if (livekitUrl != null && rtcDelegate != null && roomFactory != null) {
      final plugin = MeetingPlaceLiveKitCallPlugin(
        livekitServiceUrl: livekitUrl,
        livekitSfuUrl: config.livekitSfuUrl,
        outgoingCallTimeout: config.outgoingCallTimeout,
        rtcDelegate: rtcDelegate,
        roomFactory: roomFactory,
      );
      plugin.initialize(sdk: sdk);
      return MeetingPlaceMatrixSDK._(
        coreSDK: coreSDK,
        matrixService: matrixServiceRef!,
        callPlugin: plugin,
        options: options,
      );
    }

    return sdk;
  }

  /// Broadcast stream of call signals from the control plane.
  ///
  /// Emits a [CallSignal] for each call-related [ChannelActivity] event:
  /// - [IncomingCallSignal] for `call-invite-video` and `call-invite-audio`
  /// - [CallDeclineSignal] for `call-decline`
  ///
  /// The plugin layer subscribes once and switches on the concrete type.
  Stream<CallSignal> get callSignals => _callSignalMapper.callSignals;

  // ---------------------------------------------------------------------------
  // MeetingPlaceCoreSDK — delegated members
  // ---------------------------------------------------------------------------

  @override
  Wallet get wallet => _coreSDK.wallet;

  @override
  VdipClient get vdip => _coreSDK.vdip;

  @override
  MeetingPlaceMatrixSdkOptions get options => _options;

  @override
  Stream<ChannelAttachmentEvent> get channelAttachments =>
      _coreSDK.channelAttachments;

  @override
  Stream<ControlPlaneStreamEvent> get controlPlaneEventsStream =>
      _coreSDK.controlPlaneEventsStream;

  @override
  MeetingPlaceTransport get channelTransport => _coreSDK.channelTransport;

  @override
  ControlPlaneSDK get controlPlaneSDK => _coreSDK.controlPlaneSDK;

  @override
  MeetingPlaceMediatorSDK get mediator => _coreSDK.mediator;

  @override
  set mediatorDid(String mediatorDid) => _coreSDK.mediatorDid = mediatorDid;

  @override
  set device(Device device) => _coreSDK.device = device;

  @override
  Future<DidManager> generateDid() => _coreSDK.generateDid();

  @override
  Future<DidManager> getDidManager(String did) => _coreSDK.getDidManager(did);

  @override
  Future<OobOfferSession> createOobFlow({
    required ContactCard contactCard,
    String? type,
    String? did,
    String? mediatorDid,
    String? externalRef,
  }) => _coreSDK.createOobFlow(
    contactCard: contactCard,
    type: type,
    did: did,
    mediatorDid: mediatorDid,
    externalRef: externalRef,
  );

  @override
  Future<OobAcceptanceSession> acceptOobFlow(
    Uri oobUrl, {
    required ContactCard contactCard,
    String? type,
    String? externalRef,
    String? did,
    List<Attachment>? attachments,
  }) => _coreSDK.acceptOobFlow(
    oobUrl,
    contactCard: contactCard,
    type: type,
    externalRef: externalRef,
    did: did,
    attachments: attachments,
  );

  @override
  Future<ValidateOfferPhraseResult> validateOfferPhrase(String phrase) =>
      _coreSDK.validateOfferPhrase(phrase);

  @override
  Future<Device> registerForPushNotifications(String deviceToken) =>
      _coreSDK.registerForPushNotifications(deviceToken);

  @override
  Future<RegisterForDidcommNotificationsResult>
  registerForDIDCommNotifications({
    String? mediatorDid,
    String? recipientDid,
  }) => _coreSDK.registerForDIDCommNotifications(
    mediatorDid: mediatorDid,
    recipientDid: recipientDid,
  );

  @override
  Future<PublishOfferResult<T>> publishOffer<T extends ConnectionOffer>({
    required String offerName,
    required SDKConnectionOfferType type,
    required ContactCard contactCard,
    required String offerDescription,
    String? customPhrase,
    DateTime? validUntil,
    int? maximumUsage,
    String? mediatorDid,
    String? metadata,
    String? externalRef,
    ChannelTransport transport = ChannelTransport.didcomm,
    int? score,
  }) => _coreSDK.publishOffer(
    offerName: offerName,
    type: type,
    contactCard: contactCard,
    offerDescription: offerDescription,
    customPhrase: customPhrase,
    validUntil: validUntil,
    maximumUsage: maximumUsage,
    mediatorDid: mediatorDid,
    metadata: metadata,
    externalRef: externalRef,
    transport: transport,
    score: score,
  );

  @override
  Future<FindOfferResult> findOffer({required String mnemonic}) =>
      _coreSDK.findOffer(mnemonic: mnemonic);

  @override
  Future<AcceptOfferResult<T>> acceptOffer<T extends ConnectionOffer>({
    required T connectionOffer,
    required ContactCard contactCard,
    required String senderInfo,
    String? externalRef,
  }) => _coreSDK.acceptOffer(
    connectionOffer: connectionOffer,
    contactCard: contactCard,
    senderInfo: senderInfo,
    externalRef: externalRef,
  );

  @override
  Future<Channel> approveConnectionRequest({
    required Channel channel,
    List<Attachment>? attachments,
  }) => _coreSDK.approveConnectionRequest(
    channel: channel,
    attachments: attachments,
  );

  @override
  Future<Group> rejectConnectionRequest({required Channel channel}) =>
      _coreSDK.rejectConnectionRequest(channel: channel);

  @override
  Future<void> leaveChannel(Channel channel) => _coreSDK.leaveChannel(channel);

  @override
  Future<void> removeMemberFromGroup({
    required String groupId,
    required String memberDid,
  }) => _coreSDK.removeMemberFromGroup(groupId: groupId, memberDid: memberDid);

  @override
  Future<void> sendOutreachInvitation({
    required ConnectionOffer outreachConnectionOffer,
    required ConnectionOffer inviteToConnectionOffer,
    required String messageToInclude,
    required String senderInfo,
  }) => _coreSDK.sendOutreachInvitation(
    outreachConnectionOffer: outreachConnectionOffer,
    inviteToConnectionOffer: inviteToConnectionOffer,
    messageToInclude: messageToInclude,
    senderInfo: senderInfo,
  );

  @override
  Future<void> processControlPlaneEvents({
    void Function(List<Object> errors)? onDone,
  }) => _coreSDK.processControlPlaneEvents(onDone: onDone);

  @override
  void disposeControlPlaneEventsStream() =>
      _coreSDK.disposeControlPlaneEventsStream();

  @override
  Future<void> dispose() async {
    await _callPlugin?.dispose();
    return _coreSDK.dispose();
  }

  @override
  Future<void> closeChannelAttachmentsStream() =>
      _coreSDK.closeChannelAttachmentsStream();

  @override
  Future<void> closeVdipStream() => _coreSDK.closeVdipStream();

  @override
  Future<List<String>> deleteControlPlaneEvents() =>
      _coreSDK.deleteControlPlaneEvents();

  @override
  Future<ConnectionOffer?> getConnectionOffer(String offerLink) =>
      _coreSDK.getConnectionOffer(offerLink);

  @override
  Future<ConnectionOffer> markConnectionOfferAsDeleted(
    ConnectionOffer connectionOffer,
  ) => _coreSDK.markConnectionOfferAsDeleted(connectionOffer);

  @override
  Future<void> deleteConnectionOffer(ConnectionOffer connectionOffer) =>
      _coreSDK.deleteConnectionOffer(connectionOffer);

  @override
  Future<Group?> getGroupByOfferLink(String offerLink) =>
      _coreSDK.getGroupByOfferLink(offerLink);

  @override
  Future<Group?> getGroupById(String groupId) => _coreSDK.getGroupById(groupId);

  @override
  Future<void> updateGroup(Group group) => _coreSDK.updateGroup(group);

  @override
  Future<List<ConnectionOffer>> listConnectionOffers() =>
      _coreSDK.listConnectionOffers();

  @override
  Future<List<ConnectionOffer>> getConnectionOffersByExternalRef(
    String externalRef,
  ) => _coreSDK.getConnectionOffersByExternalRef(externalRef);

  @override
  Future<UpdateScoreForOffersResult> updateScoreForOffers({
    required int score,
    required List<ConnectionOffer> offers,
  }) => _coreSDK.updateScoreForOffers(score: score, offers: offers);

  @override
  Future<void> updateLocalConnectionOffersScore({
    required int score,
    required List<ConnectionOffer> offers,
  }) => _coreSDK.updateLocalConnectionOffersScore(score: score, offers: offers);

  @override
  Future<Channel?> getChannelByDid(String did) => _coreSDK.getChannelByDid(did);

  @override
  Future<Channel?> getChannelByOtherPartyPermanentDid(String did) =>
      _coreSDK.getChannelByOtherPartyPermanentDid(did);

  @override
  Future<void> updateChannel(Channel channel) =>
      _coreSDK.updateChannel(channel);

  @override
  Future<String?> getMediatorDidFromUrl(String mediatorEndpoint) =>
      _coreSDK.getMediatorDidFromUrl(mediatorEndpoint);

  @override
  Future<String?> sendMediaMessage(
    Channel channel,
    Uint8List fileBytes, {
    required String contentType,
    String? filename,
    String? caption,
    Map<String, dynamic>? extraContent,
    ChannelNotification? notification,
  }) => _coreSDK.sendMediaMessage(
    channel,
    fileBytes,
    contentType: contentType,
    filename: filename,
    caption: caption,
    extraContent: extraContent,
    notification: notification,
  );

  @override
  Future<Uint8List> downloadMedia(Channel channel, MediaReference reference) =>
      _coreSDK.downloadMedia(channel, reference);

  @override
  Future<Channel> findChannelByDid(String did) =>
      _coreSDK.findChannelByDid(did);

  @override
  Future<Channel?> findChannelByDidOrNull(String did) =>
      _coreSDK.findChannelByDidOrNull(did);

  @override
  Future<void> updateMessageSyncMarker(Channel channel, String eventId) =>
      _coreSDK.updateMessageSyncMarker(channel, eventId);

  @override
  Future<void> notifyChannel(ChannelNotification notification) =>
      _coreSDK.notifyChannel(notification);

  // ---------------------------------------------------------------------------
  // Matrix transport overrides
  // ---------------------------------------------------------------------------

  @override
  Future<IncomingMessageHandle> subscribe(
    IncomingMessageSubscription subscription,
  ) async {
    switch (subscription) {
      case MatrixRoomSubscription s:
        final channel = await _coreSDK.findChannelByDid(s.receiverDid);
        final didManager = await _coreSDK.getDidManager(s.receiverDid);
        final participantDids = await _senderDidResolver.fetchParticipantDids(
          channel,
        );
        final stream = _coreSDK.channelTransport.subscribe(
          channel: channel,
          didManager: didManager,
          options: s.options,
          participantDids: participantDids,
        );
        final mapped = stream
            .asyncMap((e) async {
              if (_isTimelineEvent(e)) {
                await _advanceMatrixSyncMarker(s.receiverDid, e.id);
              }
              return _toMatrixIncoming(e, s.receiverDid);
            })
            .where((e) => e != null)
            .cast<MatrixIncomingMessage>();
        return _MatrixIncomingMessageHandle(mapped);
      case DidCommSubscription _:
        return _coreSDK.subscribe(subscription);
      default:
        return _coreSDK.subscribe(subscription);
    }
  }

  @override
  Future<String?> sendMessage(OutgoingMessage message) async {
    switch (message) {
      case MatrixOutgoingMessage m:
        final channel = await _coreSDK.findChannelByDid(m.senderDid);
        final didManager = await _coreSDK.getDidManager(m.senderDid);
        final eventId = await _coreSDK.channelTransport.sendEvent(
          channel: channel,
          type: m.type,
          content: m.content,
          didManager: didManager,
        );
        final notification = m.notification;
        if (notification != null) {
          unawaited(
            _coreSDK
                .notifyChannel(notification)
                .catchError((Object _, StackTrace _) {}),
          );
        }
        return eventId;
      default:
        return _coreSDK.sendMessage(message);
    }
  }

  @override
  Future<List<IncomingMessage>> fetchHistory(HistoryQuery query) async {
    switch (query) {
      case MatrixRoomHistoryQuery q:
        final channel = await _coreSDK.findChannelByDid(q.receiverDid);
        final didManager = await _coreSDK.getDidManager(q.receiverDid);
        final events = await _coreSDK.channelTransport.fetchHistory(
          channel: channel,
          didManager: didManager,
          limit: q.limit,
          since: q.since,
        );

        if (q.updateChannelSyncMarker && events.isNotEmpty) {
          // Advance the marker to the newest event by timestamp, not by list
          // position. Matrix history is returned newest-first, so `events.last`
          // is the oldest fetched event. Anchoring the marker there leaves
          // newer events "unseen", so the next sync re-fetches and re-counts
          // them, inflating `seqNo` and the unread badge.
          final newestEvent = events.reduce(
            (a, b) => b.timestamp.isAfter(a.timestamp) ? b : a,
          );
          await _coreSDK.updateMessageSyncMarker(channel, newestEvent.id);
        }

        return Future.wait(
          events.map((e) => _toMatrixIncoming(e, q.receiverDid)),
        ).then((mapped) => mapped.whereType<MatrixIncomingMessage>().toList());
      case DidCommHistoryQuery _:
        return _coreSDK.fetchHistory(query);
      default:
        return _coreSDK.fetchHistory(query);
    }
  }

  bool _isTimelineEvent(TransportEvent event) {
    return event.type != 'm.typing' && event.type != 'm.receipt';
  }

  Future<MatrixIncomingMessage?> _toMatrixIncoming(
    TransportEvent e,
    String receiverDid,
  ) async {
    final resolved =
        e.senderDid ??
        await _senderDidResolver.resolve(
          receiverDid: receiverDid,
          matrixUserId: e.metadata?['sender_id'] as String,
        );
    if (resolved == null) return null;

    return MatrixIncomingMessage(
      senderDid: resolved,
      timestamp: e.timestamp,
      roomId: e.channelId,
      eventId: e.id,
      type: e.type,
      content: e.content,
      isFromMe: e.isFromMe,
      stateKey: e.metadata?['state_key'] as String?,
    );
  }

  Future<void> _advanceMatrixSyncMarker(
    String receiverDid,
    String eventId,
  ) async {
    final channel = await _coreSDK.findChannelByDidOrNull(receiverDid);
    if (channel == null) return;
    await _coreSDK.updateMessageSyncMarker(channel, eventId);
  }
}

class _MatrixIncomingMessageHandle implements IncomingMessageHandle {
  _MatrixIncomingMessageHandle(this.stream);

  @override
  final Stream<IncomingMessage> stream;

  @override
  Future<void> dispose() async {}
}

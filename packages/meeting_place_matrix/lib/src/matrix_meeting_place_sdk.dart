import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meta/meta.dart';
import 'package:ssi/ssi.dart';

import 'matrix_config.dart';
import 'matrix_incoming_message.dart';
import 'matrix_outgoing_message.dart';
import 'matrix_room_history_query.dart';
import 'matrix_room_subscription.dart';
import 'matrix_service.dart';
import 'matrix_transport.dart';

/// A [MeetingPlaceCoreSDK] backed by a Matrix homeserver.
///
/// Extends [MeetingPlaceCoreSDK] so consumers interact with a single object
/// and do not need to declare `meeting_place_core` as an explicit dependency.
/// The additional [matrixService] field exposes matrix-specific APIs for
/// consumers that need them (e.g. `meeting_place_matrix_livekit`).
///
/// Use [MeetingPlaceMatrixSDK.create] to instantiate.
class MeetingPlaceMatrixSDK extends MeetingPlaceCoreSDK {
  MeetingPlaceMatrixSDK._({
    required MeetingPlaceCoreSDK base,
    required this.matrixService,
  }) : super.extend(base);

  /// The underlying [MatrixService] — exposed for matrix-specific consumers
  /// (e.g. `meeting_place_matrix_livekit`) that need VoIP or OpenID token
  /// operations without those APIs leaking through [MeetingPlaceCoreSDK].
  final MatrixService matrixService;

  static Future<MeetingPlaceMatrixSDK> create({
    required Wallet wallet,
    required RepositoryConfig repositoryConfig,
    required MatrixConfig config,
    MeetingPlaceCoreSDKOptions options = const MeetingPlaceCoreSDKOptions(),
    MeetingPlaceCoreSDKLogger? logger,
  }) async {
    MatrixService? matrixServiceRef;

    final base = await MeetingPlaceCoreSDK.create(
      wallet: wallet,
      repositoryConfig: repositoryConfig,
      config: config,
      options: options,
      logger: logger,
      channelTransportFactory: (controlPlaneSDK) {
        final svc = MatrixService(
          config: config,
          controlPlaneSDK: controlPlaneSDK,
          logger:
              logger ??
              DefaultMeetingPlaceCoreSDKLogger(className: 'MatrixService'),
        );
        matrixServiceRef = svc;
        return MatrixTransport(matrixService: svc);
      },
    );

    return MeetingPlaceMatrixSDK._(
      base: base,
      matrixService: matrixServiceRef!,
    );
  }

  // ---------------------------------------------------------------------------
  // Matrix transport overrides
  // ---------------------------------------------------------------------------

  @override
  Future<IncomingMessageHandle> subscribe(
    IncomingMessageSubscription subscription,
  ) async {
    switch (subscription) {
      case MatrixRoomSubscription s:
        final channel = await findChannelByDid(s.receiverDid);
        final didManager = await getDidManager(s.receiverDid);
        final participantDids = await _fetchParticipantDids(channel);
        final stream = channelTransport.subscribe(
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
              return _toMatrixIncoming(e);
            })
            .where((e) => e != null)
            .cast<MatrixIncomingMessage>();
        return _MatrixIncomingMessageHandle(mapped);
      case DidCommSubscription _:
        return super.subscribe(subscription);
      default:
        return super.subscribe(subscription);
    }
  }

  @override
  Future<String?> sendMessage(OutgoingMessage message) async {
    switch (message) {
      case MatrixOutgoingMessage m:
        final channel = await findChannelByDid(m.senderDid);
        final didManager = await getDidManager(m.senderDid);
        final eventId = await channelTransport.sendEvent(
          channel: channel,
          type: m.type,
          content: m.content,
          didManager: didManager,
        );
        final notification = m.notification;
        if (notification != null) {
          unawaited(
            notifyChannel(notification).catchError((Object _, StackTrace _) {}),
          );
        }
        return eventId;
      default:
        return super.sendMessage(message);
    }
  }

  @override
  Future<List<IncomingMessage>> fetchHistory(HistoryQuery query) async {
    switch (query) {
      case MatrixRoomHistoryQuery q:
        final channel = await findChannelByDid(q.receiverDid);
        final didManager = await getDidManager(q.receiverDid);
        final events = await channelTransport.fetchHistory(
          channel: channel,
          didManager: didManager,
          limit: q.limit,
          since: q.since,
        );
        if (q.updateChannelSyncMarker && events.isNotEmpty) {
          await updateMatrixSyncMarker(channel, events.last.id);
        }
        return events
            .map(_toMatrixIncoming)
            .whereType<MatrixIncomingMessage>()
            .toList();
      case DidCommHistoryQuery _:
        return super.fetchHistory(query);
      default:
        return super.fetchHistory(query);
    }
  }

  @visibleForTesting
  @override
  Future<void> waitForRoomEncryptionReady({
    required String localDid,
    required Iterable<String> expectedDids,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final channel = await findChannelByDid(localDid);
    final didManager = await getDidManager(localDid);
    final roomId = await matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    await matrixService.waitForRoomEncryptionReady(
      roomId: roomId,
      didManager: didManager,
      expectedDids: expectedDids,
      timeout: timeout,
    );
  }

  // ---------------------------------------------------------------------------
  // Private Matrix helpers
  // ---------------------------------------------------------------------------

  bool _isTimelineEvent(TransportEvent event) {
    return event.type != 'm.typing' && event.type != 'm.receipt';
  }

  MatrixIncomingMessage? _toMatrixIncoming(TransportEvent e) {
    final senderDid = e.senderDid;
    if (senderDid == null) return null;
    return MatrixIncomingMessage(
      senderDid: senderDid,
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
    final channel = await findChannelByDidOrNull(receiverDid);
    if (channel == null) return;
    await updateMatrixSyncMarker(channel, eventId);
  }

  Future<List<String>> _fetchParticipantDids(Channel channel) async {
    if (channel.type == ChannelType.group) {
      final group = await getGroupByOfferLink(channel.offerLink);
      if (group == null) return [];
      return group.members.map((m) => m.did).toList();
    }
    final peer = channel.otherPartyPermanentChannelDid;
    if (peer != null) return [peer];
    return [];
  }
}

class _MatrixIncomingMessageHandle implements IncomingMessageHandle {
  _MatrixIncomingMessageHandle(this.stream);

  @override
  final Stream<IncomingMessage> stream;

  @override
  Future<void> dispose() async {}
}

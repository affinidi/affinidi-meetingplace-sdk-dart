import 'dart:typed_data';

import 'package:meeting_place_core/meeting_place_core.dart'
    show
        Channel,
        MeetingPlaceTransport,
        TransportEvent,
        TransportSubscriptionOptions;
import 'package:ssi/ssi.dart';

import 'matrix_media_exception.dart';
import 'matrix_service.dart';
import 'matrix_subscription_options.dart';
import 'matrix_user_id_binding.dart';

/// [MeetingPlaceTransport] implementation backed by [MatrixService].
///
/// Maps each interface method to the corresponding [MatrixService] operation,
/// resolving room IDs from [Channel] internally. Sender DID resolution uses
/// [participantDids] supplied by the caller so that [MatrixService] and its
/// [matrix_user_id_binding] logic stay transport-internal.
class MatrixTransport implements MeetingPlaceTransport {
  MatrixTransport({required MatrixService matrixService})
    : _matrixService = matrixService;

  final MatrixService _matrixService;

  @override
  Future<void> authenticate(DidManager didManager) =>
      _matrixService.loginWithDid(didManager).then((_) {});

  @override
  Future<void> setupChannel({
    required Channel channel,
    required DidManager didManager,
    List<String> participantDids = const [],
  }) async {
    final channelDid = channel.isGroup
        ? channel.otherPartyPermanentChannelDid!
        : (await didManager.getDidDocument()).id;
    await _matrixService.createRoom(
      didManager: didManager,
      channelDid: channelDid,
      otherPartyChannelDid: channel.isGroup
          ? null
          : (participantDids.isNotEmpty ? participantDids.first : null),
      inviteUsers: channel.isGroup ? [] : participantDids,
    );
  }

  @override
  Future<void> joinChannel({
    required Channel channel,
    required DidManager didManager,
  }) async {
    final channelDid = channel.isGroup
        ? channel.otherPartyPermanentChannelDid!
        : (await didManager.getDidDocument()).id;
    final otherPartyChannelDid = channel.isGroup
        ? null
        : channel.otherPartyPermanentChannelDid;
    await _matrixService.joinChannelRoom(
      didManager: didManager,
      channelDid: channelDid,
      otherPartyChannelDid: otherPartyChannelDid,
    );
  }

  @override
  Future<void> leaveChannel({
    required Channel channel,
    required DidManager didManager,
  }) async {
    final roomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    await _matrixService.leaveRoom(roomId, didManager: didManager);
  }

  @override
  Future<void> inviteToChannel({
    required Channel channel,
    required String participantDid,
    required DidManager didManager,
  }) async {
    final roomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    await _matrixService.inviteUser(
      roomId,
      did: participantDid,
      didManager: didManager,
    );
  }

  @override
  Future<void> removeFromChannel({
    required Channel channel,
    required String participantDid,
    required DidManager didManager,
  }) async {
    final roomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    await _matrixService.kickUser(
      roomId,
      did: participantDid,
      didManager: didManager,
    );
  }

  @override
  Stream<TransportEvent> subscribe({
    required Channel channel,
    required DidManager didManager,
    TransportSubscriptionOptions? options,
    List<String> participantDids = const [],
  }) async* {
    final roomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );

    final matrixOptions = options == null
        ? null
        : MatrixSubscriptionOptions(
            excludeSelf: options.excludeSelf,
            syncGracePeriodDuration: options.syncGracePeriodDuration,
            keepSyncActiveOnEnd: options.keepSyncActiveOnEnd,
          );

    final cutoff = DateTime.now().toUtc();

    await for (final e in _matrixService.subscribeToRoom(
      roomId,
      didManager: didManager,
      options: matrixOptions ?? const MatrixSubscriptionOptions(),
    )) {
      final isTimeline = e.type != 'm.typing' && e.type != 'm.receipt';
      if (isTimeline && e.timestamp.isBefore(cutoff)) continue;

      final senderDid =
          e.senderDid ??
          _resolveSenderDid(
            matrixUserId: e.userId,
            receiverDid: (await didManager.getDidDocument()).id,
            participantDids: participantDids,
            serverName: _matrixService.serverName,
          );

      if (senderDid == null && isTimeline) continue;

      yield TransportEvent(
        id: e.id,
        type: e.type,
        content: e.content,
        channelId: roomId,
        timestamp: e.timestamp,
        senderDid: senderDid,
        senderId: e.userId,
        stateKey: e.stateKey,
        isFromMe: e.isFromMe,
        isReplay: e.isReplay,
      );
    }
  }

  @override
  Future<List<TransportEvent>> fetchHistory({
    required Channel channel,
    required DidManager didManager,
    int? limit,
    String? sinceEventId,
  }) async {
    final roomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    final events = await _matrixService.fetchRoomHistory(
      roomId,
      didManager: didManager,
      limit: limit ?? 50,
      sinceEventId: sinceEventId,
    );
    return events
        .map(
          (e) => TransportEvent(
            id: e.id,
            type: e.type,
            content: e.content,
            channelId: roomId,
            timestamp: e.timestamp,
            senderDid: e.senderDid,
            senderId: e.userId,
            stateKey: e.stateKey,
            isFromMe: e.isFromMe,
            isReplay: true,
          ),
        )
        .toList();
  }

  @override
  Future<String?> getLastEventId({
    required Channel channel,
    required DidManager didManager,
  }) async {
    final roomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    return _matrixService.getLatestEventId(roomId, didManager: didManager);
  }

  @override
  Future<String?> sendEvent({
    required Channel channel,
    required String type,
    required Map<String, dynamic> content,
    required DidManager didManager,
  }) async {
    final roomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    return _matrixService.sendRoomEvent(
      roomId,
      type,
      content,
      didManager: didManager,
    );
  }

  @override
  Future<String?> sendFile({
    required Channel channel,
    required Uint8List bytes,
    required String contentType,
    String? filename,
    required DidManager didManager,
    Map<String, dynamic>? extraContent,
  }) async {
    final maxSize = await _matrixService.getMediaConfig(didManager: didManager);
    if (maxSize != null && bytes.length > maxSize) {
      throw MatrixMediaException.tooLarge(maxBytes: maxSize);
    }

    final roomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    return _matrixService.sendFileEvent(
      roomId,
      bytes: bytes,
      contentType: contentType,
      filename: filename,
      didManager: didManager,
      extraContent: extraContent,
    );
  }

  @override
  Future<Uint8List> downloadFile({
    required Channel channel,
    required String fileId,
    required DidManager didManager,
  }) async {
    final roomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    return _matrixService.downloadFileForEvent(
      roomId,
      fileId,
      didManager: didManager,
    );
  }

  @override
  Future<void> awaitChannelReady({
    required Channel channel,
    required DidManager didManager,
    required Iterable<String> participantDids,
    Duration? timeout,
  }) async {
    final roomId = await _matrixService.resolveRoomIdForChannel(
      didManager: didManager,
      channel: channel,
    );
    await _matrixService.waitForRoomEncryptionReady(
      roomId: roomId,
      didManager: didManager,
      expectedDids: participantDids,
      timeout: timeout ?? const Duration(seconds: 15),
    );
  }

  @override
  String? get serverId => _matrixService.serverName;

  @override
  Future<void> dispose() => _matrixService.dispose();

  @override
  bool isNewInboundMessage(TransportEvent event) {
    if (event.isFromMe) return false;
    if (event.type != 'm.room.message') return false;
    final relatesTo = event.content['m.relates_to'];
    if (relatesTo is Map && relatesTo['rel_type'] == 'm.replace') return false;
    return true;
  }

  String? _resolveSenderDid({
    required String matrixUserId,
    required String receiverDid,
    required List<String> participantDids,
    required String serverName,
  }) {
    bool matches(String did) =>
        deriveMatrixUserId(did, serverName) == matrixUserId;
    if (matches(receiverDid)) return receiverDid;
    for (final did in participantDids) {
      if (matches(did)) return did;
    }
    return null;
  }
}

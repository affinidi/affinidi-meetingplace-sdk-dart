import 'dart:typed_data';

import 'package:ssi/ssi.dart';

import '../entity/channel.dart';
import 'meeting_place_transport.dart';
import 'transport_event.dart';
import 'transport_subscription_options.dart';

/// Default no-op channel transport.
class NopTransport implements MeetingPlaceTransport {
  @override
  Future<void> authenticate(DidManager didManager) async {}

  @override
  Future<String> setupChannel({
    required Channel channel,
    required DidManager didManager,
    List<String> participantDids = const [],
  }) async => '';

  @override
  Future<String> joinRoomById({
    required DidManager didManager,
    required String roomId,
  }) async => roomId;

  @override
  Future<String> joinChannel({
    required Channel channel,
    required DidManager didManager,
  }) async => channel.matrixRoomId ?? '';

  @override
  Future<void> leaveChannel({
    required Channel channel,
    required DidManager didManager,
  }) async {}

  @override
  Future<void> inviteToChannel({
    required Channel channel,
    required String participantDid,
    required DidManager didManager,
  }) async {}

  @override
  Future<void> removeFromChannel({
    required Channel channel,
    required String participantDid,
    required DidManager didManager,
  }) async {}

  @override
  Stream<TransportEvent> subscribe({
    required Channel channel,
    required DidManager didManager,
    TransportSubscriptionOptions? options,
    List<String> participantDids = const [],
  }) => const Stream.empty();

  @override
  Future<List<TransportEvent>> fetchHistory({
    required Channel channel,
    required DidManager didManager,
    int? limit,
    String? since,
    bool forceSync = false,
  }) async => [];

  @override
  Future<String?> getLastEventId({
    required Channel channel,
    required DidManager didManager,
  }) async => null;

  @override
  Future<String?> sendEvent({
    required Channel channel,
    required String type,
    required Map<String, dynamic> content,
    required DidManager didManager,
  }) async => null;

  @override
  Future<String?> sendFile({
    required Channel channel,
    required Uint8List bytes,
    required String contentType,
    String? filename,
    required DidManager didManager,
    Map<String, dynamic>? extraContent,
  }) => throw UnimplementedError('Channel transport not configured');

  @override
  Future<Uint8List> downloadFile({
    required Channel channel,
    required String fileId,
    required DidManager didManager,
  }) => throw UnimplementedError('Channel transport not configured');

  @override
  String? get serverId => null;

  @override
  bool isNewInboundMessage(TransportEvent event) => false;

  @override
  Future<void> dispose() async {}
}

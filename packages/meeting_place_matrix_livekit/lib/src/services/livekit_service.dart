import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:meeting_place_core/meeting_place_core.dart';

import '../models/audio_video_call_participant.dart';

/// Signature for E2EE state change notifications from [LiveKitService].
///
/// [participantIdentity] is the LiveKit participant identity string.
/// [state] is the new [E2EEState] reported by the FrameCryptor.
typedef OnE2EEStateChanged =
    void Function(String participantIdentity, E2EEState state);

/// Signature for participant departure notifications from [LiveKitService].
///
/// Called when a remote participant disconnects from the room.
/// [participantIdentity] is the identity of the participant who left.
typedef OnParticipantDisconnected = void Function(String participantIdentity);

/// Manages a single LiveKit Room lifecycle.
///
/// Owns the raw livekit_client types — they must not leak out of this class
/// into AudioVideoCallService or any other layer. Converts LiveKit events into
/// [AudioVideoCallParticipant] domain objects before publishing.
///
/// Modelled after the MatrixService session lifecycle pattern.
class LiveKitService {
  LiveKitService({MeetingPlaceCoreSDKLogger? logger})
    : _logger =
          logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);

  static const _className = 'LiveKitService';

  final MeetingPlaceCoreSDKLogger _logger;
  Room? _room;
  bool _isDisposed = false;
  EventsListener<RoomEvent>? _roomListener;

  /// Identity of this client's participant in the room, or `null` when not
  /// connected.
  String? get ownIdentity => _room?.localParticipant?.identity;

  /// Connects to the LiveKit SFU using [url] and [token].
  ///
  /// [url] is the LiveKit server URL (e.g. `wss://livekit.example.com`).
  /// [token] is the JWT obtained from lk-jwt-service via `SfuTokenService`.
  ///
  /// Pass a [keyProvider] to enable per-participant E2EE via FrameCryptor.
  /// When provided, [onE2EEStateChanged] is called whenever a participant's
  /// encryption state changes.
  ///
  /// [onParticipantDisconnected] is called when a remote participant leaves
  /// the room, giving the caller the opportunity to rotate encryption keys.
  ///
  /// [onParticipantsChanged] is called whenever any track is published,
  /// unpublished, muted, or unmuted — for both local and remote participants.
  /// Use this to refresh the participant list in the call service so the UI
  /// stays in sync after camera or microphone toggles.
  Future<void> connect({
    required String url,
    required String token,
    BaseKeyProvider? keyProvider,
    OnE2EEStateChanged? onE2EEStateChanged,
    OnParticipantDisconnected? onParticipantDisconnected,
    void Function()? onParticipantsChanged,
  }) async {
    const methodName = 'connect';
    if (_isDisposed) return;
    _logger.info('url=$url e2ee=${keyProvider != null}', name: methodName);

    final e2eeOptions = keyProvider != null
        ? E2EEOptions(keyProvider: keyProvider)
        : null;

    final room = Room(roomOptions: RoomOptions(e2eeOptions: e2eeOptions));

    final needsListener =
        (e2eeOptions != null && onE2EEStateChanged != null) ||
        onParticipantDisconnected != null ||
        onParticipantsChanged != null;

    if (needsListener) {
      final listener = room.createListener();
      if (e2eeOptions != null && onE2EEStateChanged != null) {
        listener.on<TrackE2EEStateEvent>((event) {
          onE2EEStateChanged(event.participant.identity, event.state);
        });
      }
      if (onParticipantDisconnected != null) {
        listener.on<ParticipantDisconnectedEvent>((event) {
          onParticipantDisconnected(event.participant.identity);
        });
      }
      if (onParticipantsChanged != null) {
        listener
          ..on<LocalTrackPublishedEvent>((_) => onParticipantsChanged())
          ..on<LocalTrackUnpublishedEvent>((_) => onParticipantsChanged())
          ..on<TrackMutedEvent>((_) => onParticipantsChanged())
          ..on<TrackUnmutedEvent>((_) => onParticipantsChanged())
          ..on<TrackSubscribedEvent>((_) => onParticipantsChanged())
          ..on<TrackUnsubscribedEvent>((_) => onParticipantsChanged())
          ..on<ParticipantConnectedEvent>((_) => onParticipantsChanged());
      }
      _roomListener = listener;
    }

    // Assign before connecting so that disconnect() can stop the room even if
    // connect() throws (e.g. ICE timeout). Without this, the abandoned Room
    // object keeps its internal reconnect loop running indefinitely.
    _room = room;
    await room.connect(url, token);
    _logger.info(
      'Room connected identity=${room.localParticipant?.identity}',
      name: methodName,
    );
  }

  /// Disconnects from the LiveKit room and releases all resources.
  Future<void> disconnect() async {
    const methodName = 'disconnect';
    _logger.info('Releasing room', name: methodName);
    _isDisposed = true;
    await _roomListener?.dispose();
    _roomListener = null;
    await _room?.disconnect();
    _room = null;
    _logger.info('Done', name: methodName);
  }

  /// Enables or disables the local microphone track.
  Future<void> setMicrophoneEnabled(bool enabled) async {
    _logger.info('Microphone enabled: $enabled', name: 'setMicrophoneEnabled');
    await _room?.localParticipant?.setMicrophoneEnabled(enabled);
  }

  /// Enables or disables the local camera track.
  Future<void> setCameraEnabled(bool enabled) async {
    _logger.info('Camera enabled: $enabled', name: 'setCameraEnabled');
    await _room?.localParticipant?.setCameraEnabled(enabled);
  }

  /// Routes audio through the loudspeaker ([enabled] = true) or earpiece
  /// ([enabled] = false).
  ///
  /// On platforms that do not support speakerphone routing (macOS, web) this
  /// is a no-op.
  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    _logger.info(
      'Speakerphone enabled: $enabled',
      name: 'setSpeakerphoneEnabled',
    );
    await Hardware.instance.setSpeakerphoneOn(enabled);
  }

  /// Snapshot of all current participants mapped to domain objects.
  List<AudioVideoCallParticipant> get participants {
    final room = _room;
    if (room == null) return const [];

    final local = room.localParticipant;
    final remotes = room.remoteParticipants.values;

    return [
      if (local != null)
        AudioVideoCallParticipant(
          identity: local.identity,
          hasVideo: _hasRenderableVideo(local),
          hasAudio: local.isMicrophoneEnabled(),
          isSpeaking: local.isSpeaking,
          isLocal: true,
        ),
      for (final p in remotes)
        AudioVideoCallParticipant(
          identity: p.identity,
          hasVideo: _hasRenderableVideo(p),
          hasAudio: p.isMicrophoneEnabled(),
          isSpeaking: p.isSpeaking,
        ),
    ];
  }

  /// Whether [participant] has a subscribed, unmuted video track that can
  /// actually be rendered right now.
  ///
  /// This intentionally mirrors the track selection in [buildVideoView] so the
  /// `hasVideo` flag never reports `true` for a track that would render blank.
  /// A remote's camera publication can exist and be unmuted before its track
  /// is subscribed and decodable on this device; until then the tile shows the
  /// avatar placeholder rather than an empty frame.
  bool _hasRenderableVideo(Participant participant) =>
      _renderableVideoTrack(participant) != null;

  VideoTrack? _renderableVideoTrack(Participant participant) {
    final pub = participant.videoTrackPublications
        .where((pub) => pub.track != null && !pub.muted)
        .firstOrNull;
    return pub?.track as VideoTrack?;
  }

  /// Builds a video view widget for the participant with [identity].
  ///
  /// Returns `null` when the room is not connected, the participant is not
  /// found, or the participant has no active video track.
  ///
  /// Pass `mirror: true` for the local camera preview to match the
  /// selfie-camera convention.
  Widget? buildVideoView(String identity, {bool mirror = false}) {
    final room = _room;
    if (room == null) return null;

    final Participant? participant;
    if (room.localParticipant?.identity == identity) {
      participant = room.localParticipant;
    } else {
      participant = room.remoteParticipants[identity];
    }
    if (participant == null) return null;

    final videoTrack = _renderableVideoTrack(participant);
    if (videoTrack == null) return null;

    return VideoTrackRenderer(
      videoTrack,
      fit: VideoViewFit.cover,
      mirrorMode: mirror ? VideoViewMirrorMode.mirror : VideoViewMirrorMode.off,
    );
  }
}

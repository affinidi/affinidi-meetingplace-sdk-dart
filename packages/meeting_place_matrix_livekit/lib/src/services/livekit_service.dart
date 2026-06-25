import 'dart:async';

import 'package:livekit_client/livekit_client.dart';
import 'package:meeting_place_chat/meeting_place_chat.dart'
    show AudioVideoCallParticipant;
import 'package:meeting_place_core/meeting_place_core.dart';

import 'participant_video_extension.dart';
import 'room_participants_extension.dart';

/// Signature for E2EE state change notifications from [LivekitService].
///
/// [participantId] is the participant's stable identifier.
/// [state] is the new [E2EEState] reported by the FrameCryptor.
typedef OnE2EEStateChanged =
    void Function(String participantId, E2EEState state);

/// Signature for participant departure notifications from [LivekitService].
///
/// Called when another participant disconnects from the room.
/// [participantId] is the identifier of the participant who left.
typedef OnParticipantDisconnected = void Function(String participantId);

/// Manages a single LiveKit Room lifecycle.
///
/// Owns the raw livekit_client types — they must not leak out of this class
/// into AudioVideoCallService or any other layer. Converts LiveKit events into
/// [AudioVideoCallParticipant] domain objects before publishing.
///
/// Modelled after the MatrixService session lifecycle pattern.
class LivekitService {
  LivekitService({MeetingPlaceCoreSDKLogger? logger})
    : _logger = logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _logKey);

  static const _logKey = 'LivekitService';

  final MeetingPlaceCoreSDKLogger _logger;
  Room? _room;
  bool _isDisposed = false;
  EventsListener<RoomEvent>? _roomListener;

  /// Maps a participant id (the LiveKit identity, a Matrix user id) to the
  /// permanent channel DID of that participant. Populated at [connect] time so
  /// the [participants] getter can stamp each domain participant with its DID
  /// without exposing transport identifiers to higher layers.
  Map<String, String> _participantIdToDid = const {};

  /// Stable id of this client's participant in the room, or `null` when not
  /// connected.
  String? get ownParticipantId => _room?.localParticipant?.identity;

  /// Connects to the LiveKit SFU using [url] and [token].
  ///
  /// [url] is the LiveKit server URL (e.g. `wss://livekit.example.com`).
  /// [token] is the JWT obtained from lk-jwt-service via `SfuTokenService`.
  ///
  /// [keyProvider] enables per-participant E2EE via FrameCryptor. All call
  /// traffic is encrypted, so it is always required. [onE2EEStateChanged] is
  /// called whenever a participant's encryption state changes.
  ///
  /// [onParticipantDisconnected] is called when another participant leaves
  /// the room, giving the owner the opportunity to rotate encryption keys.
  ///
  /// [onParticipantsChanged] is called whenever any track is published,
  /// unpublished, muted, or unmuted — for own and other participants.
  /// Use this to refresh the participant list in the call service so the UI
  /// stays in sync after camera or microphone toggles.
  ///
  /// [participantIdToDid] maps each expected participant id (Matrix user id)
  /// to its permanent channel DID. The [participants] getter uses it to expose
  /// a DID on each domain participant.
  Future<void> connect({
    required String url,
    required String token,
    required BaseKeyProvider keyProvider,
    Map<String, String> participantIdToDid = const {},
    OnE2EEStateChanged? onE2EEStateChanged,
    OnParticipantDisconnected? onParticipantDisconnected,
    void Function()? onParticipantsChanged,
  }) async {
    if (_isDisposed) return;
    _participantIdToDid = participantIdToDid;
    _logger.info('connect: url=$url', name: _logKey);

    final e2eeOptions = E2EEOptions(keyProvider: keyProvider);

    final room = Room(roomOptions: RoomOptions(e2eeOptions: e2eeOptions));

    final needsListener =
        onE2EEStateChanged != null ||
        onParticipantDisconnected != null ||
        onParticipantsChanged != null;

    if (needsListener) {
      final listener = room.createListener();
      if (onE2EEStateChanged != null) {
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
      'connect: Room connected identity=${room.localParticipant?.identity}',
      name: _logKey,
    );
  }

  /// Disconnects from the LiveKit room and releases all resources.
  Future<void> disconnect() async {
    _logger.info('disconnect: Releasing room', name: _logKey);
    _isDisposed = true;
    await _roomListener?.dispose();
    _roomListener = null;
    await _room?.disconnect();
    _room = null;
    _logger.info('disconnect: Done', name: _logKey);
  }

  /// Enables or disables the local microphone track.
  Future<void> setMicrophoneEnabled(bool enabled) async {
    _logger.info('setMicrophoneEnabled: enabled=$enabled', name: _logKey);
    await _room?.localParticipant?.setMicrophoneEnabled(enabled);
  }

  /// Enables or disables the local camera track.
  Future<void> setCameraEnabled(bool enabled) async {
    _logger.info('setCameraEnabled: enabled=$enabled', name: _logKey);
    await _room?.localParticipant?.setCameraEnabled(enabled);
  }

  /// Switches between front and rear camera.
  Future<void> switchCamera() async {
    _logger.info('switchCamera: Switching camera', name: _logKey);
    final track =
        _room?.localParticipant?.videoTrackPublications.firstOrNull?.track;
    if (track is! LocalVideoTrack) {
      _logger.warning('switchCamera: no local video track', name: _logKey);
      return;
    }
    final options = track.currentOptions;
    if (options is! CameraCaptureOptions) {
      _logger.warning(
        'switchCamera: track is not a camera track',
        name: _logKey,
      );
      return;
    }
    final next = options.cameraPosition == CameraPosition.front
        ? CameraPosition.back
        : CameraPosition.front;
    await track.setCameraPosition(next);
  }

  /// Forces the SFU to emit a fresh keyframe for [participantId]'s video.
  ///
  /// The FrameCryptor reports decryption state only on transitions: a frame
  /// that arrives before this client has applied the publisher's E2EE key is
  /// dropped, and the decoder then stays black until the next keyframe. After
  /// the key lands there is no automatic keyframe, so the picture never
  /// recovers. Toggling the remote video subscription off then on makes the
  /// SFU resend a keyframe, which the now-keyed FrameCryptor can decrypt.
  Future<void> forceRemoteKeyframe(String participantId) async {
    if (_isDisposed) return;
    final participant = _room?.remoteParticipants[participantId];
    if (participant == null) {
      _logger.warning(
        'forceRemoteKeyframe: no remote participant $participantId',
        name: _logKey,
      );
      return;
    }
    for (final publication in participant.videoTrackPublications) {
      _logger.info(
        'forceRemoteKeyframe: re-subscribing ${participant.identity} '
        'track ${publication.sid}',
        name: _logKey,
      );
      await publication.disable();
      await publication.enable();
    }
  }

  /// Routes audio through the loudspeaker ([enabled] = true) or earpiece
  /// ([enabled] = false).
  ///
  /// On platforms that do not support speakerphone routing (macOS, web) this
  /// is a no-op.
  Future<void> setSpeakerphoneEnabled(bool enabled) async {
    _logger.info('setSpeakerphoneEnabled: enabled=$enabled', name: _logKey);
    await Hardware.instance.setSpeakerphoneOn(enabled);
  }

  /// Snapshot of all current participants mapped to domain objects.
  List<AudioVideoCallParticipant> get participants =>
      _room?.toParticipants(_participantIdToDid) ?? const [];

  /// Returns the renderable video track for [participantId], or `null` when
  /// the room is not connected, the participant is not found, or they have no
  /// active video track.
  ///
  /// Consumer widgets use this to build `VideoTrackRenderer` directly, keeping
  /// the Flutter rendering concern out of this service.
  VideoTrack? renderableVideoTrackFor(String participantId) {
    final room = _room;
    if (room == null) return null;

    final Participant? participant;
    if (room.localParticipant?.identity == participantId) {
      participant = room.localParticipant;
    } else {
      participant = room.remoteParticipants[participantId];
    }
    return participant?.renderableVideoTrack;
  }
}

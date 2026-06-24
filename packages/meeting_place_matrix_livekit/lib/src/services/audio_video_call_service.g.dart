// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_video_call_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Orchestrates the full LiveKit call lifecycle for the channel identified
/// by [otherPartyChannelDid] (the other party's permanent channel DID).
///
/// Responsibilities:
/// - Resolves the channel, derives the LiveKit room name, obtains the
///   local user's DidManager, and exchanges for a LiveKit JWT.
/// - Owns [LiveKitService] and [SfuTokenService] for this call.
/// - Publishes [AudioVideoCallState] for the presentation layer to observe.
/// - Disconnects and releases resources on dispose.
///
/// Read by AudioVideoCallScreenController via `ref.listen`.
/// Modelled after ChatSessionService.

@ProviderFor(AudioVideoCallService)
const audioVideoCallServiceProvider = AudioVideoCallServiceFamily._();

/// Orchestrates the full LiveKit call lifecycle for the channel identified
/// by [otherPartyChannelDid] (the other party's permanent channel DID).
///
/// Responsibilities:
/// - Resolves the channel, derives the LiveKit room name, obtains the
///   local user's DidManager, and exchanges for a LiveKit JWT.
/// - Owns [LiveKitService] and [SfuTokenService] for this call.
/// - Publishes [AudioVideoCallState] for the presentation layer to observe.
/// - Disconnects and releases resources on dispose.
///
/// Read by AudioVideoCallScreenController via `ref.listen`.
/// Modelled after ChatSessionService.
final class AudioVideoCallServiceProvider
    extends $NotifierProvider<AudioVideoCallService, AudioVideoCallState> {
  /// Orchestrates the full LiveKit call lifecycle for the channel identified
  /// by [otherPartyChannelDid] (the other party's permanent channel DID).
  ///
  /// Responsibilities:
  /// - Resolves the channel, derives the LiveKit room name, obtains the
  ///   local user's DidManager, and exchanges for a LiveKit JWT.
  /// - Owns [LiveKitService] and [SfuTokenService] for this call.
  /// - Publishes [AudioVideoCallState] for the presentation layer to observe.
  /// - Disconnects and releases resources on dispose.
  ///
  /// Read by AudioVideoCallScreenController via `ref.listen`.
  /// Modelled after ChatSessionService.
  const AudioVideoCallServiceProvider._({
    required AudioVideoCallServiceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'audioVideoCallServiceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static const $allTransitiveDependencies0 = pluginCoreSdkProvider;
  static const $allTransitiveDependencies1 = pluginOptionsProvider;
  static const $allTransitiveDependencies2 = pluginRtcDelegateProvider;
  static const $allTransitiveDependencies3 = pluginLoggerProvider;
  static const $allTransitiveDependencies4 = sfuTokenServiceProvider;
  static const $allTransitiveDependencies5 = livekitKeyProviderFactoryProvider;

  @override
  String debugGetCreateSourceHash() => _$audioVideoCallServiceHash();

  @override
  String toString() {
    return r'audioVideoCallServiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  AudioVideoCallService create() => AudioVideoCallService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AudioVideoCallState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AudioVideoCallState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AudioVideoCallServiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$audioVideoCallServiceHash() =>
    r'f50a2f6bced7e6c41c4de01b47056865bd9df0d8';

/// Orchestrates the full LiveKit call lifecycle for the channel identified
/// by [otherPartyChannelDid] (the other party's permanent channel DID).
///
/// Responsibilities:
/// - Resolves the channel, derives the LiveKit room name, obtains the
///   local user's DidManager, and exchanges for a LiveKit JWT.
/// - Owns [LiveKitService] and [SfuTokenService] for this call.
/// - Publishes [AudioVideoCallState] for the presentation layer to observe.
/// - Disconnects and releases resources on dispose.
///
/// Read by AudioVideoCallScreenController via `ref.listen`.
/// Modelled after ChatSessionService.

final class AudioVideoCallServiceFamily extends $Family
    with
        $ClassFamilyOverride<
          AudioVideoCallService,
          AudioVideoCallState,
          AudioVideoCallState,
          AudioVideoCallState,
          String
        > {
  const AudioVideoCallServiceFamily._()
    : super(
        retry: null,
        name: r'audioVideoCallServiceProvider',
        dependencies: const <ProviderOrFamily>[
          pluginCoreSdkProvider,
          pluginOptionsProvider,
          pluginRtcDelegateProvider,
          pluginLoggerProvider,
          sfuTokenServiceProvider,
          livekitKeyProviderFactoryProvider,
        ],
        $allTransitiveDependencies: const <ProviderOrFamily>{
          AudioVideoCallServiceProvider.$allTransitiveDependencies0,
          AudioVideoCallServiceProvider.$allTransitiveDependencies1,
          AudioVideoCallServiceProvider.$allTransitiveDependencies2,
          AudioVideoCallServiceProvider.$allTransitiveDependencies3,
          AudioVideoCallServiceProvider.$allTransitiveDependencies4,
          AudioVideoCallServiceProvider.$allTransitiveDependencies5,
        },
        isAutoDispose: true,
      );

  /// Orchestrates the full LiveKit call lifecycle for the channel identified
  /// by [otherPartyChannelDid] (the other party's permanent channel DID).
  ///
  /// Responsibilities:
  /// - Resolves the channel, derives the LiveKit room name, obtains the
  ///   local user's DidManager, and exchanges for a LiveKit JWT.
  /// - Owns [LiveKitService] and [SfuTokenService] for this call.
  /// - Publishes [AudioVideoCallState] for the presentation layer to observe.
  /// - Disconnects and releases resources on dispose.
  ///
  /// Read by AudioVideoCallScreenController via `ref.listen`.
  /// Modelled after ChatSessionService.

  AudioVideoCallServiceProvider call(String otherPartyChannelDid) =>
      AudioVideoCallServiceProvider._(
        argument: otherPartyChannelDid,
        from: this,
      );

  @override
  String toString() => r'audioVideoCallServiceProvider';
}

/// Orchestrates the full LiveKit call lifecycle for the channel identified
/// by [otherPartyChannelDid] (the other party's permanent channel DID).
///
/// Responsibilities:
/// - Resolves the channel, derives the LiveKit room name, obtains the
///   local user's DidManager, and exchanges for a LiveKit JWT.
/// - Owns [LiveKitService] and [SfuTokenService] for this call.
/// - Publishes [AudioVideoCallState] for the presentation layer to observe.
/// - Disconnects and releases resources on dispose.
///
/// Read by AudioVideoCallScreenController via `ref.listen`.
/// Modelled after ChatSessionService.

abstract class _$AudioVideoCallService extends $Notifier<AudioVideoCallState> {
  late final _$args = ref.$arg as String;
  String get otherPartyChannelDid => _$args;

  AudioVideoCallState build(String otherPartyChannelDid);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AudioVideoCallState, AudioVideoCallState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AudioVideoCallState, AudioVideoCallState>,
              AudioVideoCallState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

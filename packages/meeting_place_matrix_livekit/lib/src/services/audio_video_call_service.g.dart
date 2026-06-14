// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audio_video_call_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$audioVideoCallServiceHash() =>
    r'b4eade870c5d0b5ff0e28e0976d1a1574c4dfb26';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$AudioVideoCallService
    extends BuildlessAutoDisposeNotifier<CallSessionState> {
  late final String otherPartyChannelDid;

  CallSessionState build(String otherPartyChannelDid);
}

/// Orchestrates the full LiveKit call lifecycle for the channel identified
/// by [otherPartyChannelDid] (the other party's permanent channel DID).
///
/// Responsibilities:
/// - Resolves the channel, derives the LiveKit room name, obtains the
///   local user's DidManager, and exchanges for a LiveKit JWT.
/// - Owns [LiveKitService] and [SfuTokenService] for this call.
/// - Publishes [CallSessionState] for the presentation layer to observe.
/// - Disconnects and releases resources on dispose.
///
/// Read by AudioVideoCallScreenController via `ref.listen`.
/// Modelled after ChatSessionService.
///
/// Copied from [AudioVideoCallService].
@ProviderFor(AudioVideoCallService)
const audioVideoCallServiceProvider = AudioVideoCallServiceFamily();

/// Orchestrates the full LiveKit call lifecycle for the channel identified
/// by [otherPartyChannelDid] (the other party's permanent channel DID).
///
/// Responsibilities:
/// - Resolves the channel, derives the LiveKit room name, obtains the
///   local user's DidManager, and exchanges for a LiveKit JWT.
/// - Owns [LiveKitService] and [SfuTokenService] for this call.
/// - Publishes [CallSessionState] for the presentation layer to observe.
/// - Disconnects and releases resources on dispose.
///
/// Read by AudioVideoCallScreenController via `ref.listen`.
/// Modelled after ChatSessionService.
///
/// Copied from [AudioVideoCallService].
class AudioVideoCallServiceFamily extends Family<CallSessionState> {
  /// Orchestrates the full LiveKit call lifecycle for the channel identified
  /// by [otherPartyChannelDid] (the other party's permanent channel DID).
  ///
  /// Responsibilities:
  /// - Resolves the channel, derives the LiveKit room name, obtains the
  ///   local user's DidManager, and exchanges for a LiveKit JWT.
  /// - Owns [LiveKitService] and [SfuTokenService] for this call.
  /// - Publishes [CallSessionState] for the presentation layer to observe.
  /// - Disconnects and releases resources on dispose.
  ///
  /// Read by AudioVideoCallScreenController via `ref.listen`.
  /// Modelled after ChatSessionService.
  ///
  /// Copied from [AudioVideoCallService].
  const AudioVideoCallServiceFamily();

  /// Orchestrates the full LiveKit call lifecycle for the channel identified
  /// by [otherPartyChannelDid] (the other party's permanent channel DID).
  ///
  /// Responsibilities:
  /// - Resolves the channel, derives the LiveKit room name, obtains the
  ///   local user's DidManager, and exchanges for a LiveKit JWT.
  /// - Owns [LiveKitService] and [SfuTokenService] for this call.
  /// - Publishes [CallSessionState] for the presentation layer to observe.
  /// - Disconnects and releases resources on dispose.
  ///
  /// Read by AudioVideoCallScreenController via `ref.listen`.
  /// Modelled after ChatSessionService.
  ///
  /// Copied from [AudioVideoCallService].
  AudioVideoCallServiceProvider call(String otherPartyChannelDid) {
    return AudioVideoCallServiceProvider(otherPartyChannelDid);
  }

  @override
  AudioVideoCallServiceProvider getProviderOverride(
    covariant AudioVideoCallServiceProvider provider,
  ) {
    return call(provider.otherPartyChannelDid);
  }

  static final Iterable<ProviderOrFamily> _dependencies = <ProviderOrFamily>{
    pluginCoreSdkProvider,
    pluginOptionsProvider,
    pluginRtcDelegateProvider,
    pluginLoggerProvider,
  };

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static final Iterable<ProviderOrFamily> _allTransitiveDependencies =
      <ProviderOrFamily>{
        pluginCoreSdkProvider,
        ...?pluginCoreSdkProvider.allTransitiveDependencies,
        pluginOptionsProvider,
        ...?pluginOptionsProvider.allTransitiveDependencies,
        pluginRtcDelegateProvider,
        ...?pluginRtcDelegateProvider.allTransitiveDependencies,
        pluginLoggerProvider,
        ...?pluginLoggerProvider.allTransitiveDependencies,
      };

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'audioVideoCallServiceProvider';
}

/// Orchestrates the full LiveKit call lifecycle for the channel identified
/// by [otherPartyChannelDid] (the other party's permanent channel DID).
///
/// Responsibilities:
/// - Resolves the channel, derives the LiveKit room name, obtains the
///   local user's DidManager, and exchanges for a LiveKit JWT.
/// - Owns [LiveKitService] and [SfuTokenService] for this call.
/// - Publishes [CallSessionState] for the presentation layer to observe.
/// - Disconnects and releases resources on dispose.
///
/// Read by AudioVideoCallScreenController via `ref.listen`.
/// Modelled after ChatSessionService.
///
/// Copied from [AudioVideoCallService].
class AudioVideoCallServiceProvider
    extends
        AutoDisposeNotifierProviderImpl<
          AudioVideoCallService,
          CallSessionState
        > {
  /// Orchestrates the full LiveKit call lifecycle for the channel identified
  /// by [otherPartyChannelDid] (the other party's permanent channel DID).
  ///
  /// Responsibilities:
  /// - Resolves the channel, derives the LiveKit room name, obtains the
  ///   local user's DidManager, and exchanges for a LiveKit JWT.
  /// - Owns [LiveKitService] and [SfuTokenService] for this call.
  /// - Publishes [CallSessionState] for the presentation layer to observe.
  /// - Disconnects and releases resources on dispose.
  ///
  /// Read by AudioVideoCallScreenController via `ref.listen`.
  /// Modelled after ChatSessionService.
  ///
  /// Copied from [AudioVideoCallService].
  AudioVideoCallServiceProvider(String otherPartyChannelDid)
    : this._internal(
        () =>
            AudioVideoCallService()
              ..otherPartyChannelDid = otherPartyChannelDid,
        from: audioVideoCallServiceProvider,
        name: r'audioVideoCallServiceProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$audioVideoCallServiceHash,
        dependencies: AudioVideoCallServiceFamily._dependencies,
        allTransitiveDependencies:
            AudioVideoCallServiceFamily._allTransitiveDependencies,
        otherPartyChannelDid: otherPartyChannelDid,
      );

  AudioVideoCallServiceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.otherPartyChannelDid,
  }) : super.internal();

  final String otherPartyChannelDid;

  @override
  CallSessionState runNotifierBuild(covariant AudioVideoCallService notifier) {
    return notifier.build(otherPartyChannelDid);
  }

  @override
  Override overrideWith(AudioVideoCallService Function() create) {
    return ProviderOverride(
      origin: this,
      override: AudioVideoCallServiceProvider._internal(
        () => create()..otherPartyChannelDid = otherPartyChannelDid,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        otherPartyChannelDid: otherPartyChannelDid,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<AudioVideoCallService, CallSessionState>
  createElement() {
    return _AudioVideoCallServiceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AudioVideoCallServiceProvider &&
        other.otherPartyChannelDid == otherPartyChannelDid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, otherPartyChannelDid.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AudioVideoCallServiceRef
    on AutoDisposeNotifierProviderRef<CallSessionState> {
  /// The parameter `otherPartyChannelDid` of this provider.
  String get otherPartyChannelDid;
}

class _AudioVideoCallServiceProviderElement
    extends
        AutoDisposeNotifierProviderElement<
          AudioVideoCallService,
          CallSessionState
        >
    with AudioVideoCallServiceRef {
  _AudioVideoCallServiceProviderElement(super.provider);

  @override
  String get otherPartyChannelDid =>
      (origin as AudioVideoCallServiceProvider).otherPartyChannelDid;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

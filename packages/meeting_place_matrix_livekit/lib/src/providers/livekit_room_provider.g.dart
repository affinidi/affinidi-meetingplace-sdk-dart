// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livekit_room_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [LiveKitRoom] for a call session.
///
/// This provider is overridden per-session inside the plugin's isolated
/// [ProviderContainer] via [MeetingPlaceLiveKitCallPlugin]. Reading it from
/// the global container is a configuration error.

@ProviderFor(livekitRoom)
const livekitRoomProvider = LivekitRoomFamily._();

/// Provides the [LiveKitRoom] for a call session.
///
/// This provider is overridden per-session inside the plugin's isolated
/// [ProviderContainer] via [MeetingPlaceLiveKitCallPlugin]. Reading it from
/// the global container is a configuration error.

final class LivekitRoomProvider
    extends $FunctionalProvider<LiveKitRoom, LiveKitRoom, LiveKitRoom>
    with $Provider<LiveKitRoom> {
  /// Provides the [LiveKitRoom] for a call session.
  ///
  /// This provider is overridden per-session inside the plugin's isolated
  /// [ProviderContainer] via [MeetingPlaceLiveKitCallPlugin]. Reading it from
  /// the global container is a configuration error.
  const LivekitRoomProvider._({
    required LivekitRoomFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'livekitRoomProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$livekitRoomHash();

  @override
  String toString() {
    return r'livekitRoomProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<LiveKitRoom> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LiveKitRoom create(Ref ref) {
    final argument = this.argument as String;
    return livekitRoom(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiveKitRoom value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiveKitRoom>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LivekitRoomProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$livekitRoomHash() => r'47e685d94c85b964b40f5e075e05e770c01127ee';

/// Provides the [LiveKitRoom] for a call session.
///
/// This provider is overridden per-session inside the plugin's isolated
/// [ProviderContainer] via [MeetingPlaceLiveKitCallPlugin]. Reading it from
/// the global container is a configuration error.

final class LivekitRoomFamily extends $Family
    with $FunctionalFamilyOverride<LiveKitRoom, String> {
  const LivekitRoomFamily._()
    : super(
        retry: null,
        name: r'livekitRoomProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provides the [LiveKitRoom] for a call session.
  ///
  /// This provider is overridden per-session inside the plugin's isolated
  /// [ProviderContainer] via [MeetingPlaceLiveKitCallPlugin]. Reading it from
  /// the global container is a configuration error.

  LivekitRoomProvider call(String otherPartyChannelDid) =>
      LivekitRoomProvider._(argument: otherPartyChannelDid, from: this);

  @override
  String toString() => r'livekitRoomProvider';
}

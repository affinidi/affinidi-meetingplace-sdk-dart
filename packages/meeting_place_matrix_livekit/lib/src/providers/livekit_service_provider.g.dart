// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livekit_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [LiveKitService] instance scoped to a single call session identified by
/// [otherPartyChannelDid].
///
/// Auto-disposed when the last watcher is disposed, which triggers
/// [LiveKitService.disconnect] and releases the room.

@ProviderFor(livekitService)
const livekitServiceProvider = LivekitServiceFamily._();

/// [LiveKitService] instance scoped to a single call session identified by
/// [otherPartyChannelDid].
///
/// Auto-disposed when the last watcher is disposed, which triggers
/// [LiveKitService.disconnect] and releases the room.

final class LivekitServiceProvider
    extends $FunctionalProvider<LiveKitService, LiveKitService, LiveKitService>
    with $Provider<LiveKitService> {
  /// [LiveKitService] instance scoped to a single call session identified by
  /// [otherPartyChannelDid].
  ///
  /// Auto-disposed when the last watcher is disposed, which triggers
  /// [LiveKitService.disconnect] and releases the room.
  const LivekitServiceProvider._({
    required LivekitServiceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'livekitServiceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$livekitServiceHash();

  @override
  String toString() {
    return r'livekitServiceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<LiveKitService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LiveKitService create(Ref ref) {
    final argument = this.argument as String;
    return livekitService(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LiveKitService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LiveKitService>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LivekitServiceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$livekitServiceHash() => r'722acff1fd0c978b9046a4765a510864015b6872';

/// [LiveKitService] instance scoped to a single call session identified by
/// [otherPartyChannelDid].
///
/// Auto-disposed when the last watcher is disposed, which triggers
/// [LiveKitService.disconnect] and releases the room.

final class LivekitServiceFamily extends $Family
    with $FunctionalFamilyOverride<LiveKitService, String> {
  const LivekitServiceFamily._()
    : super(
        retry: null,
        name: r'livekitServiceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// [LiveKitService] instance scoped to a single call session identified by
  /// [otherPartyChannelDid].
  ///
  /// Auto-disposed when the last watcher is disposed, which triggers
  /// [LiveKitService.disconnect] and releases the room.

  LivekitServiceProvider call(String otherPartyChannelDid) =>
      LivekitServiceProvider._(argument: otherPartyChannelDid, from: this);

  @override
  String toString() => r'livekitServiceProvider';
}

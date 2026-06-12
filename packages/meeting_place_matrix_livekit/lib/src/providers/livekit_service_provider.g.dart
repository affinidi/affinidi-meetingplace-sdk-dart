// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livekit_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$livekitServiceHash() => r'722acff1fd0c978b9046a4765a510864015b6872';

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

/// [LiveKitService] instance scoped to a single call session identified by
/// [otherPartyChannelDid].
///
/// Auto-disposed when the last watcher is disposed, which triggers
/// [LiveKitService.disconnect] and releases the room.
///
/// Copied from [livekitService].
@ProviderFor(livekitService)
const livekitServiceProvider = LivekitServiceFamily();

/// [LiveKitService] instance scoped to a single call session identified by
/// [otherPartyChannelDid].
///
/// Auto-disposed when the last watcher is disposed, which triggers
/// [LiveKitService.disconnect] and releases the room.
///
/// Copied from [livekitService].
class LivekitServiceFamily extends Family<LiveKitService> {
  /// [LiveKitService] instance scoped to a single call session identified by
  /// [otherPartyChannelDid].
  ///
  /// Auto-disposed when the last watcher is disposed, which triggers
  /// [LiveKitService.disconnect] and releases the room.
  ///
  /// Copied from [livekitService].
  const LivekitServiceFamily();

  /// [LiveKitService] instance scoped to a single call session identified by
  /// [otherPartyChannelDid].
  ///
  /// Auto-disposed when the last watcher is disposed, which triggers
  /// [LiveKitService.disconnect] and releases the room.
  ///
  /// Copied from [livekitService].
  LivekitServiceProvider call(String otherPartyChannelDid) {
    return LivekitServiceProvider(otherPartyChannelDid);
  }

  @override
  LivekitServiceProvider getProviderOverride(
    covariant LivekitServiceProvider provider,
  ) {
    return call(provider.otherPartyChannelDid);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'livekitServiceProvider';
}

/// [LiveKitService] instance scoped to a single call session identified by
/// [otherPartyChannelDid].
///
/// Auto-disposed when the last watcher is disposed, which triggers
/// [LiveKitService.disconnect] and releases the room.
///
/// Copied from [livekitService].
class LivekitServiceProvider extends AutoDisposeProvider<LiveKitService> {
  /// [LiveKitService] instance scoped to a single call session identified by
  /// [otherPartyChannelDid].
  ///
  /// Auto-disposed when the last watcher is disposed, which triggers
  /// [LiveKitService.disconnect] and releases the room.
  ///
  /// Copied from [livekitService].
  LivekitServiceProvider(String otherPartyChannelDid)
    : this._internal(
        (ref) => livekitService(ref as LivekitServiceRef, otherPartyChannelDid),
        from: livekitServiceProvider,
        name: r'livekitServiceProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$livekitServiceHash,
        dependencies: LivekitServiceFamily._dependencies,
        allTransitiveDependencies:
            LivekitServiceFamily._allTransitiveDependencies,
        otherPartyChannelDid: otherPartyChannelDid,
      );

  LivekitServiceProvider._internal(
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
  Override overrideWith(
    LiveKitService Function(LivekitServiceRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LivekitServiceProvider._internal(
        (ref) => create(ref as LivekitServiceRef),
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
  AutoDisposeProviderElement<LiveKitService> createElement() {
    return _LivekitServiceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LivekitServiceProvider &&
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
mixin LivekitServiceRef on AutoDisposeProviderRef<LiveKitService> {
  /// The parameter `otherPartyChannelDid` of this provider.
  String get otherPartyChannelDid;
}

class _LivekitServiceProviderElement
    extends AutoDisposeProviderElement<LiveKitService>
    with LivekitServiceRef {
  _LivekitServiceProviderElement(super.provider);

  @override
  String get otherPartyChannelDid =>
      (origin as LivekitServiceProvider).otherPartyChannelDid;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

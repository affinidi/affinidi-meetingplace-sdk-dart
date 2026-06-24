// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livekit_key_provider_factory_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider that vends the [KeyProviderFactory] for this plugin session.
///
/// Override in tests to return a factory that creates a fake key provider
/// instead of calling the real platform-channel-backed [BaseKeyProvider.create].

@ProviderFor(livekitKeyProviderFactory)
const livekitKeyProviderFactoryProvider = LivekitKeyProviderFactoryProvider._();

/// Provider that vends the [KeyProviderFactory] for this plugin session.
///
/// Override in tests to return a factory that creates a fake key provider
/// instead of calling the real platform-channel-backed [BaseKeyProvider.create].

final class LivekitKeyProviderFactoryProvider
    extends
        $FunctionalProvider<
          KeyProviderFactory,
          KeyProviderFactory,
          KeyProviderFactory
        >
    with $Provider<KeyProviderFactory> {
  /// Provider that vends the [KeyProviderFactory] for this plugin session.
  ///
  /// Override in tests to return a factory that creates a fake key provider
  /// instead of calling the real platform-channel-backed [BaseKeyProvider.create].
  const LivekitKeyProviderFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'livekitKeyProviderFactoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$livekitKeyProviderFactoryHash();

  @$internal
  @override
  $ProviderElement<KeyProviderFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KeyProviderFactory create(Ref ref) {
    return livekitKeyProviderFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KeyProviderFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KeyProviderFactory>(value),
    );
  }
}

String _$livekitKeyProviderFactoryHash() =>
    r'3b6c9bf01716f829a8a63345eefe550375cc5671';

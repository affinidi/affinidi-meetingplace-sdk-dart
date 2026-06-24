// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sfu_token_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [SfuTokenService] instance for the current plugin session.
///
/// Override in tests to return a mock without making real HTTP requests.

@ProviderFor(sfuTokenService)
const sfuTokenServiceProvider = SfuTokenServiceProvider._();

/// [SfuTokenService] instance for the current plugin session.
///
/// Override in tests to return a mock without making real HTTP requests.

final class SfuTokenServiceProvider
    extends
        $FunctionalProvider<SfuTokenService, SfuTokenService, SfuTokenService>
    with $Provider<SfuTokenService> {
  /// [SfuTokenService] instance for the current plugin session.
  ///
  /// Override in tests to return a mock without making real HTTP requests.
  const SfuTokenServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sfuTokenServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sfuTokenServiceHash();

  @$internal
  @override
  $ProviderElement<SfuTokenService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SfuTokenService create(Ref ref) {
    return sfuTokenService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SfuTokenService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SfuTokenService>(value),
    );
  }
}

String _$sfuTokenServiceHash() => r'b81940b9af4ddaa14caba836a7d81956a58ffcc2';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_core_sdk_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// [MeetingPlaceCoreSDK] instance injected into this plugin's scope.
///
/// Overridden in the `ProviderScope` via `MeetingPlaceLiveKitCallPlugin.scope`.
/// Not part of the public API; the app injects the SDK via the plugin
/// constructor, not directly.

@ProviderFor(pluginCoreSdk)
const pluginCoreSdkProvider = PluginCoreSdkProvider._();

/// [MeetingPlaceCoreSDK] instance injected into this plugin's scope.
///
/// Overridden in the `ProviderScope` via `MeetingPlaceLiveKitCallPlugin.scope`.
/// Not part of the public API; the app injects the SDK via the plugin
/// constructor, not directly.

final class PluginCoreSdkProvider
    extends
        $FunctionalProvider<
          MeetingPlaceCoreSDK,
          MeetingPlaceCoreSDK,
          MeetingPlaceCoreSDK
        >
    with $Provider<MeetingPlaceCoreSDK> {
  /// [MeetingPlaceCoreSDK] instance injected into this plugin's scope.
  ///
  /// Overridden in the `ProviderScope` via `MeetingPlaceLiveKitCallPlugin.scope`.
  /// Not part of the public API; the app injects the SDK via the plugin
  /// constructor, not directly.
  const PluginCoreSdkProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pluginCoreSdkProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pluginCoreSdkHash();

  @$internal
  @override
  $ProviderElement<MeetingPlaceCoreSDK> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MeetingPlaceCoreSDK create(Ref ref) {
    return pluginCoreSdk(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeetingPlaceCoreSDK value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeetingPlaceCoreSDK>(value),
    );
  }
}

String _$pluginCoreSdkHash() => r'2d73ce2190fbface3a3e0101ff498ee4a0eca828';

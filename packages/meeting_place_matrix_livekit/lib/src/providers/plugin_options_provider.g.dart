// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_options_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Plugin-wide options (includes `livekitServiceUrl`).
///
/// Overridden in the `ProviderScope` via `MeetingPlaceLiveKitCallPlugin.scope`.
/// Internal; the app sets options via the plugin constructor.

@ProviderFor(pluginOptions)
const pluginOptionsProvider = PluginOptionsProvider._();

/// Plugin-wide options (includes `livekitServiceUrl`).
///
/// Overridden in the `ProviderScope` via `MeetingPlaceLiveKitCallPlugin.scope`.
/// Internal; the app sets options via the plugin constructor.

final class PluginOptionsProvider
    extends
        $FunctionalProvider<
          MeetingPlaceLiveKitCallPluginOptions,
          MeetingPlaceLiveKitCallPluginOptions,
          MeetingPlaceLiveKitCallPluginOptions
        >
    with $Provider<MeetingPlaceLiveKitCallPluginOptions> {
  /// Plugin-wide options (includes `livekitServiceUrl`).
  ///
  /// Overridden in the `ProviderScope` via `MeetingPlaceLiveKitCallPlugin.scope`.
  /// Internal; the app sets options via the plugin constructor.
  const PluginOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pluginOptionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pluginOptionsHash();

  @$internal
  @override
  $ProviderElement<MeetingPlaceLiveKitCallPluginOptions> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MeetingPlaceLiveKitCallPluginOptions create(Ref ref) {
    return pluginOptions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeetingPlaceLiveKitCallPluginOptions value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<MeetingPlaceLiveKitCallPluginOptions>(value),
    );
  }
}

String _$pluginOptionsHash() => r'26984d5b41ab68871e29cf2ee71b85c2ef3209db';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_rtc_delegate_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared [matrix.WebRTCDelegate] instance for this call session.
///
/// Overridden in the plugin's isolated [ProviderContainer] by
/// [MeetingPlaceLiveKitCallPlugin] at session creation time.

@ProviderFor(pluginRtcDelegate)
const pluginRtcDelegateProvider = PluginRtcDelegateProvider._();

/// Shared [matrix.WebRTCDelegate] instance for this call session.
///
/// Overridden in the plugin's isolated [ProviderContainer] by
/// [MeetingPlaceLiveKitCallPlugin] at session creation time.

final class PluginRtcDelegateProvider
    extends
        $FunctionalProvider<
          matrix.WebRTCDelegate,
          matrix.WebRTCDelegate,
          matrix.WebRTCDelegate
        >
    with $Provider<matrix.WebRTCDelegate> {
  /// Shared [matrix.WebRTCDelegate] instance for this call session.
  ///
  /// Overridden in the plugin's isolated [ProviderContainer] by
  /// [MeetingPlaceLiveKitCallPlugin] at session creation time.
  const PluginRtcDelegateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pluginRtcDelegateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pluginRtcDelegateHash();

  @$internal
  @override
  $ProviderElement<matrix.WebRTCDelegate> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  matrix.WebRTCDelegate create(Ref ref) {
    return pluginRtcDelegate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(matrix.WebRTCDelegate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<matrix.WebRTCDelegate>(value),
    );
  }
}

String _$pluginRtcDelegateHash() => r'f3537004921d80058e5fc11833834b8f4e144ba4';

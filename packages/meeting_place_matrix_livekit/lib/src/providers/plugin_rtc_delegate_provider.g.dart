// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_rtc_delegate_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Shared [FlutterMatrixRTCDelegate] instance for this call session.
///
/// Overridden in the `ProviderScope` via `MeetingPlaceLiveKitCallPlugin.scope`;
/// constructed by `MeetingPlaceLiveKitCallPlugin` and not exposed to the app.

@ProviderFor(pluginRtcDelegate)
const pluginRtcDelegateProvider = PluginRtcDelegateProvider._();

/// Shared [FlutterMatrixRTCDelegate] instance for this call session.
///
/// Overridden in the `ProviderScope` via `MeetingPlaceLiveKitCallPlugin.scope`;
/// constructed by `MeetingPlaceLiveKitCallPlugin` and not exposed to the app.

final class PluginRtcDelegateProvider
    extends
        $FunctionalProvider<
          FlutterMatrixRTCDelegate,
          FlutterMatrixRTCDelegate,
          FlutterMatrixRTCDelegate
        >
    with $Provider<FlutterMatrixRTCDelegate> {
  /// Shared [FlutterMatrixRTCDelegate] instance for this call session.
  ///
  /// Overridden in the `ProviderScope` via `MeetingPlaceLiveKitCallPlugin.scope`;
  /// constructed by `MeetingPlaceLiveKitCallPlugin` and not exposed to the app.
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
  $ProviderElement<FlutterMatrixRTCDelegate> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  FlutterMatrixRTCDelegate create(Ref ref) {
    return pluginRtcDelegate(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlutterMatrixRTCDelegate value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FlutterMatrixRTCDelegate>(value),
    );
  }
}

String _$pluginRtcDelegateHash() => r'6565c1df4ae1a63b6bd5a30389bf043e677ae8aa';

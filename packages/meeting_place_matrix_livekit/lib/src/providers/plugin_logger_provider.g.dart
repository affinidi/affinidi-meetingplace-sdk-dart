// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_logger_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Logger for the MeetingPlace Matrix LiveKit plugin.
///
/// Defaults to [DefaultMeetingPlaceCoreSDKLogger]. Override in the app's
/// ProviderScope to route plugin logs through the app's own logging pipeline.

@ProviderFor(pluginLogger)
const pluginLoggerProvider = PluginLoggerProvider._();

/// Logger for the MeetingPlace Matrix LiveKit plugin.
///
/// Defaults to [DefaultMeetingPlaceCoreSDKLogger]. Override in the app's
/// ProviderScope to route plugin logs through the app's own logging pipeline.

final class PluginLoggerProvider
    extends
        $FunctionalProvider<
          MeetingPlaceCoreSDKLogger,
          MeetingPlaceCoreSDKLogger,
          MeetingPlaceCoreSDKLogger
        >
    with $Provider<MeetingPlaceCoreSDKLogger> {
  /// Logger for the MeetingPlace Matrix LiveKit plugin.
  ///
  /// Defaults to [DefaultMeetingPlaceCoreSDKLogger]. Override in the app's
  /// ProviderScope to route plugin logs through the app's own logging pipeline.
  const PluginLoggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pluginLoggerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pluginLoggerHash();

  @$internal
  @override
  $ProviderElement<MeetingPlaceCoreSDKLogger> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MeetingPlaceCoreSDKLogger create(Ref ref) {
    return pluginLogger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MeetingPlaceCoreSDKLogger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MeetingPlaceCoreSDKLogger>(value),
    );
  }
}

String _$pluginLoggerHash() => r'd2ffd6b7334ab3eb82ee01469ffa2ae647d1cf93';

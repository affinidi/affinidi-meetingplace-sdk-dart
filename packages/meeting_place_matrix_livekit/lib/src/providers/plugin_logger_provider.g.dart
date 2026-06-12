// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plugin_logger_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$pluginLoggerHash() => r'd2ffd6b7334ab3eb82ee01469ffa2ae647d1cf93';

/// Logger for the MeetingPlace Matrix LiveKit plugin.
///
/// Defaults to [DefaultMeetingPlaceCoreSDKLogger]. Override in the app's
/// ProviderScope to route plugin logs through the app's own logging pipeline.
///
/// Copied from [pluginLogger].
@ProviderFor(pluginLogger)
final pluginLoggerProvider = Provider<MeetingPlaceCoreSDKLogger>.internal(
  pluginLogger,
  name: r'pluginLoggerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$pluginLoggerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef PluginLoggerRef = ProviderRef<MeetingPlaceCoreSDKLogger>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

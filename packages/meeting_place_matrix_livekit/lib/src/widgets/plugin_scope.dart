import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Places the plugin's [ProviderScope] above [child], backed by [container].
///
/// Sharing the container ensures that the widget tree reads the same service
/// instances that `MeetingPlaceLiveKitCallPlugin` drives imperatively.
///
/// Constructed by `MeetingPlaceLiveKitCallPlugin.scope`; do not instantiate
/// directly.
class PluginScope extends StatelessWidget {
  const PluginScope({super.key, required this.container, required this.child});

  final ProviderContainer container;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(container: container, child: child);
  }
}

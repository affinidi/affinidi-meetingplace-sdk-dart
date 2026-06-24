import 'package:livekit_client/livekit_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'livekit_key_provider_factory_provider.g.dart';

/// A factory function that creates a [BaseKeyProvider].
///
/// Wrapping [BaseKeyProvider.create] in a provider makes the key-provider
/// creation injectable in tests, where the underlying platform channel is not
/// available.
typedef KeyProviderFactory =
    Future<BaseKeyProvider> Function({required bool sharedKey});

/// Provider that vends the [KeyProviderFactory] for this plugin session.
///
/// Override in tests to return a factory that creates a fake key provider
/// instead of calling the real platform-channel-backed [BaseKeyProvider.create]
@riverpod
KeyProviderFactory livekitKeyProviderFactory(Ref ref) {
  return BaseKeyProvider.create;
}

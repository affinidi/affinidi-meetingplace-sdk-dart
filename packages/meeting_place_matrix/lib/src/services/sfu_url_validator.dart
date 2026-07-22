import '../exceptions/meeting_place_livekit_call_exception.dart';

/// Validates LiveKit SFU URLs against transport and host security rules.
class SfuUrlValidator {
  const SfuUrlValidator();

  static const _secureWebSocketScheme = 'wss';
  static const _webSocketScheme = 'ws';
  static const _secureWebSocketDisplay = 'wss://';
  static const _webSocketDisplay = 'ws://';
  static const _missingUrlMessage =
      'No LiveKit SFU URL available: set livekitSfuUrl in plugin options '
      'or ensure lk-jwt-service returns a URL in the response';
  static const _missingAllowlistMessage =
      'Security violation: sfuAllowedHosts must be configured when using '
      'server-supplied SFU URLs (livekitSfuUrl is null). '
      'Set sfuAllowedHosts '
      'in plugin options to prevent compromised JWT services from redirecting'
      ' media to attacker-controlled servers.';

  /// Validates the SFU URL for security: enforces wss:// scheme and checks
  /// against the allowlist when configured.
  ///
  /// Throws [MeetingPlaceLiveKitCallOperationException] if:
  /// - The URL is null, empty, or invalid.
  /// - The scheme is not `wss` (server-supplied URLs), or not `wss`/`ws`
  ///   (app-supplied URLs, where [isServerSupplied] is false).
  /// - [isServerSupplied] is true and [allowedHosts] is empty (production
  ///   mode requires allowlist).
  /// - The host is not in [allowedHosts] when the list is non-empty.
  ///
  /// Supports wildcard patterns in [allowedHosts] (e.g. `*.example.com`).
  Uri validate(
    String? rawUrl,
    List<String> allowedHosts, {
    required bool isServerSupplied,
  }) {
    if (rawUrl == null || rawUrl.isEmpty) {
      throw const MeetingPlaceLiveKitCallOperationException(_missingUrlMessage);
    }
    final uri = Uri.tryParse(rawUrl);
    final schemeIsAllowed = isServerSupplied
        ? uri?.scheme == _secureWebSocketScheme
        : uri?.scheme == _secureWebSocketScheme ||
              uri?.scheme == _webSocketScheme;
    if (uri == null || !schemeIsAllowed) {
      final allowedSchemes = isServerSupplied
          ? _secureWebSocketDisplay
          : '$_secureWebSocketDisplay or $_webSocketDisplay';
      throw MeetingPlaceLiveKitCallOperationException(
        'SFU URL must use $allowedSchemes scheme, '
        'got: ${uri?.scheme ?? "null"}',
      );
    }
    if (isServerSupplied && allowedHosts.isEmpty) {
      throw const MeetingPlaceLiveKitCallOperationException(
        _missingAllowlistMessage,
      );
    }
    if (allowedHosts.isNotEmpty) {
      final host = uri.host;
      if (!_hostMatchesAllowlist(host, allowedHosts)) {
        throw MeetingPlaceLiveKitCallOperationException(
          'SFU host "$host" is not in the allowlist',
        );
      }
    }
    return uri;
  }

  /// Returns whether [host] matches any entry in [allowedHosts].
  ///
  /// A `*.` prefix is a single-label wildcard: `*.affinidi.io` matches
  /// `livekit.affinidi.io` but not the apex `affinidi.io` nor deeper
  /// subdomains such as `evil.sub.affinidi.io`. All other entries require an
  /// exact host match.
  bool _hostMatchesAllowlist(String host, List<String> allowedHosts) {
    return allowedHosts.any((pattern) {
      if (pattern.startsWith('*.')) {
        final suffix = pattern.substring(
          1,
        ); // '*.affinidi.io' -> '.affinidi.io'
        if (!host.endsWith(suffix)) return false;
        final label = host.substring(0, host.length - suffix.length);
        return label.isNotEmpty && !label.contains('.');
      }
      return host == pattern;
    });
  }
}

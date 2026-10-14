import 'dart:convert';

import 'host_rules.dart';
import 'trigger_link_config.dart';
import 'trigger_link_result.dart';

/// Reads one-scan trigger links, such as a VTC sign-in code, offline.
///
/// Follows the reading order of the VTI trigger-link chapter
/// (`dtgwg-vti-spec`, `spec/07a-links.md`), ported from Keyring's reader that
/// passes that spec's conformance vectors.
///
/// Pure: no network, no storage. A rejection carries only a reason and the
/// class of words to show, never the link text. Nothing in the link decides
/// where anything is sent: endpoints come from the sender's DID document.
abstract final class TriggerLink {
  static const _reserved = {'_from', '_id', '_exp', '_type'};

  /// Reads [text] with [config], at [now] (seconds since the epoch).
  static TriggerLinkResult read(
    String text, {
    TriggerLinkConfig config = TriggerLinkConfig.meetingPlace,
    int? now,
  }) {
    final nowSeconds = now ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final aliasSchemes = config.aliasSchemes.map((s) => s.toLowerCase());

    // 1. Trim ASCII whitespace; the length counts code points.
    final trimmed = text.replaceAll(_edgeWhitespace, '');
    if (trimmed.runes.length > config.maxLinkLength) {
      return TriggerLinkRejected.because('too-long');
    }

    // 2. The scheme, then whether the text carries a trigger at all.
    final schemeMatch = _scheme.firstMatch(trimmed);
    final scheme = schemeMatch?.group(1)!.toLowerCase();
    if (scheme == null ||
        !(scheme == 'https' ||
            scheme == 'http' ||
            aliasSchemes.contains(scheme))) {
      return TriggerLinkRejected.because('not-ours');
    }
    final hashAt = trimmed.indexOf('#');
    final fragment = hashAt == -1 ? '' : trimmed.substring(hashAt + 1);
    final beforeHash = hashAt == -1 ? trimmed : trimmed.substring(0, hashAt);
    final queryAt = beforeHash.indexOf('?');
    final query = queryAt == -1 ? '' : beforeHash.substring(queryAt + 1);
    final pairs = _parseForm(fragment);
    if (!_hasReserved(pairs)) {
      // The query is read only to say "a trigger in the wrong place".
      return TriggerLinkRejected.because(
        _hasReserved(_parseForm(query)) ? 'query-form' : 'not-ours',
      );
    }
    if (scheme == 'http') return TriggerLinkRejected.because('insecure-scheme');

    // 3. No control character, space or DEL anywhere, and only one `#`.
    if (_controlOrSpace.hasMatch(trimmed) || fragment.contains('#')) {
      return TriggerLinkRejected.because('bad-grammar');
    }

    // 4. No userinfo, no port, and a host that meets the host rules.
    final afterScheme = trimmed.substring(schemeMatch!.group(0)!.length);
    final authorityEnd = afterScheme.indexOf(_authorityEnd);
    final linkHost = _parseAuthority(
      authorityEnd == -1 ? afterScheme : afterScheme.substring(0, authorityEnd),
    );
    if (linkHost == null) return TriggerLinkRejected.because('bad-authority');

    // 5. Each reserved name at most once, compared after decoding.
    final fields = <String, String>{};
    final ignored = <String>[];
    for (final (name, value) in pairs) {
      if (_reserved.contains(name)) {
        if (fields.containsKey(name)) {
          return TriggerLinkRejected.because('repeated-param');
        }
        fields[name] = value;
      } else if (name.startsWith('_')) {
        ignored.add('fragment.$name');
      }
    }

    // 6. The contact.
    final from = fields['_from'];
    if (from == null) return TriggerLinkRejected.because('missing-from');
    final fromProblem = _fromProblem(from);
    if (fromProblem != null) return TriggerLinkRejected.because(fromProblem);

    // 7. The handle and the expiry.
    final id = fields['_id'];
    if (id == null || !_idIsValid(id)) {
      return TriggerLinkRejected.because('bad-id');
    }
    int? exp;
    final expText = fields['_exp'];
    if (expText != null) {
      exp = _parseExp(expText);
      if (exp == null) return TriggerLinkRejected.because('bad-exp');
    }

    // 8. The flow: its grammar, its host, whether it is known, its version.
    TriggerFlow? flow;
    TriggerTask? task;
    final typeText = fields['_type'];
    if (typeText != null) {
      final type = _parseType(typeText, linkHost);
      if (type == null) return TriggerLinkRejected.because('bad-type');
      flow = config.flows.where((f) => f.typeBase == type.base).firstOrNull;
      if (flow == null) {
        // A known flow served from another host: no app version reads that.
        final samePath = config.flows.any((f) {
          final base = Uri.parse(f.typeBase);
          return base.path == type.path && base.host != type.host;
        });
        return TriggerLinkRejected.because(
          samePath ? 'wrong-host' : 'unknown-flow',
        );
      }
      if (!flow.accepts(type.major, type.minor)) {
        return TriggerLinkRejected.because('unsupported-version');
      }
      task = TriggerTask(uri: type.uri, major: type.major, minor: type.minor);
    }

    // 9. The flow's own rules for the contact and the expiry.
    if (flow != null) {
      final method = 'did:${from.split(':')[1]}';
      final allowed = flow.allowedDidMethods;
      if (allowed != null && !allowed.contains(method)) {
        return TriggerLinkRejected.because('from-not-allowed');
      }
      if (flow.expRequired && exp == null) {
        return TriggerLinkRejected.because('missing-exp');
      }
    }

    // 10. The expiry, allowing for the phone's clock.
    if (exp != null && exp + config.skewSeconds <= nowSeconds) {
      return TriggerLinkRejected.because('expired');
    }

    return TriggerLinkAccepted(
      from: from,
      id: id,
      exp: exp,
      flow: flow?.flow,
      task: task,
      ignored: ignored,
    );
  }

  static final _edgeWhitespace = RegExp(r'^[\t\n\f\r ]+|[\t\n\f\r ]+$');
  static final _scheme = RegExp(r'^([A-Za-z][A-Za-z0-9+.-]*):\/\/');
  static final _controlOrSpace = RegExp('[\u0000- \u007f]');
  static final _authorityEnd = RegExp('[/?#]');

  static bool _hasReserved(List<(String, String)> pairs) =>
      pairs.any((pair) => _reserved.contains(pair.$1));

  /// WHATWG `application/x-www-form-urlencoded` parsing: split on `&`, skip
  /// empty sequences, split at the first `=`, turn `+` into a space and
  /// percent-decode once, leaving a malformed `%` as written.
  static List<(String, String)> _parseForm(String text) {
    final pairs = <(String, String)>[];
    for (final sequence in text.split('&')) {
      if (sequence.isEmpty) continue;
      final equalsAt = sequence.indexOf('=');
      final name = equalsAt == -1 ? sequence : sequence.substring(0, equalsAt);
      final value = equalsAt == -1 ? '' : sequence.substring(equalsAt + 1);
      pairs.add((_formDecode(name), _formDecode(value)));
    }
    return pairs;
  }

  static String _formDecode(String text) {
    final bytes = utf8.encode(text.replaceAll('+', ' '));
    final decoded = <int>[];
    for (var i = 0; i < bytes.length; i++) {
      final byte = bytes[i];
      final isEscape =
          byte == 0x25 &&
          i + 2 < bytes.length &&
          _isHexDigit(bytes[i + 1]) &&
          _isHexDigit(bytes[i + 2]);
      if (isEscape) {
        decoded.add(
          int.parse(String.fromCharCodes(bytes, i + 1, i + 3), radix: 16),
        );
        i += 2;
        continue;
      }
      decoded.add(byte);
    }
    return utf8.decode(decoded, allowMalformed: true);
  }

  static bool _isHexDigit(int byte) =>
      (byte >= 0x30 && byte <= 0x39) ||
      (byte >= 0x41 && byte <= 0x46) ||
      (byte >= 0x61 && byte <= 0x66);

  /// The host of a raw authority, or null when it has userinfo, a port, or
  /// fails the host rules.
  ///
  /// Stricter than a browser's WHATWG host parser: hosts that only become
  /// valid after percent-decoding or IDNA conversion are refused.
  static String? _parseAuthority(String authority) {
    if (authority.contains('@') ||
        authority.startsWith('[') ||
        authority.contains(':')) {
      return null;
    }
    final host = authority.toLowerCase();
    return hostMeetsRules(host) ? host : null;
  }

  static const _idChar = '(?:[A-Za-z0-9._-]|%[0-9A-Fa-f]{2})';
  static final _didCore = RegExp(
    '^did:([a-z0-9]+):((?:$_idChar*:)*$_idChar+)\$',
  );
  static final _segment = RegExp('^$_idChar+\$');
  static final _scid = RegExp(r'^[A-Za-z0-9]{1,64}$');
  static final _didKeyId = RegExp(r'^z[1-9A-HJ-NP-Za-km-z]+$');

  /// Why the contact cannot be read, or null when it reads.
  static String? _fromProblem(String value) {
    // Agent names are reserved, and refused before any syntax check.
    if (value.contains('/@')) return 'unsupported-vid';
    if (value.isEmpty) return 'bad-from';
    if (!value.startsWith('did:')) return 'unsupported-vid';
    final match = _didCore.firstMatch(value);
    if (match == null) return 'bad-from';
    final methodSpecificId = match.group(2)!;
    final segments = methodSpecificId.split(':');
    final readsAs = switch (match.group(1)) {
      'webvh' =>
        segments.length >= 2 &&
            _scid.hasMatch(segments.first) &&
            segments.skip(1).every(_segment.hasMatch),
      'web' => segments.every(_segment.hasMatch),
      'key' => _didKeyId.hasMatch(methodSpecificId),
      _ => null,
    };
    if (readsAs == null) return 'unsupported-vid';
    return readsAs ? null : 'bad-from';
  }

  static const _base64UrlAlphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';
  static final _handle = RegExp(r'^[A-Za-z0-9_-]{22,43}$');

  /// A handle is 16 to 32 bytes as canonical unpadded base64url.
  static bool _idIsValid(String id) {
    if (!_handle.hasMatch(id)) return false;
    final remainder = id.length % 4;
    if (remainder == 1) return false;
    final last = _base64UrlAlphabet.indexOf(id[id.length - 1]);
    if (remainder == 2) return last & 0x0f == 0;
    if (remainder == 3) return last & 0x03 == 0;
    return true;
  }

  static final _decimal = RegExp(r'^(?:0|[1-9][0-9]*)$');
  static const _maxSafeInteger = 9007199254740991;

  /// `_exp`: 0, or a decimal integer with no leading zero, at most 2^53-1.
  static int? _parseExp(String text) {
    if (!_decimal.hasMatch(text)) return null;
    final value = int.tryParse(text);
    return value == null || value > _maxSafeInteger ? null : value;
  }

  static final _pathType = RegExp(r'^[A-Za-z0-9\-._~/]+$');
  static final _absoluteType = RegExp(
    r'^https:\/\/[^/?#]+\/[^?#]*$',
    caseSensitive: false,
  );
  static final _absoluteTypeChars = RegExp(
    r"^[A-Za-z0-9\-._~:/@!$&'()*+,;=%]+$",
  );
  static final _strayPercent = RegExp('%(?![0-9A-Fa-f]{2})');
  static final _typeParts = RegExp(r'^([A-Za-z]+:\/\/)([^/]+)(\/.*)$');
  static final _version = RegExp(r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$');

  /// `_type`: an absolute https URI, or a path resolved against the link's
  /// host. The last segment is MAJOR.MINOR.
  static _ParsedType? _parseType(String value, String linkHost) {
    final String uri;
    if (value.startsWith('/')) {
      if (value.startsWith('//') || !_pathType.hasMatch(value)) return null;
      final hasDotSegment = value
          .substring(1)
          .split('/')
          .any((segment) => segment == '.' || segment == '..');
      if (hasDotSegment) return null;
      uri = 'https://$linkHost$value';
    } else {
      if (!_absoluteType.hasMatch(value) ||
          !_absoluteTypeChars.hasMatch(value) ||
          _strayPercent.hasMatch(value)) {
        return null;
      }
      uri = value;
    }

    final parts = _typeParts.firstMatch(uri);
    if (parts == null) return null;
    final host = parts.group(2)!;
    final fullPath = parts.group(3)!;
    final cut = fullPath.lastIndexOf('/');
    final version = _version.firstMatch(fullPath.substring(cut + 1));
    if (version == null) return null;
    final major = int.tryParse(version.group(1)!);
    final minor = int.tryParse(version.group(2)!);
    if (major == null || minor == null) return null;
    return _ParsedType(
      uri: uri,
      base: uri.substring(0, uri.length - (fullPath.length - cut)),
      path: fullPath.substring(0, cut),
      host: host,
      major: major,
      minor: minor,
    );
  }
}

class _ParsedType {
  _ParsedType({
    required this.uri,
    required this.base,
    required this.path,
    required this.host,
    required this.major,
    required this.minor,
  });

  final String uri;
  final String base;
  final String path;
  final String host;
  final int major;
  final int minor;
}

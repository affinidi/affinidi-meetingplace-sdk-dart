import 'dart:convert';
import 'dart:typed_data';

const jcsSerializer = JcsSerializer();

/// Canonicalizes and serializes JSON values according to RFC 8785 (JCS).
///
/// This implementation accepts JSON-compatible Dart values, enforces the
/// I-JSON constraints required by JCS, sorts object properties by raw UTF-16
/// code unit order, preserves array element order while recursively
/// canonicalizing nested objects, rejects lone surrogates and non-finite
/// numbers, and emits canonical JSON text or UTF-8 bytes suitable for hashing
/// and signing. Its behavior is covered by focused unit tests using the RFC
/// sample data, official upstream JCS object and array vectors, Appendix B
/// style number cases, primitive root values, and a deterministic differential
/// check against V8 `JSON.stringify` for a broad IEEE 754 sample.
class JcsSerializer {
  const JcsSerializer();

  dynamic canonicalize(dynamic value) {
    return _canonicalizeValue(value, 'top-level JSON value');
  }

  String serialize(dynamic value) {
    return _serializeValue(canonicalize(value));
  }

  Uint8List serializeToUtf8(dynamic value) {
    return Uint8List.fromList(utf8.encode(serialize(value)));
  }

  Map<String, dynamic> canonicalizeObject(Map<String, dynamic> map) {
    return canonicalize(map) as Map<String, dynamic>;
  }

  Map<String, dynamic> _canonicalizeObject(Map<String, dynamic> map) {
    final sorted = <String, dynamic>{};
    final mapKeys = map.keys.toList()..sort(_compareUtf16Strings);

    for (final key in mapKeys) {
      _validateString(key, 'JSON object property name');
      sorted[key] = _canonicalizeValue(map[key], 'property "$key"');
    }

    return sorted;
  }

  String serializeObject(Map<String, dynamic> map) {
    return serialize(map);
  }

  Uint8List serializeObjectToUtf8(Map<String, dynamic> map) {
    return serializeToUtf8(map);
  }

  dynamic _canonicalizeValue(dynamic value, String context) {
    if (value == null || value is bool) {
      return value;
    }

    if (value is String) {
      _validateString(value, context);
      return value;
    }

    if (value is int) {
      _validateInteger(value, context);
      return value;
    }

    if (value is double) {
      _validateDouble(value, context);
      return value;
    }

    if (value is Map<String, dynamic>) {
      return _canonicalizeObject(value);
    }

    if (value is Map) {
      return _canonicalizeObject(_asStringDynamicMap(value, context));
    }

    if (value is List) {
      return [
        for (var index = 0; index < value.length; index++)
          _canonicalizeValue(value[index], '$context[$index]'),
      ];
    }

    throw FormatException(
      'RFC 8785 canonicalization only supports JSON-compatible values. '
      'Found ${value.runtimeType} in $context.',
    );
  }

  String _serializeArray(List<dynamic> list) {
    final buffer = StringBuffer('[');

    for (var index = 0; index < list.length; index++) {
      if (index > 0) {
        buffer.write(',');
      }
      buffer.write(_serializeValue(list[index]));
    }

    buffer.write(']');
    return buffer.toString();
  }

  String _serializeValue(dynamic value) {
    if (value == null || value is bool) {
      return jsonEncode(value);
    }

    if (value is String) {
      _validateString(value, 'JSON string value');
      return jsonEncode(value);
    }

    if (value is int) {
      _validateInteger(value, 'JSON number value');
      return value.toString();
    }

    if (value is double) {
      return _serializeDouble(value);
    }

    if (value is Map<String, dynamic>) {
      final buffer = StringBuffer('{');
      var isFirst = true;

      for (final entry in value.entries) {
        if (!isFirst) {
          buffer.write(',');
        }
        isFirst = false;
        buffer.write(jsonEncode(entry.key));
        buffer.write(':');
        buffer.write(_serializeValue(entry.value));
      }

      buffer.write('}');
      return buffer.toString();
    }

    if (value is Map) {
      return _serializeValue(
        _canonicalizeObject(_asStringDynamicMap(value, 'JSON object value')),
      );
    }

    if (value is List) {
      return _serializeArray(value);
    }

    throw FormatException(
      'RFC 8785 canonicalization only supports JSON-compatible values. '
      'Found ${value.runtimeType}.',
    );
  }

  String _serializeDouble(double value) {
    _validateDouble(value, 'JSON number value');

    if (value == 0) {
      return '0';
    }

    final serialized = jsonEncode(value);
    if (serialized.endsWith('.0')) {
      return serialized.substring(0, serialized.length - 2);
    }
    return serialized;
  }
}

const _ieee754IntegerPrecisionBits = 53;
const _highSurrogateStart = 0xD800;
const _highSurrogateEnd = 0xDBFF;
const _lowSurrogateStart = 0xDC00;
const _lowSurrogateEnd = 0xDFFF;

Map<String, dynamic> _asStringDynamicMap(Map map, String context) {
  final typed = <String, dynamic>{};

  for (final entry in map.entries) {
    if (entry.key is! String) {
      throw FormatException(
        'RFC 8785 requires JSON object property names to be strings. '
        'Found ${entry.key.runtimeType} in $context.',
      );
    }

    typed[entry.key as String] = entry.value;
  }

  return typed;
}

void _validateInteger(int value, String context) {
  if (!_isExactlyRepresentableAsDouble(value)) {
    throw FormatException(
      'RFC 8785 requires JSON integers to be exactly representable as IEEE 754 '
      'double-precision values. Store larger exact integers as JSON strings '
      'instead. Found non-representable integer $value in $context.',
    );
  }
}

bool _isExactlyRepresentableAsDouble(int value) {
  if (value == 0) {
    return true;
  }

  final magnitude = value.abs();
  final excessPrecisionBits =
      magnitude.bitLength - _ieee754IntegerPrecisionBits;

  if (excessPrecisionBits <= 0) {
    return true;
  }

  final trailingBitMask = (1 << excessPrecisionBits) - 1;
  return (magnitude & trailingBitMask) == 0;
}

void _validateDouble(double value, String context) {
  if (!value.isFinite) {
    throw FormatException(
      'RFC 8785 forbids NaN and Infinity. Found $value in $context.',
    );
  }
}

void _validateString(String value, String context) {
  final codeUnits = value.codeUnits;

  for (var index = 0; index < codeUnits.length; index++) {
    final codeUnit = codeUnits[index];
    final isHighSurrogate =
        codeUnit >= _highSurrogateStart && codeUnit <= _highSurrogateEnd;
    final isLowSurrogate =
        codeUnit >= _lowSurrogateStart && codeUnit <= _lowSurrogateEnd;

    if (isHighSurrogate) {
      final hasNext = index + 1 < codeUnits.length;
      if (!hasNext) {
        throw FormatException(
          'RFC 8785 forbids lone surrogate code units in $context.',
        );
      }

      final next = codeUnits[index + 1];
      if (next < _lowSurrogateStart || next > _lowSurrogateEnd) {
        throw FormatException(
          'RFC 8785 forbids lone surrogate code units in $context.',
        );
      }

      index++;
      continue;
    }

    if (isLowSurrogate) {
      throw FormatException(
        'RFC 8785 forbids lone surrogate code units in $context.',
      );
    }
  }
}

int _compareUtf16Strings(String left, String right) {
  final leftUnits = left.codeUnits;
  final rightUnits = right.codeUnits;
  final limit = leftUnits.length < rightUnits.length
      ? leftUnits.length
      : rightUnits.length;

  for (var index = 0; index < limit; index++) {
    final comparison = leftUnits[index].compareTo(rightUnits[index]);
    if (comparison != 0) {
      return comparison;
    }
  }

  return leftUnits.length.compareTo(rightUnits.length);
}

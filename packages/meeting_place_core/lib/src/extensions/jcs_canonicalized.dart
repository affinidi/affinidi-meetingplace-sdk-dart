import 'dart:typed_data';

import '../utils/jcs_serializer.dart';

dynamic canonicalizeJcsValue(dynamic value) =>
    jcsSerializer.canonicalize(value);

String toCanonicalJcsJson(dynamic value) => jcsSerializer.serialize(value);

Uint8List toCanonicalJcsUtf8(dynamic value) =>
    jcsSerializer.serializeToUtf8(value);

extension JCSCanonicalizedMap on Map<String, dynamic> {
  /// Returns a new map with the same keys and values as this map,
  /// but with all nested maps recursively sorted and validated for JCS use.
  Map<String, dynamic> canonicalized() =>
      jcsSerializer.canonicalizeObject(this);

  /// Returns a JSON string representation of this map,
  /// with all nested maps recursively canonicalized according to RFC 8785.
  String toCanonicalJson() => jcsSerializer.serializeObject(this);

  /// Returns the canonical RFC 8785 JSON representation encoded as UTF-8.
  Uint8List toCanonicalUtf8() => jcsSerializer.serializeObjectToUtf8(this);
}

extension JCSCanonicalizedList on List<dynamic> {
  /// Returns a new list whose nested object values are recursively
  /// canonicalized according to RFC 8785, preserving array element order.
  List<dynamic> canonicalized() => canonicalizeJcsValue(this) as List<dynamic>;

  /// Returns a JSON string representation of this array, with all
  /// nested object members recursively canonicalized according to RFC 8785.
  String toCanonicalJson() => toCanonicalJcsJson(this);

  /// Returns the canonical RFC 8785 JSON representation encoded as UTF-8.
  Uint8List toCanonicalUtf8() => toCanonicalJcsUtf8(this);
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'matrix_token.g.dart';

/// List of required parameters to obtain a Matrix login token.
///
/// Properties:
/// * [challengeResponse] - A base64 encoded string containing the encrypted
///   DIDComm message signed with the user's private key associated with their
///   Decentralised Identifier (DID).
/// * [homeserver] - Matrix homeserver URL that the issued token should
///   authenticate against.
@BuiltValue()
abstract class MatrixToken implements Built<MatrixToken, MatrixTokenBuilder> {
  /// A base64 encoded string containing the encrypted DIDComm message signed
  /// with the user's private key associated with their Decentralised
  /// Identifier (DID).
  @BuiltValueField(wireName: r'challenge_response')
  String? get challengeResponse;

  /// Matrix homeserver URL that the issued token should authenticate against.
  @BuiltValueField(wireName: r'homeserver')
  String? get homeserver;

  MatrixToken._();

  factory MatrixToken([void updates(MatrixTokenBuilder b)]) = _$MatrixToken;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatrixTokenBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatrixToken> get serializer => _$MatrixTokenSerializer();
}

class _$MatrixTokenSerializer implements PrimitiveSerializer<MatrixToken> {
  @override
  final Iterable<Type> types = const [MatrixToken, _$MatrixToken];

  @override
  final String wireName = r'MatrixToken';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatrixToken object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.challengeResponse != null) {
      yield r'challenge_response';
      yield serializers.serialize(
        object.challengeResponse,
        specifiedType: const FullType(String),
      );
    }
    if (object.homeserver != null) {
      yield r'homeserver';
      yield serializers.serialize(
        object.homeserver,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MatrixToken object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(
      serializers,
      object,
      specifiedType: specifiedType,
    ).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatrixTokenBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'challenge_response':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.challengeResponse = valueDes;
          break;
        case r'homeserver':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.homeserver = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MatrixToken deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatrixTokenBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

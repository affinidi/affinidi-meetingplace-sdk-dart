//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'did_authenticate.g.dart';

/// List of required parameters to authenticate the user.
///
/// Properties:
/// * [challengeResponse] - A base64 encoded string containing the encrypted DIDComm  message signed with the user's private key associated with  their Decentralised Identifier (DID).
@BuiltValue()
abstract class DidAuthenticate
    implements Built<DidAuthenticate, DidAuthenticateBuilder> {
  /// A base64 encoded string containing the encrypted DIDComm  message signed with the user's private key associated with  their Decentralised Identifier (DID).
  @BuiltValueField(wireName: r'challenge_response')
  String? get challengeResponse;

  DidAuthenticate._();

  factory DidAuthenticate([void updates(DidAuthenticateBuilder b)]) =
      _$DidAuthenticate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DidAuthenticateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DidAuthenticate> get serializer =>
      _$DidAuthenticateSerializer();
}

class _$DidAuthenticateSerializer
    implements PrimitiveSerializer<DidAuthenticate> {
  @override
  final Iterable<Type> types = const [DidAuthenticate, _$DidAuthenticate];

  @override
  final String wireName = r'DidAuthenticate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DidAuthenticate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.challengeResponse != null) {
      yield r'challenge_response';
      yield serializers.serialize(
        object.challengeResponse,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DidAuthenticate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object,
            specifiedType: specifiedType)
        .toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DidAuthenticateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'challenge_response':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.challengeResponse = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DidAuthenticate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DidAuthenticateBuilder();
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

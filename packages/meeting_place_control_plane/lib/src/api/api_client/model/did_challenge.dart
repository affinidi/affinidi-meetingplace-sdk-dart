//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'did_challenge.g.dart';

/// List of required parameters to initiate authentication process.
///
/// Properties:
/// * [did] - Decentralised Identifier (DID) of the user to initialise the  authentication process and generate the challenge token.
@BuiltValue()
abstract class DidChallenge
    implements Built<DidChallenge, DidChallengeBuilder> {
  /// Decentralised Identifier (DID) of the user to initialise the  authentication process and generate the challenge token.
  @BuiltValueField(wireName: r'did')
  String? get did;

  DidChallenge._();

  factory DidChallenge([void updates(DidChallengeBuilder b)]) = _$DidChallenge;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DidChallengeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DidChallenge> get serializer => _$DidChallengeSerializer();
}

class _$DidChallengeSerializer implements PrimitiveSerializer<DidChallenge> {
  @override
  final Iterable<Type> types = const [DidChallenge, _$DidChallenge];

  @override
  final String wireName = r'DidChallenge';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DidChallenge object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.did != null) {
      yield r'did';
      yield serializers.serialize(
        object.did,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DidChallenge object, {
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
    required DidChallengeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'did':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.did = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DidChallenge deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DidChallengeBuilder();
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

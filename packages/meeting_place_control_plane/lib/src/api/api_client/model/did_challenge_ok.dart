//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'did_challenge_ok.g.dart';

/// DidChallengeOK
///
/// Properties:
/// * [challenge]
@BuiltValue()
abstract class DidChallengeOK
    implements Built<DidChallengeOK, DidChallengeOKBuilder> {
  @BuiltValueField(wireName: r'challenge')
  String? get challenge;

  DidChallengeOK._();

  factory DidChallengeOK([void updates(DidChallengeOKBuilder b)]) =
      _$DidChallengeOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DidChallengeOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DidChallengeOK> get serializer =>
      _$DidChallengeOKSerializer();
}

class _$DidChallengeOKSerializer
    implements PrimitiveSerializer<DidChallengeOK> {
  @override
  final Iterable<Type> types = const [DidChallengeOK, _$DidChallengeOK];

  @override
  final String wireName = r'DidChallengeOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DidChallengeOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.challenge != null) {
      yield r'challenge';
      yield serializers.serialize(
        object.challenge,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DidChallengeOK object, {
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
    required DidChallengeOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'challenge':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.challenge = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DidChallengeOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DidChallengeOKBuilder();
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

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'matrix_challenge_ok.g.dart';

/// MatrixChallengeOK
///
/// Properties:
/// * [challenge]
@BuiltValue()
abstract class MatrixChallengeOK
    implements Built<MatrixChallengeOK, MatrixChallengeOKBuilder> {
  @BuiltValueField(wireName: r'challenge')
  String? get challenge;

  MatrixChallengeOK._();

  factory MatrixChallengeOK([void updates(MatrixChallengeOKBuilder b)]) =
      _$MatrixChallengeOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatrixChallengeOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatrixChallengeOK> get serializer =>
      _$MatrixChallengeOKSerializer();
}

class _$MatrixChallengeOKSerializer
    implements PrimitiveSerializer<MatrixChallengeOK> {
  @override
  final Iterable<Type> types = const [MatrixChallengeOK, _$MatrixChallengeOK];

  @override
  final String wireName = r'MatrixChallengeOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatrixChallengeOK object, {
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
    MatrixChallengeOK object, {
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
    required MatrixChallengeOKBuilder result,
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
  MatrixChallengeOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatrixChallengeOKBuilder();
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

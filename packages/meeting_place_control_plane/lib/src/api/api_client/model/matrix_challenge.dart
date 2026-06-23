//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'matrix_challenge.g.dart';

/// List of required parameters to initiate the Matrix challenge.
///
/// Properties:
/// * [did] - Decentralised Identifier (DID) of the user to initialise the
///   Matrix authentication process and generate the challenge token.
@BuiltValue()
abstract class MatrixChallenge
    implements Built<MatrixChallenge, MatrixChallengeBuilder> {
  /// Decentralised Identifier (DID) of the user to initialise the Matrix
  /// authentication process and generate the challenge token.
  @BuiltValueField(wireName: r'did')
  String? get did;

  MatrixChallenge._();

  factory MatrixChallenge([void updates(MatrixChallengeBuilder b)]) =
      _$MatrixChallenge;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatrixChallengeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatrixChallenge> get serializer =>
      _$MatrixChallengeSerializer();
}

class _$MatrixChallengeSerializer
    implements PrimitiveSerializer<MatrixChallenge> {
  @override
  final Iterable<Type> types = const [MatrixChallenge, _$MatrixChallenge];

  @override
  final String wireName = r'MatrixChallenge';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatrixChallenge object, {
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
    MatrixChallenge object, {
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
    required MatrixChallengeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'did':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
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
  MatrixChallenge deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatrixChallengeBuilder();
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

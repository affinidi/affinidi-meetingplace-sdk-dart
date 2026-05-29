//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'matrix_token_ok.g.dart';

/// MatrixTokenOK
///
/// Properties:
/// * [token]
@BuiltValue()
abstract class MatrixTokenOK
    implements Built<MatrixTokenOK, MatrixTokenOKBuilder> {
  @BuiltValueField(wireName: r'token')
  String? get token;

  MatrixTokenOK._();

  factory MatrixTokenOK([void updates(MatrixTokenOKBuilder b)]) =
      _$MatrixTokenOK;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatrixTokenOKBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatrixTokenOK> get serializer =>
      _$MatrixTokenOKSerializer();
}

class _$MatrixTokenOKSerializer implements PrimitiveSerializer<MatrixTokenOK> {
  @override
  final Iterable<Type> types = const [MatrixTokenOK, _$MatrixTokenOK];

  @override
  final String wireName = r'MatrixTokenOK';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatrixTokenOK object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.token != null) {
      yield r'token';
      yield serializers.serialize(
        object.token,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MatrixTokenOK object, {
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
    required MatrixTokenOKBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'token':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.token = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MatrixTokenOK deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatrixTokenOKBuilder();
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

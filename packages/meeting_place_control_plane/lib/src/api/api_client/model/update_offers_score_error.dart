//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'update_offers_score_error.g.dart';

/// UpdateOffersScoreError
///
/// Properties:
/// * [errorCode] 
/// * [errorMessage] 
@BuiltValue()
abstract class UpdateOffersScoreError implements Built<UpdateOffersScoreError, UpdateOffersScoreErrorBuilder> {
  @BuiltValueField(wireName: r'errorCode')
  String get errorCode;

  @BuiltValueField(wireName: r'errorMessage')
  String get errorMessage;

  UpdateOffersScoreError._();

  factory UpdateOffersScoreError([void updates(UpdateOffersScoreErrorBuilder b)]) = _$UpdateOffersScoreError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UpdateOffersScoreErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UpdateOffersScoreError> get serializer => _$UpdateOffersScoreErrorSerializer();
}

class _$UpdateOffersScoreErrorSerializer implements PrimitiveSerializer<UpdateOffersScoreError> {
  @override
  final Iterable<Type> types = const [UpdateOffersScoreError, _$UpdateOffersScoreError];

  @override
  final String wireName = r'UpdateOffersScoreError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UpdateOffersScoreError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'errorCode';
    yield serializers.serialize(
      object.errorCode,
      specifiedType: const FullType(String),
    );
    yield r'errorMessage';
    yield serializers.serialize(
      object.errorMessage,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UpdateOffersScoreError object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UpdateOffersScoreErrorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'errorCode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.errorCode = valueDes;
          break;
        case r'errorMessage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.errorMessage = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UpdateOffersScoreError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UpdateOffersScoreErrorBuilder();
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


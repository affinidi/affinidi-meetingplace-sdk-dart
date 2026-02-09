//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'offer_unprocessable_entity_error.g.dart';

/// The offer is no longer valid due to max usage or validity date expiration.
///
/// Properties:
/// * [errorCode]
/// * [errorMessage]
@BuiltValue()
abstract class OfferUnprocessableEntityError
    implements
        Built<
          OfferUnprocessableEntityError,
          OfferUnprocessableEntityErrorBuilder
        > {
  @BuiltValueField(wireName: r'errorCode')
  String get errorCode;

  @BuiltValueField(wireName: r'errorMessage')
  String get errorMessage;

  OfferUnprocessableEntityError._();

  factory OfferUnprocessableEntityError([
    void updates(OfferUnprocessableEntityErrorBuilder b),
  ]) = _$OfferUnprocessableEntityError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OfferUnprocessableEntityErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OfferUnprocessableEntityError> get serializer =>
      _$OfferUnprocessableEntityErrorSerializer();
}

class _$OfferUnprocessableEntityErrorSerializer
    implements PrimitiveSerializer<OfferUnprocessableEntityError> {
  @override
  final Iterable<Type> types = const [
    OfferUnprocessableEntityError,
    _$OfferUnprocessableEntityError,
  ];

  @override
  final String wireName = r'OfferUnprocessableEntityError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OfferUnprocessableEntityError object, {
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
    OfferUnprocessableEntityError object, {
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
    required OfferUnprocessableEntityErrorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'errorCode':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.errorCode = valueDes;
          break;
        case r'errorMessage':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
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
  OfferUnprocessableEntityError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OfferUnprocessableEntityErrorBuilder();
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

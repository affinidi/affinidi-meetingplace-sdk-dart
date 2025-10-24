//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import '../model/not_found_error_details_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'invalid_offer_error.g.dart';

/// The details to identify the offer may be valid,  but it may have exceeded its usage limit or already expired.
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class InvalidOfferError
    implements Built<InvalidOfferError, InvalidOfferErrorBuilder> {
  @BuiltValueField(wireName: r'name')
  InvalidOfferErrorNameEnum get name;
  // enum nameEnum {  InvalidOfferError,  };

  @BuiltValueField(wireName: r'message')
  InvalidOfferErrorMessageEnum get message;
  // enum messageEnum {  No valid offer found that matches the details provided.,  };

  @BuiltValueField(wireName: r'httpStatusCode')
  InvalidOfferErrorHttpStatusCodeEnum get httpStatusCode;
  // enum httpStatusCodeEnum {  404,  };

  @BuiltValueField(wireName: r'traceId')
  String get traceId;

  @BuiltValueField(wireName: r'details')
  BuiltList<NotFoundErrorDetailsInner>? get details;

  InvalidOfferError._();

  factory InvalidOfferError([void updates(InvalidOfferErrorBuilder b)]) =
      _$InvalidOfferError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(InvalidOfferErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<InvalidOfferError> get serializer =>
      _$InvalidOfferErrorSerializer();
}

class _$InvalidOfferErrorSerializer
    implements PrimitiveSerializer<InvalidOfferError> {
  @override
  final Iterable<Type> types = const [InvalidOfferError, _$InvalidOfferError];

  @override
  final String wireName = r'InvalidOfferError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    InvalidOfferError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(InvalidOfferErrorNameEnum),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(InvalidOfferErrorMessageEnum),
    );
    yield r'httpStatusCode';
    yield serializers.serialize(
      object.httpStatusCode,
      specifiedType: const FullType(InvalidOfferErrorHttpStatusCodeEnum),
    );
    yield r'traceId';
    yield serializers.serialize(
      object.traceId,
      specifiedType: const FullType(String),
    );
    if (object.details != null) {
      yield r'details';
      yield serializers.serialize(
        object.details,
        specifiedType: const FullType(BuiltList, [
          FullType(NotFoundErrorDetailsInner),
        ]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    InvalidOfferError object, {
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
    required InvalidOfferErrorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(InvalidOfferErrorNameEnum),
          ) as InvalidOfferErrorNameEnum;
          result.name = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(InvalidOfferErrorMessageEnum),
          ) as InvalidOfferErrorMessageEnum;
          result.message = valueDes;
          break;
        case r'httpStatusCode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
              InvalidOfferErrorHttpStatusCodeEnum,
            ),
          ) as InvalidOfferErrorHttpStatusCodeEnum;
          result.httpStatusCode = valueDes;
          break;
        case r'traceId':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.traceId = valueDes;
          break;
        case r'details':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [
              FullType(NotFoundErrorDetailsInner),
            ]),
          ) as BuiltList<NotFoundErrorDetailsInner>;
          result.details.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  InvalidOfferError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = InvalidOfferErrorBuilder();
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

class InvalidOfferErrorNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'InvalidOfferError')
  static const InvalidOfferErrorNameEnum invalidOfferError =
      _$invalidOfferErrorNameEnum_invalidOfferError;

  static Serializer<InvalidOfferErrorNameEnum> get serializer =>
      _$invalidOfferErrorNameEnumSerializer;

  const InvalidOfferErrorNameEnum._(String name) : super(name);

  static BuiltSet<InvalidOfferErrorNameEnum> get values =>
      _$invalidOfferErrorNameEnumValues;
  static InvalidOfferErrorNameEnum valueOf(String name) =>
      _$invalidOfferErrorNameEnumValueOf(name);
}

class InvalidOfferErrorMessageEnum extends EnumClass {
  @BuiltValueEnumConst(
    wireName: r'No valid offer found that matches the details provided.',
  )
  static const InvalidOfferErrorMessageEnum
      noValidOfferFoundThatMatchesTheDetailsProvidedPeriod =
      _$invalidOfferErrorMessageEnum_noValidOfferFoundThatMatchesTheDetailsProvidedPeriod;

  static Serializer<InvalidOfferErrorMessageEnum> get serializer =>
      _$invalidOfferErrorMessageEnumSerializer;

  const InvalidOfferErrorMessageEnum._(String name) : super(name);

  static BuiltSet<InvalidOfferErrorMessageEnum> get values =>
      _$invalidOfferErrorMessageEnumValues;
  static InvalidOfferErrorMessageEnum valueOf(String name) =>
      _$invalidOfferErrorMessageEnumValueOf(name);
}

class InvalidOfferErrorHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 404)
  static const InvalidOfferErrorHttpStatusCodeEnum number404 =
      _$invalidOfferErrorHttpStatusCodeEnum_number404;

  static Serializer<InvalidOfferErrorHttpStatusCodeEnum> get serializer =>
      _$invalidOfferErrorHttpStatusCodeEnumSerializer;

  const InvalidOfferErrorHttpStatusCodeEnum._(String name) : super(name);

  static BuiltSet<InvalidOfferErrorHttpStatusCodeEnum> get values =>
      _$invalidOfferErrorHttpStatusCodeEnumValues;
  static InvalidOfferErrorHttpStatusCodeEnum valueOf(String name) =>
      _$invalidOfferErrorHttpStatusCodeEnumValueOf(name);
}

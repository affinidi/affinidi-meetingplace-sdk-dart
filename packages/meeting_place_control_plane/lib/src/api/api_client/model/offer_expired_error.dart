//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import '../model/not_found_error_details_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'offer_expired_error.g.dart';

/// The details to identify the offer may be valid, but it may  have exceeded its usage limit or already expired.
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class OfferExpiredError
    implements Built<OfferExpiredError, OfferExpiredErrorBuilder> {
  @BuiltValueField(wireName: r'name')
  OfferExpiredErrorNameEnum get name;
  // enum nameEnum {  OfferExpiredError,  };

  @BuiltValueField(wireName: r'message')
  OfferExpiredErrorMessageEnum get message;
  // enum messageEnum {  The offer has expired,  };

  @BuiltValueField(wireName: r'httpStatusCode')
  OfferExpiredErrorHttpStatusCodeEnum get httpStatusCode;
  // enum httpStatusCodeEnum {  404,  };

  @BuiltValueField(wireName: r'traceId')
  String get traceId;

  @BuiltValueField(wireName: r'details')
  BuiltList<NotFoundErrorDetailsInner>? get details;

  OfferExpiredError._();

  factory OfferExpiredError([void updates(OfferExpiredErrorBuilder b)]) =
      _$OfferExpiredError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OfferExpiredErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OfferExpiredError> get serializer =>
      _$OfferExpiredErrorSerializer();
}

class _$OfferExpiredErrorSerializer
    implements PrimitiveSerializer<OfferExpiredError> {
  @override
  final Iterable<Type> types = const [OfferExpiredError, _$OfferExpiredError];

  @override
  final String wireName = r'OfferExpiredError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OfferExpiredError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(OfferExpiredErrorNameEnum),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(OfferExpiredErrorMessageEnum),
    );
    yield r'httpStatusCode';
    yield serializers.serialize(
      object.httpStatusCode,
      specifiedType: const FullType(OfferExpiredErrorHttpStatusCodeEnum),
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
    OfferExpiredError object, {
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
    required OfferExpiredErrorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OfferExpiredErrorNameEnum),
          ) as OfferExpiredErrorNameEnum;
          result.name = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(OfferExpiredErrorMessageEnum),
          ) as OfferExpiredErrorMessageEnum;
          result.message = valueDes;
          break;
        case r'httpStatusCode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
              OfferExpiredErrorHttpStatusCodeEnum,
            ),
          ) as OfferExpiredErrorHttpStatusCodeEnum;
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
  OfferExpiredError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OfferExpiredErrorBuilder();
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

class OfferExpiredErrorNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'OfferExpiredError')
  static const OfferExpiredErrorNameEnum offerExpiredError =
      _$offerExpiredErrorNameEnum_offerExpiredError;

  static Serializer<OfferExpiredErrorNameEnum> get serializer =>
      _$offerExpiredErrorNameEnumSerializer;

  const OfferExpiredErrorNameEnum._(String name) : super(name);

  static BuiltSet<OfferExpiredErrorNameEnum> get values =>
      _$offerExpiredErrorNameEnumValues;
  static OfferExpiredErrorNameEnum valueOf(String name) =>
      _$offerExpiredErrorNameEnumValueOf(name);
}

class OfferExpiredErrorMessageEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'The offer has expired')
  static const OfferExpiredErrorMessageEnum theOfferHasExpired =
      _$offerExpiredErrorMessageEnum_theOfferHasExpired;

  static Serializer<OfferExpiredErrorMessageEnum> get serializer =>
      _$offerExpiredErrorMessageEnumSerializer;

  const OfferExpiredErrorMessageEnum._(String name) : super(name);

  static BuiltSet<OfferExpiredErrorMessageEnum> get values =>
      _$offerExpiredErrorMessageEnumValues;
  static OfferExpiredErrorMessageEnum valueOf(String name) =>
      _$offerExpiredErrorMessageEnumValueOf(name);
}

class OfferExpiredErrorHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 404)
  static const OfferExpiredErrorHttpStatusCodeEnum number404 =
      _$offerExpiredErrorHttpStatusCodeEnum_number404;

  static Serializer<OfferExpiredErrorHttpStatusCodeEnum> get serializer =>
      _$offerExpiredErrorHttpStatusCodeEnumSerializer;

  const OfferExpiredErrorHttpStatusCodeEnum._(String name) : super(name);

  static BuiltSet<OfferExpiredErrorHttpStatusCodeEnum> get values =>
      _$offerExpiredErrorHttpStatusCodeEnumValues;
  static OfferExpiredErrorHttpStatusCodeEnum valueOf(String name) =>
      _$offerExpiredErrorHttpStatusCodeEnumValueOf(name);
}

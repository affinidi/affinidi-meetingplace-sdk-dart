//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import '../model/not_found_error_details_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'offer_limit_exceeded_error.g.dart';

/// Either the maxQuery, maxClaim or validity date is not valid.
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class OfferLimitExceededError
    implements Built<OfferLimitExceededError, OfferLimitExceededErrorBuilder> {
  @BuiltValueField(wireName: r'name')
  OfferLimitExceededErrorNameEnum get name;
  // enum nameEnum {  OfferLimitExceededError,  };

  @BuiltValueField(wireName: r'message')
  OfferLimitExceededErrorMessageEnum get message;
  // enum messageEnum {  The offer is no longer valid,  };

  @BuiltValueField(wireName: r'httpStatusCode')
  OfferLimitExceededErrorHttpStatusCodeEnum get httpStatusCode;
  // enum httpStatusCodeEnum {  404,  };

  @BuiltValueField(wireName: r'traceId')
  String get traceId;

  @BuiltValueField(wireName: r'details')
  BuiltList<NotFoundErrorDetailsInner>? get details;

  OfferLimitExceededError._();

  factory OfferLimitExceededError([
    void updates(OfferLimitExceededErrorBuilder b),
  ]) = _$OfferLimitExceededError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OfferLimitExceededErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OfferLimitExceededError> get serializer =>
      _$OfferLimitExceededErrorSerializer();
}

class _$OfferLimitExceededErrorSerializer
    implements PrimitiveSerializer<OfferLimitExceededError> {
  @override
  final Iterable<Type> types = const [
    OfferLimitExceededError,
    _$OfferLimitExceededError,
  ];

  @override
  final String wireName = r'OfferLimitExceededError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OfferLimitExceededError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(OfferLimitExceededErrorNameEnum),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(OfferLimitExceededErrorMessageEnum),
    );
    yield r'httpStatusCode';
    yield serializers.serialize(
      object.httpStatusCode,
      specifiedType: const FullType(OfferLimitExceededErrorHttpStatusCodeEnum),
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
    OfferLimitExceededError object, {
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
    required OfferLimitExceededErrorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      OfferLimitExceededErrorNameEnum,
                    ),
                  )
                  as OfferLimitExceededErrorNameEnum;
          result.name = valueDes;
          break;
        case r'message':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      OfferLimitExceededErrorMessageEnum,
                    ),
                  )
                  as OfferLimitExceededErrorMessageEnum;
          result.message = valueDes;
          break;
        case r'httpStatusCode':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      OfferLimitExceededErrorHttpStatusCodeEnum,
                    ),
                  )
                  as OfferLimitExceededErrorHttpStatusCodeEnum;
          result.httpStatusCode = valueDes;
          break;
        case r'traceId':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(String),
                  )
                  as String;
          result.traceId = valueDes;
          break;
        case r'details':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(BuiltList, [
                      FullType(NotFoundErrorDetailsInner),
                    ]),
                  )
                  as BuiltList<NotFoundErrorDetailsInner>;
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
  OfferLimitExceededError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OfferLimitExceededErrorBuilder();
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

class OfferLimitExceededErrorNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'OfferLimitExceededError')
  static const OfferLimitExceededErrorNameEnum offerLimitExceededError =
      _$offerLimitExceededErrorNameEnum_offerLimitExceededError;

  static Serializer<OfferLimitExceededErrorNameEnum> get serializer =>
      _$offerLimitExceededErrorNameEnumSerializer;

  const OfferLimitExceededErrorNameEnum._(String name) : super(name);

  static BuiltSet<OfferLimitExceededErrorNameEnum> get values =>
      _$offerLimitExceededErrorNameEnumValues;
  static OfferLimitExceededErrorNameEnum valueOf(String name) =>
      _$offerLimitExceededErrorNameEnumValueOf(name);
}

class OfferLimitExceededErrorMessageEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'The offer is no longer valid')
  static const OfferLimitExceededErrorMessageEnum theOfferIsNoLongerValid =
      _$offerLimitExceededErrorMessageEnum_theOfferIsNoLongerValid;

  static Serializer<OfferLimitExceededErrorMessageEnum> get serializer =>
      _$offerLimitExceededErrorMessageEnumSerializer;

  const OfferLimitExceededErrorMessageEnum._(String name) : super(name);

  static BuiltSet<OfferLimitExceededErrorMessageEnum> get values =>
      _$offerLimitExceededErrorMessageEnumValues;
  static OfferLimitExceededErrorMessageEnum valueOf(String name) =>
      _$offerLimitExceededErrorMessageEnumValueOf(name);
}

class OfferLimitExceededErrorHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 404)
  static const OfferLimitExceededErrorHttpStatusCodeEnum number404 =
      _$offerLimitExceededErrorHttpStatusCodeEnum_number404;

  static Serializer<OfferLimitExceededErrorHttpStatusCodeEnum> get serializer =>
      _$offerLimitExceededErrorHttpStatusCodeEnumSerializer;

  const OfferLimitExceededErrorHttpStatusCodeEnum._(String name) : super(name);

  static BuiltSet<OfferLimitExceededErrorHttpStatusCodeEnum> get values =>
      _$offerLimitExceededErrorHttpStatusCodeEnumValues;
  static OfferLimitExceededErrorHttpStatusCodeEnum valueOf(String name) =>
      _$offerLimitExceededErrorHttpStatusCodeEnumValueOf(name);
}

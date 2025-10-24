//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import '../model/not_found_error_details_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'invalid_acceptance_error.g.dart';

/// The details to identify the offer may be valid, but it may  have already expired, or the offerLink provided is invalid.
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class InvalidAcceptanceError
    implements Built<InvalidAcceptanceError, InvalidAcceptanceErrorBuilder> {
  @BuiltValueField(wireName: r'name')
  InvalidAcceptanceErrorNameEnum get name;
  // enum nameEnum {  InvalidAcceptanceError,  };

  @BuiltValueField(wireName: r'message')
  InvalidAcceptanceErrorMessageEnum get message;
  // enum messageEnum {  No valid acceptance found that matches the details provided.,  };

  @BuiltValueField(wireName: r'httpStatusCode')
  InvalidAcceptanceErrorHttpStatusCodeEnum get httpStatusCode;
  // enum httpStatusCodeEnum {  404,  };

  @BuiltValueField(wireName: r'traceId')
  String get traceId;

  @BuiltValueField(wireName: r'details')
  BuiltList<NotFoundErrorDetailsInner>? get details;

  InvalidAcceptanceError._();

  factory InvalidAcceptanceError([
    void updates(InvalidAcceptanceErrorBuilder b),
  ]) = _$InvalidAcceptanceError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(InvalidAcceptanceErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<InvalidAcceptanceError> get serializer =>
      _$InvalidAcceptanceErrorSerializer();
}

class _$InvalidAcceptanceErrorSerializer
    implements PrimitiveSerializer<InvalidAcceptanceError> {
  @override
  final Iterable<Type> types = const [
    InvalidAcceptanceError,
    _$InvalidAcceptanceError,
  ];

  @override
  final String wireName = r'InvalidAcceptanceError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    InvalidAcceptanceError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(InvalidAcceptanceErrorNameEnum),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(InvalidAcceptanceErrorMessageEnum),
    );
    yield r'httpStatusCode';
    yield serializers.serialize(
      object.httpStatusCode,
      specifiedType: const FullType(InvalidAcceptanceErrorHttpStatusCodeEnum),
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
    InvalidAcceptanceError object, {
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
    required InvalidAcceptanceErrorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
              InvalidAcceptanceErrorNameEnum,
            ),
          ) as InvalidAcceptanceErrorNameEnum;
          result.name = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
              InvalidAcceptanceErrorMessageEnum,
            ),
          ) as InvalidAcceptanceErrorMessageEnum;
          result.message = valueDes;
          break;
        case r'httpStatusCode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
              InvalidAcceptanceErrorHttpStatusCodeEnum,
            ),
          ) as InvalidAcceptanceErrorHttpStatusCodeEnum;
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
  InvalidAcceptanceError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = InvalidAcceptanceErrorBuilder();
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

class InvalidAcceptanceErrorNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'InvalidAcceptanceError')
  static const InvalidAcceptanceErrorNameEnum invalidAcceptanceError =
      _$invalidAcceptanceErrorNameEnum_invalidAcceptanceError;

  static Serializer<InvalidAcceptanceErrorNameEnum> get serializer =>
      _$invalidAcceptanceErrorNameEnumSerializer;

  const InvalidAcceptanceErrorNameEnum._(String name) : super(name);

  static BuiltSet<InvalidAcceptanceErrorNameEnum> get values =>
      _$invalidAcceptanceErrorNameEnumValues;
  static InvalidAcceptanceErrorNameEnum valueOf(String name) =>
      _$invalidAcceptanceErrorNameEnumValueOf(name);
}

class InvalidAcceptanceErrorMessageEnum extends EnumClass {
  @BuiltValueEnumConst(
    wireName: r'No valid acceptance found that matches the details provided.',
  )
  static const InvalidAcceptanceErrorMessageEnum
      noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod =
      _$invalidAcceptanceErrorMessageEnum_noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod;

  static Serializer<InvalidAcceptanceErrorMessageEnum> get serializer =>
      _$invalidAcceptanceErrorMessageEnumSerializer;

  const InvalidAcceptanceErrorMessageEnum._(String name) : super(name);

  static BuiltSet<InvalidAcceptanceErrorMessageEnum> get values =>
      _$invalidAcceptanceErrorMessageEnumValues;
  static InvalidAcceptanceErrorMessageEnum valueOf(String name) =>
      _$invalidAcceptanceErrorMessageEnumValueOf(name);
}

class InvalidAcceptanceErrorHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 404)
  static const InvalidAcceptanceErrorHttpStatusCodeEnum number404 =
      _$invalidAcceptanceErrorHttpStatusCodeEnum_number404;

  static Serializer<InvalidAcceptanceErrorHttpStatusCodeEnum> get serializer =>
      _$invalidAcceptanceErrorHttpStatusCodeEnumSerializer;

  const InvalidAcceptanceErrorHttpStatusCodeEnum._(String name) : super(name);

  static BuiltSet<InvalidAcceptanceErrorHttpStatusCodeEnum> get values =>
      _$invalidAcceptanceErrorHttpStatusCodeEnumValues;
  static InvalidAcceptanceErrorHttpStatusCodeEnum valueOf(String name) =>
      _$invalidAcceptanceErrorHttpStatusCodeEnumValueOf(name);
}

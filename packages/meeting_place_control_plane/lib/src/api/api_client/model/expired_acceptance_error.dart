//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import '../model/not_found_error_details_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'expired_acceptance_error.g.dart';

/// The offer is no longer valid due to max usage or validity  date expiration.
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class ExpiredAcceptanceError
    implements Built<ExpiredAcceptanceError, ExpiredAcceptanceErrorBuilder> {
  @BuiltValueField(wireName: r'name')
  ExpiredAcceptanceErrorNameEnum get name;
  // enum nameEnum {  ExpiredAcceptanceError,  };

  @BuiltValueField(wireName: r'message')
  ExpiredAcceptanceErrorMessageEnum get message;
  // enum messageEnum {  The acceptance has expired,  };

  @BuiltValueField(wireName: r'httpStatusCode')
  ExpiredAcceptanceErrorHttpStatusCodeEnum get httpStatusCode;
  // enum httpStatusCodeEnum {  404,  };

  @BuiltValueField(wireName: r'traceId')
  String get traceId;

  @BuiltValueField(wireName: r'details')
  BuiltList<NotFoundErrorDetailsInner>? get details;

  ExpiredAcceptanceError._();

  factory ExpiredAcceptanceError([
    void updates(ExpiredAcceptanceErrorBuilder b),
  ]) = _$ExpiredAcceptanceError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ExpiredAcceptanceErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ExpiredAcceptanceError> get serializer =>
      _$ExpiredAcceptanceErrorSerializer();
}

class _$ExpiredAcceptanceErrorSerializer
    implements PrimitiveSerializer<ExpiredAcceptanceError> {
  @override
  final Iterable<Type> types = const [
    ExpiredAcceptanceError,
    _$ExpiredAcceptanceError,
  ];

  @override
  final String wireName = r'ExpiredAcceptanceError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ExpiredAcceptanceError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(ExpiredAcceptanceErrorNameEnum),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(ExpiredAcceptanceErrorMessageEnum),
    );
    yield r'httpStatusCode';
    yield serializers.serialize(
      object.httpStatusCode,
      specifiedType: const FullType(ExpiredAcceptanceErrorHttpStatusCodeEnum),
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
    ExpiredAcceptanceError object, {
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
    required ExpiredAcceptanceErrorBuilder result,
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
                      ExpiredAcceptanceErrorNameEnum,
                    ),
                  )
                  as ExpiredAcceptanceErrorNameEnum;
          result.name = valueDes;
          break;
        case r'message':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      ExpiredAcceptanceErrorMessageEnum,
                    ),
                  )
                  as ExpiredAcceptanceErrorMessageEnum;
          result.message = valueDes;
          break;
        case r'httpStatusCode':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      ExpiredAcceptanceErrorHttpStatusCodeEnum,
                    ),
                  )
                  as ExpiredAcceptanceErrorHttpStatusCodeEnum;
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
  ExpiredAcceptanceError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ExpiredAcceptanceErrorBuilder();
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

class ExpiredAcceptanceErrorNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'ExpiredAcceptanceError')
  static const ExpiredAcceptanceErrorNameEnum expiredAcceptanceError =
      _$expiredAcceptanceErrorNameEnum_expiredAcceptanceError;

  static Serializer<ExpiredAcceptanceErrorNameEnum> get serializer =>
      _$expiredAcceptanceErrorNameEnumSerializer;

  const ExpiredAcceptanceErrorNameEnum._(String name) : super(name);

  static BuiltSet<ExpiredAcceptanceErrorNameEnum> get values =>
      _$expiredAcceptanceErrorNameEnumValues;
  static ExpiredAcceptanceErrorNameEnum valueOf(String name) =>
      _$expiredAcceptanceErrorNameEnumValueOf(name);
}

class ExpiredAcceptanceErrorMessageEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'The acceptance has expired')
  static const ExpiredAcceptanceErrorMessageEnum theAcceptanceHasExpired =
      _$expiredAcceptanceErrorMessageEnum_theAcceptanceHasExpired;

  static Serializer<ExpiredAcceptanceErrorMessageEnum> get serializer =>
      _$expiredAcceptanceErrorMessageEnumSerializer;

  const ExpiredAcceptanceErrorMessageEnum._(String name) : super(name);

  static BuiltSet<ExpiredAcceptanceErrorMessageEnum> get values =>
      _$expiredAcceptanceErrorMessageEnumValues;
  static ExpiredAcceptanceErrorMessageEnum valueOf(String name) =>
      _$expiredAcceptanceErrorMessageEnumValueOf(name);
}

class ExpiredAcceptanceErrorHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 404)
  static const ExpiredAcceptanceErrorHttpStatusCodeEnum number404 =
      _$expiredAcceptanceErrorHttpStatusCodeEnum_number404;

  static Serializer<ExpiredAcceptanceErrorHttpStatusCodeEnum> get serializer =>
      _$expiredAcceptanceErrorHttpStatusCodeEnumSerializer;

  const ExpiredAcceptanceErrorHttpStatusCodeEnum._(String name) : super(name);

  static BuiltSet<ExpiredAcceptanceErrorHttpStatusCodeEnum> get values =>
      _$expiredAcceptanceErrorHttpStatusCodeEnumValues;
  static ExpiredAcceptanceErrorHttpStatusCodeEnum valueOf(String name) =>
      _$expiredAcceptanceErrorHttpStatusCodeEnumValueOf(name);
}

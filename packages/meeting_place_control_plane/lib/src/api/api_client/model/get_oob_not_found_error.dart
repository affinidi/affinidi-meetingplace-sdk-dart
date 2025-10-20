//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import '../model/not_found_error_details_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'get_oob_not_found_error.g.dart';

/// The oob could not be found
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class GetOobNotFoundError
    implements Built<GetOobNotFoundError, GetOobNotFoundErrorBuilder> {
  @BuiltValueField(wireName: r'name')
  GetOobNotFoundErrorNameEnum get name;
  // enum nameEnum {  GetOobNotFoundError,  };

  @BuiltValueField(wireName: r'message')
  GetOobNotFoundErrorMessageEnum get message;
  // enum messageEnum {  The oob could not be found,  };

  @BuiltValueField(wireName: r'httpStatusCode')
  GetOobNotFoundErrorHttpStatusCodeEnum get httpStatusCode;
  // enum httpStatusCodeEnum {  404,  };

  @BuiltValueField(wireName: r'traceId')
  String get traceId;

  @BuiltValueField(wireName: r'details')
  BuiltList<NotFoundErrorDetailsInner>? get details;

  GetOobNotFoundError._();

  factory GetOobNotFoundError([void updates(GetOobNotFoundErrorBuilder b)]) =
      _$GetOobNotFoundError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GetOobNotFoundErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GetOobNotFoundError> get serializer =>
      _$GetOobNotFoundErrorSerializer();
}

class _$GetOobNotFoundErrorSerializer
    implements PrimitiveSerializer<GetOobNotFoundError> {
  @override
  final Iterable<Type> types = const [
    GetOobNotFoundError,
    _$GetOobNotFoundError,
  ];

  @override
  final String wireName = r'GetOobNotFoundError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GetOobNotFoundError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(GetOobNotFoundErrorNameEnum),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(GetOobNotFoundErrorMessageEnum),
    );
    yield r'httpStatusCode';
    yield serializers.serialize(
      object.httpStatusCode,
      specifiedType: const FullType(GetOobNotFoundErrorHttpStatusCodeEnum),
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
    GetOobNotFoundError object, {
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
    required GetOobNotFoundErrorBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GetOobNotFoundErrorNameEnum),
          ) as GetOobNotFoundErrorNameEnum;
          result.name = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
              GetOobNotFoundErrorMessageEnum,
            ),
          ) as GetOobNotFoundErrorMessageEnum;
          result.message = valueDes;
          break;
        case r'httpStatusCode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(
              GetOobNotFoundErrorHttpStatusCodeEnum,
            ),
          ) as GetOobNotFoundErrorHttpStatusCodeEnum;
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
  GetOobNotFoundError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GetOobNotFoundErrorBuilder();
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

class GetOobNotFoundErrorNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'GetOobNotFoundError')
  static const GetOobNotFoundErrorNameEnum getOobNotFoundError =
      _$getOobNotFoundErrorNameEnum_getOobNotFoundError;

  static Serializer<GetOobNotFoundErrorNameEnum> get serializer =>
      _$getOobNotFoundErrorNameEnumSerializer;

  const GetOobNotFoundErrorNameEnum._(String name) : super(name);

  static BuiltSet<GetOobNotFoundErrorNameEnum> get values =>
      _$getOobNotFoundErrorNameEnumValues;
  static GetOobNotFoundErrorNameEnum valueOf(String name) =>
      _$getOobNotFoundErrorNameEnumValueOf(name);
}

class GetOobNotFoundErrorMessageEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'The oob could not be found')
  static const GetOobNotFoundErrorMessageEnum theOobCouldNotBeFound =
      _$getOobNotFoundErrorMessageEnum_theOobCouldNotBeFound;

  static Serializer<GetOobNotFoundErrorMessageEnum> get serializer =>
      _$getOobNotFoundErrorMessageEnumSerializer;

  const GetOobNotFoundErrorMessageEnum._(String name) : super(name);

  static BuiltSet<GetOobNotFoundErrorMessageEnum> get values =>
      _$getOobNotFoundErrorMessageEnumValues;
  static GetOobNotFoundErrorMessageEnum valueOf(String name) =>
      _$getOobNotFoundErrorMessageEnumValueOf(name);
}

class GetOobNotFoundErrorHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 404)
  static const GetOobNotFoundErrorHttpStatusCodeEnum number404 =
      _$getOobNotFoundErrorHttpStatusCodeEnum_number404;

  static Serializer<GetOobNotFoundErrorHttpStatusCodeEnum> get serializer =>
      _$getOobNotFoundErrorHttpStatusCodeEnumSerializer;

  const GetOobNotFoundErrorHttpStatusCodeEnum._(String name) : super(name);

  static BuiltSet<GetOobNotFoundErrorHttpStatusCodeEnum> get values =>
      _$getOobNotFoundErrorHttpStatusCodeEnumValues;
  static GetOobNotFoundErrorHttpStatusCodeEnum valueOf(String name) =>
      _$getOobNotFoundErrorHttpStatusCodeEnumValueOf(name);
}

//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import '../model/not_found_error_details_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'offer_phrase_in_use_error.g.dart';

/// The offer phrase is already in use by another offer
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class OfferPhraseInUseError
    implements Built<OfferPhraseInUseError, OfferPhraseInUseErrorBuilder> {
  @BuiltValueField(wireName: r'name')
  OfferPhraseInUseErrorNameEnum get name;
  // enum nameEnum {  OfferPhraseInUseError,  };

  @BuiltValueField(wireName: r'message')
  OfferPhraseInUseErrorMessageEnum get message;
  // enum messageEnum {  The offer phrase is already in use by another offer,  };

  @BuiltValueField(wireName: r'httpStatusCode')
  OfferPhraseInUseErrorHttpStatusCodeEnum get httpStatusCode;
  // enum httpStatusCodeEnum {  409,  };

  @BuiltValueField(wireName: r'traceId')
  String get traceId;

  @BuiltValueField(wireName: r'details')
  BuiltList<NotFoundErrorDetailsInner>? get details;

  OfferPhraseInUseError._();

  factory OfferPhraseInUseError([
    void updates(OfferPhraseInUseErrorBuilder b),
  ]) = _$OfferPhraseInUseError;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OfferPhraseInUseErrorBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OfferPhraseInUseError> get serializer =>
      _$OfferPhraseInUseErrorSerializer();
}

class _$OfferPhraseInUseErrorSerializer
    implements PrimitiveSerializer<OfferPhraseInUseError> {
  @override
  final Iterable<Type> types = const [
    OfferPhraseInUseError,
    _$OfferPhraseInUseError,
  ];

  @override
  final String wireName = r'OfferPhraseInUseError';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OfferPhraseInUseError object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(OfferPhraseInUseErrorNameEnum),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(OfferPhraseInUseErrorMessageEnum),
    );
    yield r'httpStatusCode';
    yield serializers.serialize(
      object.httpStatusCode,
      specifiedType: const FullType(OfferPhraseInUseErrorHttpStatusCodeEnum),
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
    OfferPhraseInUseError object, {
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
    required OfferPhraseInUseErrorBuilder result,
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
                      OfferPhraseInUseErrorNameEnum,
                    ),
                  )
                  as OfferPhraseInUseErrorNameEnum;
          result.name = valueDes;
          break;
        case r'message':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      OfferPhraseInUseErrorMessageEnum,
                    ),
                  )
                  as OfferPhraseInUseErrorMessageEnum;
          result.message = valueDes;
          break;
        case r'httpStatusCode':
          final valueDes =
              serializers.deserialize(
                    value,
                    specifiedType: const FullType(
                      OfferPhraseInUseErrorHttpStatusCodeEnum,
                    ),
                  )
                  as OfferPhraseInUseErrorHttpStatusCodeEnum;
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
  OfferPhraseInUseError deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OfferPhraseInUseErrorBuilder();
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

class OfferPhraseInUseErrorNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'OfferPhraseInUseError')
  static const OfferPhraseInUseErrorNameEnum offerPhraseInUseError =
      _$offerPhraseInUseErrorNameEnum_offerPhraseInUseError;

  static Serializer<OfferPhraseInUseErrorNameEnum> get serializer =>
      _$offerPhraseInUseErrorNameEnumSerializer;

  const OfferPhraseInUseErrorNameEnum._(String name) : super(name);

  static BuiltSet<OfferPhraseInUseErrorNameEnum> get values =>
      _$offerPhraseInUseErrorNameEnumValues;
  static OfferPhraseInUseErrorNameEnum valueOf(String name) =>
      _$offerPhraseInUseErrorNameEnumValueOf(name);
}

class OfferPhraseInUseErrorMessageEnum extends EnumClass {
  @BuiltValueEnumConst(
    wireName: r'The offer phrase is already in use by another offer',
  )
  static const OfferPhraseInUseErrorMessageEnum
  theOfferPhraseIsAlreadyInUseByAnotherOffer =
      _$offerPhraseInUseErrorMessageEnum_theOfferPhraseIsAlreadyInUseByAnotherOffer;

  static Serializer<OfferPhraseInUseErrorMessageEnum> get serializer =>
      _$offerPhraseInUseErrorMessageEnumSerializer;

  const OfferPhraseInUseErrorMessageEnum._(String name) : super(name);

  static BuiltSet<OfferPhraseInUseErrorMessageEnum> get values =>
      _$offerPhraseInUseErrorMessageEnumValues;
  static OfferPhraseInUseErrorMessageEnum valueOf(String name) =>
      _$offerPhraseInUseErrorMessageEnumValueOf(name);
}

class OfferPhraseInUseErrorHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 409)
  static const OfferPhraseInUseErrorHttpStatusCodeEnum number409 =
      _$offerPhraseInUseErrorHttpStatusCodeEnum_number409;

  static Serializer<OfferPhraseInUseErrorHttpStatusCodeEnum> get serializer =>
      _$offerPhraseInUseErrorHttpStatusCodeEnumSerializer;

  const OfferPhraseInUseErrorHttpStatusCodeEnum._(String name) : super(name);

  static BuiltSet<OfferPhraseInUseErrorHttpStatusCodeEnum> get values =>
      _$offerPhraseInUseErrorHttpStatusCodeEnumValues;
  static OfferPhraseInUseErrorHttpStatusCodeEnum valueOf(String name) =>
      _$offerPhraseInUseErrorHttpStatusCodeEnumValueOf(name);
}

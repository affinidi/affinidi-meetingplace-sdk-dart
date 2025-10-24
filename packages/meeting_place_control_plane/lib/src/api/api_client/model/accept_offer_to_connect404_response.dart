//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import '../model/invalid_acceptance_error.dart';
import 'package:built_collection/built_collection.dart';
import '../model/not_found_error_details_inner.dart';
import '../model/offer_limit_exceeded_error.dart';
import '../model/invalid_offer_error.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'accept_offer_to_connect404_response.g.dart';

/// AcceptOfferToConnect404Response
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class AcceptOfferToConnect404Response
    implements
        Built<AcceptOfferToConnect404Response,
            AcceptOfferToConnect404ResponseBuilder> {
  /// One Of [InvalidAcceptanceError], [InvalidOfferError], [OfferLimitExceededError]
  OneOf get oneOf;

  AcceptOfferToConnect404Response._();

  factory AcceptOfferToConnect404Response([
    void updates(AcceptOfferToConnect404ResponseBuilder b),
  ]) = _$AcceptOfferToConnect404Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AcceptOfferToConnect404ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AcceptOfferToConnect404Response> get serializer =>
      _$AcceptOfferToConnect404ResponseSerializer();
}

class _$AcceptOfferToConnect404ResponseSerializer
    implements PrimitiveSerializer<AcceptOfferToConnect404Response> {
  @override
  final Iterable<Type> types = const [
    AcceptOfferToConnect404Response,
    _$AcceptOfferToConnect404Response,
  ];

  @override
  final String wireName = r'AcceptOfferToConnect404Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AcceptOfferToConnect404Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    AcceptOfferToConnect404Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(
      oneOf.value,
      specifiedType: FullType(oneOf.valueType),
    )!;
  }

  @override
  AcceptOfferToConnect404Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AcceptOfferToConnect404ResponseBuilder();
    Object? oneOfDataSrc;
    final targetType = const FullType(OneOf, [
      FullType(InvalidOfferError),
      FullType(OfferLimitExceededError),
      FullType(InvalidAcceptanceError),
    ]);
    oneOfDataSrc = serialized;
    result.oneOf = serializers.deserialize(oneOfDataSrc,
        specifiedType: targetType) as OneOf;
    return result.build();
  }
}

class AcceptOfferToConnect404ResponseNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'InvalidAcceptanceError')
  static const AcceptOfferToConnect404ResponseNameEnum invalidAcceptanceError =
      _$acceptOfferToConnect404ResponseNameEnum_invalidAcceptanceError;

  static Serializer<AcceptOfferToConnect404ResponseNameEnum> get serializer =>
      _$acceptOfferToConnect404ResponseNameEnumSerializer;

  const AcceptOfferToConnect404ResponseNameEnum._(String name) : super(name);

  static BuiltSet<AcceptOfferToConnect404ResponseNameEnum> get values =>
      _$acceptOfferToConnect404ResponseNameEnumValues;
  static AcceptOfferToConnect404ResponseNameEnum valueOf(String name) =>
      _$acceptOfferToConnect404ResponseNameEnumValueOf(name);
}

class AcceptOfferToConnect404ResponseMessageEnum extends EnumClass {
  @BuiltValueEnumConst(
    wireName: r'No valid acceptance found that matches the details provided.',
  )
  static const AcceptOfferToConnect404ResponseMessageEnum
      noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod =
      _$acceptOfferToConnect404ResponseMessageEnum_noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod;

  static Serializer<AcceptOfferToConnect404ResponseMessageEnum>
      get serializer => _$acceptOfferToConnect404ResponseMessageEnumSerializer;

  const AcceptOfferToConnect404ResponseMessageEnum._(String name) : super(name);

  static BuiltSet<AcceptOfferToConnect404ResponseMessageEnum> get values =>
      _$acceptOfferToConnect404ResponseMessageEnumValues;
  static AcceptOfferToConnect404ResponseMessageEnum valueOf(String name) =>
      _$acceptOfferToConnect404ResponseMessageEnumValueOf(name);
}

class AcceptOfferToConnect404ResponseHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 404)
  static const AcceptOfferToConnect404ResponseHttpStatusCodeEnum number404 =
      _$acceptOfferToConnect404ResponseHttpStatusCodeEnum_number404;

  static Serializer<AcceptOfferToConnect404ResponseHttpStatusCodeEnum>
      get serializer =>
          _$acceptOfferToConnect404ResponseHttpStatusCodeEnumSerializer;

  const AcceptOfferToConnect404ResponseHttpStatusCodeEnum._(String name)
      : super(name);

  static BuiltSet<AcceptOfferToConnect404ResponseHttpStatusCodeEnum>
      get values => _$acceptOfferToConnect404ResponseHttpStatusCodeEnumValues;
  static AcceptOfferToConnect404ResponseHttpStatusCodeEnum valueOf(
    String name,
  ) =>
      _$acceptOfferToConnect404ResponseHttpStatusCodeEnumValueOf(name);
}

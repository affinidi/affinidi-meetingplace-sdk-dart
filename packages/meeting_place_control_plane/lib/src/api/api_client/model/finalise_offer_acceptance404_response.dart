//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import '../model/invalid_acceptance_error.dart';
import '../model/expired_acceptance_error.dart';
import 'package:built_collection/built_collection.dart';
import '../model/not_found_error_details_inner.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'finalise_offer_acceptance404_response.g.dart';

/// FinaliseOfferAcceptance404Response
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class FinaliseOfferAcceptance404Response
    implements
        Built<FinaliseOfferAcceptance404Response,
            FinaliseOfferAcceptance404ResponseBuilder> {
  /// One Of [ExpiredAcceptanceError], [InvalidAcceptanceError]
  OneOf get oneOf;

  FinaliseOfferAcceptance404Response._();

  factory FinaliseOfferAcceptance404Response([
    void updates(FinaliseOfferAcceptance404ResponseBuilder b),
  ]) = _$FinaliseOfferAcceptance404Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FinaliseOfferAcceptance404ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FinaliseOfferAcceptance404Response> get serializer =>
      _$FinaliseOfferAcceptance404ResponseSerializer();
}

class _$FinaliseOfferAcceptance404ResponseSerializer
    implements PrimitiveSerializer<FinaliseOfferAcceptance404Response> {
  @override
  final Iterable<Type> types = const [
    FinaliseOfferAcceptance404Response,
    _$FinaliseOfferAcceptance404Response,
  ];

  @override
  final String wireName = r'FinaliseOfferAcceptance404Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FinaliseOfferAcceptance404Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    FinaliseOfferAcceptance404Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(
      oneOf.value,
      specifiedType: FullType(oneOf.valueType),
    )!;
  }

  @override
  FinaliseOfferAcceptance404Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FinaliseOfferAcceptance404ResponseBuilder();
    Object? oneOfDataSrc;
    final targetType = const FullType(OneOf, [
      FullType(InvalidAcceptanceError),
      FullType(ExpiredAcceptanceError),
    ]);
    oneOfDataSrc = serialized;
    result.oneOf = serializers.deserialize(oneOfDataSrc,
        specifiedType: targetType) as OneOf;
    return result.build();
  }
}

class FinaliseOfferAcceptance404ResponseNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'ExpiredAcceptanceError')
  static const FinaliseOfferAcceptance404ResponseNameEnum
      expiredAcceptanceError =
      _$finaliseOfferAcceptance404ResponseNameEnum_expiredAcceptanceError;

  static Serializer<FinaliseOfferAcceptance404ResponseNameEnum>
      get serializer => _$finaliseOfferAcceptance404ResponseNameEnumSerializer;

  const FinaliseOfferAcceptance404ResponseNameEnum._(String name) : super(name);

  static BuiltSet<FinaliseOfferAcceptance404ResponseNameEnum> get values =>
      _$finaliseOfferAcceptance404ResponseNameEnumValues;
  static FinaliseOfferAcceptance404ResponseNameEnum valueOf(String name) =>
      _$finaliseOfferAcceptance404ResponseNameEnumValueOf(name);
}

class FinaliseOfferAcceptance404ResponseMessageEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'The acceptance has expired')
  static const FinaliseOfferAcceptance404ResponseMessageEnum
      theAcceptanceHasExpired =
      _$finaliseOfferAcceptance404ResponseMessageEnum_theAcceptanceHasExpired;

  static Serializer<FinaliseOfferAcceptance404ResponseMessageEnum>
      get serializer =>
          _$finaliseOfferAcceptance404ResponseMessageEnumSerializer;

  const FinaliseOfferAcceptance404ResponseMessageEnum._(String name)
      : super(name);

  static BuiltSet<FinaliseOfferAcceptance404ResponseMessageEnum> get values =>
      _$finaliseOfferAcceptance404ResponseMessageEnumValues;
  static FinaliseOfferAcceptance404ResponseMessageEnum valueOf(String name) =>
      _$finaliseOfferAcceptance404ResponseMessageEnumValueOf(name);
}

class FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 404)
  static const FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum number404 =
      _$finaliseOfferAcceptance404ResponseHttpStatusCodeEnum_number404;

  static Serializer<FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum>
      get serializer =>
          _$finaliseOfferAcceptance404ResponseHttpStatusCodeEnumSerializer;

  const FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum._(String name)
      : super(name);

  static BuiltSet<FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum>
      get values =>
          _$finaliseOfferAcceptance404ResponseHttpStatusCodeEnumValues;
  static FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum valueOf(
    String name,
  ) =>
      _$finaliseOfferAcceptance404ResponseHttpStatusCodeEnumValueOf(name);
}

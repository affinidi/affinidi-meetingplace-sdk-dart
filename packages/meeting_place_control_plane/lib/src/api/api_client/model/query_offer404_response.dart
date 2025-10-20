//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import '../model/invalid_acceptance_error.dart';
import '../model/expired_acceptance_error.dart';
import 'package:built_collection/built_collection.dart';
import '../model/not_found_error_details_inner.dart';
import '../model/offer_limit_exceeded_error.dart';
import '../model/invalid_offer_error.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'query_offer404_response.g.dart';

/// QueryOffer404Response
///
/// Properties:
/// * [name]
/// * [message]
/// * [httpStatusCode]
/// * [traceId]
/// * [details]
@BuiltValue()
abstract class QueryOffer404Response
    implements Built<QueryOffer404Response, QueryOffer404ResponseBuilder> {
  /// One Of [ExpiredAcceptanceError], [InvalidAcceptanceError], [InvalidOfferError], [OfferLimitExceededError]
  OneOf get oneOf;

  QueryOffer404Response._();

  factory QueryOffer404Response([
    void updates(QueryOffer404ResponseBuilder b),
  ]) = _$QueryOffer404Response;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(QueryOffer404ResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<QueryOffer404Response> get serializer =>
      _$QueryOffer404ResponseSerializer();
}

class _$QueryOffer404ResponseSerializer
    implements PrimitiveSerializer<QueryOffer404Response> {
  @override
  final Iterable<Type> types = const [
    QueryOffer404Response,
    _$QueryOffer404Response,
  ];

  @override
  final String wireName = r'QueryOffer404Response';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    QueryOffer404Response object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {}

  @override
  Object serialize(
    Serializers serializers,
    QueryOffer404Response object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(
      oneOf.value,
      specifiedType: FullType(oneOf.valueType),
    )!;
  }

  @override
  QueryOffer404Response deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = QueryOffer404ResponseBuilder();
    Object? oneOfDataSrc;
    final targetType = const FullType(OneOf, [
      FullType(InvalidOfferError),
      FullType(OfferLimitExceededError),
      FullType(InvalidAcceptanceError),
      FullType(ExpiredAcceptanceError),
    ]);
    oneOfDataSrc = serialized;
    result.oneOf = serializers.deserialize(oneOfDataSrc,
        specifiedType: targetType) as OneOf;
    return result.build();
  }
}

class QueryOffer404ResponseNameEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'ExpiredAcceptanceError')
  static const QueryOffer404ResponseNameEnum expiredAcceptanceError =
      _$queryOffer404ResponseNameEnum_expiredAcceptanceError;

  static Serializer<QueryOffer404ResponseNameEnum> get serializer =>
      _$queryOffer404ResponseNameEnumSerializer;

  const QueryOffer404ResponseNameEnum._(String name) : super(name);

  static BuiltSet<QueryOffer404ResponseNameEnum> get values =>
      _$queryOffer404ResponseNameEnumValues;
  static QueryOffer404ResponseNameEnum valueOf(String name) =>
      _$queryOffer404ResponseNameEnumValueOf(name);
}

class QueryOffer404ResponseMessageEnum extends EnumClass {
  @BuiltValueEnumConst(wireName: r'The acceptance has expired')
  static const QueryOffer404ResponseMessageEnum theAcceptanceHasExpired =
      _$queryOffer404ResponseMessageEnum_theAcceptanceHasExpired;

  static Serializer<QueryOffer404ResponseMessageEnum> get serializer =>
      _$queryOffer404ResponseMessageEnumSerializer;

  const QueryOffer404ResponseMessageEnum._(String name) : super(name);

  static BuiltSet<QueryOffer404ResponseMessageEnum> get values =>
      _$queryOffer404ResponseMessageEnumValues;
  static QueryOffer404ResponseMessageEnum valueOf(String name) =>
      _$queryOffer404ResponseMessageEnumValueOf(name);
}

class QueryOffer404ResponseHttpStatusCodeEnum extends EnumClass {
  @BuiltValueEnumConst(wireNumber: 404)
  static const QueryOffer404ResponseHttpStatusCodeEnum number404 =
      _$queryOffer404ResponseHttpStatusCodeEnum_number404;

  static Serializer<QueryOffer404ResponseHttpStatusCodeEnum> get serializer =>
      _$queryOffer404ResponseHttpStatusCodeEnumSerializer;

  const QueryOffer404ResponseHttpStatusCodeEnum._(String name) : super(name);

  static BuiltSet<QueryOffer404ResponseHttpStatusCodeEnum> get values =>
      _$queryOffer404ResponseHttpStatusCodeEnumValues;
  static QueryOffer404ResponseHttpStatusCodeEnum valueOf(String name) =>
      _$queryOffer404ResponseHttpStatusCodeEnumValueOf(name);
}

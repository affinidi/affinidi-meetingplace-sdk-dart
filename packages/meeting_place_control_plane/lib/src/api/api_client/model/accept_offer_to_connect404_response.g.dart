// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_offer_to_connect404_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AcceptOfferToConnect404ResponseNameEnum
    _$acceptOfferToConnect404ResponseNameEnum_invalidAcceptanceError =
    const AcceptOfferToConnect404ResponseNameEnum._('invalidAcceptanceError');

AcceptOfferToConnect404ResponseNameEnum
    _$acceptOfferToConnect404ResponseNameEnumValueOf(String name) {
  switch (name) {
    case 'invalidAcceptanceError':
      return _$acceptOfferToConnect404ResponseNameEnum_invalidAcceptanceError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AcceptOfferToConnect404ResponseNameEnum>
    _$acceptOfferToConnect404ResponseNameEnumValues = BuiltSet<
        AcceptOfferToConnect404ResponseNameEnum>(const <AcceptOfferToConnect404ResponseNameEnum>[
  _$acceptOfferToConnect404ResponseNameEnum_invalidAcceptanceError,
]);

const AcceptOfferToConnect404ResponseMessageEnum
    _$acceptOfferToConnect404ResponseMessageEnum_noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod =
    const AcceptOfferToConnect404ResponseMessageEnum._(
        'noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod');

AcceptOfferToConnect404ResponseMessageEnum
    _$acceptOfferToConnect404ResponseMessageEnumValueOf(String name) {
  switch (name) {
    case 'noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod':
      return _$acceptOfferToConnect404ResponseMessageEnum_noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AcceptOfferToConnect404ResponseMessageEnum>
    _$acceptOfferToConnect404ResponseMessageEnumValues = BuiltSet<
        AcceptOfferToConnect404ResponseMessageEnum>(const <AcceptOfferToConnect404ResponseMessageEnum>[
  _$acceptOfferToConnect404ResponseMessageEnum_noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod,
]);

const AcceptOfferToConnect404ResponseHttpStatusCodeEnum
    _$acceptOfferToConnect404ResponseHttpStatusCodeEnum_number404 =
    const AcceptOfferToConnect404ResponseHttpStatusCodeEnum._('number404');

AcceptOfferToConnect404ResponseHttpStatusCodeEnum
    _$acceptOfferToConnect404ResponseHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'number404':
      return _$acceptOfferToConnect404ResponseHttpStatusCodeEnum_number404;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AcceptOfferToConnect404ResponseHttpStatusCodeEnum>
    _$acceptOfferToConnect404ResponseHttpStatusCodeEnumValues = BuiltSet<
        AcceptOfferToConnect404ResponseHttpStatusCodeEnum>(const <AcceptOfferToConnect404ResponseHttpStatusCodeEnum>[
  _$acceptOfferToConnect404ResponseHttpStatusCodeEnum_number404,
]);

Serializer<AcceptOfferToConnect404ResponseNameEnum>
    _$acceptOfferToConnect404ResponseNameEnumSerializer =
    _$AcceptOfferToConnect404ResponseNameEnumSerializer();
Serializer<AcceptOfferToConnect404ResponseMessageEnum>
    _$acceptOfferToConnect404ResponseMessageEnumSerializer =
    _$AcceptOfferToConnect404ResponseMessageEnumSerializer();
Serializer<AcceptOfferToConnect404ResponseHttpStatusCodeEnum>
    _$acceptOfferToConnect404ResponseHttpStatusCodeEnumSerializer =
    _$AcceptOfferToConnect404ResponseHttpStatusCodeEnumSerializer();

class _$AcceptOfferToConnect404ResponseNameEnumSerializer
    implements PrimitiveSerializer<AcceptOfferToConnect404ResponseNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'invalidAcceptanceError': 'InvalidAcceptanceError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'InvalidAcceptanceError': 'invalidAcceptanceError',
  };

  @override
  final Iterable<Type> types = const <Type>[
    AcceptOfferToConnect404ResponseNameEnum
  ];
  @override
  final String wireName = 'AcceptOfferToConnect404ResponseNameEnum';

  @override
  Object serialize(Serializers serializers,
          AcceptOfferToConnect404ResponseNameEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AcceptOfferToConnect404ResponseNameEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AcceptOfferToConnect404ResponseNameEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$AcceptOfferToConnect404ResponseMessageEnumSerializer
    implements PrimitiveSerializer<AcceptOfferToConnect404ResponseMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod':
        'No valid acceptance found that matches the details provided.',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'No valid acceptance found that matches the details provided.':
        'noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod',
  };

  @override
  final Iterable<Type> types = const <Type>[
    AcceptOfferToConnect404ResponseMessageEnum
  ];
  @override
  final String wireName = 'AcceptOfferToConnect404ResponseMessageEnum';

  @override
  Object serialize(Serializers serializers,
          AcceptOfferToConnect404ResponseMessageEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AcceptOfferToConnect404ResponseMessageEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AcceptOfferToConnect404ResponseMessageEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$AcceptOfferToConnect404ResponseHttpStatusCodeEnumSerializer
    implements
        PrimitiveSerializer<AcceptOfferToConnect404ResponseHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number404': 404,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    404: 'number404',
  };

  @override
  final Iterable<Type> types = const <Type>[
    AcceptOfferToConnect404ResponseHttpStatusCodeEnum
  ];
  @override
  final String wireName = 'AcceptOfferToConnect404ResponseHttpStatusCodeEnum';

  @override
  Object serialize(Serializers serializers,
          AcceptOfferToConnect404ResponseHttpStatusCodeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  AcceptOfferToConnect404ResponseHttpStatusCodeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      AcceptOfferToConnect404ResponseHttpStatusCodeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$AcceptOfferToConnect404Response
    extends AcceptOfferToConnect404Response {
  @override
  final OneOf oneOf;

  factory _$AcceptOfferToConnect404Response(
          [void Function(AcceptOfferToConnect404ResponseBuilder)? updates]) =>
      (AcceptOfferToConnect404ResponseBuilder()..update(updates))._build();

  _$AcceptOfferToConnect404Response._({required this.oneOf}) : super._();
  @override
  AcceptOfferToConnect404Response rebuild(
          void Function(AcceptOfferToConnect404ResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AcceptOfferToConnect404ResponseBuilder toBuilder() =>
      AcceptOfferToConnect404ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcceptOfferToConnect404Response && oneOf == other.oneOf;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, oneOf.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AcceptOfferToConnect404Response')
          ..add('oneOf', oneOf))
        .toString();
  }
}

class AcceptOfferToConnect404ResponseBuilder
    implements
        Builder<AcceptOfferToConnect404Response,
            AcceptOfferToConnect404ResponseBuilder> {
  _$AcceptOfferToConnect404Response? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  AcceptOfferToConnect404ResponseBuilder() {
    AcceptOfferToConnect404Response._defaults(this);
  }

  AcceptOfferToConnect404ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AcceptOfferToConnect404Response other) {
    _$v = other as _$AcceptOfferToConnect404Response;
  }

  @override
  void update(void Function(AcceptOfferToConnect404ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcceptOfferToConnect404Response build() => _build();

  _$AcceptOfferToConnect404Response _build() {
    final _$result = _$v ??
        _$AcceptOfferToConnect404Response._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
              oneOf, r'AcceptOfferToConnect404Response', 'oneOf'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

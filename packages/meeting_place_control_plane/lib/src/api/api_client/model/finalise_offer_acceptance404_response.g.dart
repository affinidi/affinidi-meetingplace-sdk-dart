// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finalise_offer_acceptance404_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const FinaliseOfferAcceptance404ResponseNameEnum
    _$finaliseOfferAcceptance404ResponseNameEnum_expiredAcceptanceError =
    const FinaliseOfferAcceptance404ResponseNameEnum._(
        'expiredAcceptanceError');

FinaliseOfferAcceptance404ResponseNameEnum
    _$finaliseOfferAcceptance404ResponseNameEnumValueOf(String name) {
  switch (name) {
    case 'expiredAcceptanceError':
      return _$finaliseOfferAcceptance404ResponseNameEnum_expiredAcceptanceError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<FinaliseOfferAcceptance404ResponseNameEnum>
    _$finaliseOfferAcceptance404ResponseNameEnumValues = BuiltSet<
        FinaliseOfferAcceptance404ResponseNameEnum>(const <FinaliseOfferAcceptance404ResponseNameEnum>[
  _$finaliseOfferAcceptance404ResponseNameEnum_expiredAcceptanceError,
]);

const FinaliseOfferAcceptance404ResponseMessageEnum
    _$finaliseOfferAcceptance404ResponseMessageEnum_theAcceptanceHasExpired =
    const FinaliseOfferAcceptance404ResponseMessageEnum._(
        'theAcceptanceHasExpired');

FinaliseOfferAcceptance404ResponseMessageEnum
    _$finaliseOfferAcceptance404ResponseMessageEnumValueOf(String name) {
  switch (name) {
    case 'theAcceptanceHasExpired':
      return _$finaliseOfferAcceptance404ResponseMessageEnum_theAcceptanceHasExpired;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<FinaliseOfferAcceptance404ResponseMessageEnum>
    _$finaliseOfferAcceptance404ResponseMessageEnumValues = BuiltSet<
        FinaliseOfferAcceptance404ResponseMessageEnum>(const <FinaliseOfferAcceptance404ResponseMessageEnum>[
  _$finaliseOfferAcceptance404ResponseMessageEnum_theAcceptanceHasExpired,
]);

const FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum
    _$finaliseOfferAcceptance404ResponseHttpStatusCodeEnum_number404 =
    const FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum._('number404');

FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum
    _$finaliseOfferAcceptance404ResponseHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'number404':
      return _$finaliseOfferAcceptance404ResponseHttpStatusCodeEnum_number404;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum>
    _$finaliseOfferAcceptance404ResponseHttpStatusCodeEnumValues = BuiltSet<
        FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum>(const <FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum>[
  _$finaliseOfferAcceptance404ResponseHttpStatusCodeEnum_number404,
]);

Serializer<FinaliseOfferAcceptance404ResponseNameEnum>
    _$finaliseOfferAcceptance404ResponseNameEnumSerializer =
    _$FinaliseOfferAcceptance404ResponseNameEnumSerializer();
Serializer<FinaliseOfferAcceptance404ResponseMessageEnum>
    _$finaliseOfferAcceptance404ResponseMessageEnumSerializer =
    _$FinaliseOfferAcceptance404ResponseMessageEnumSerializer();
Serializer<FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum>
    _$finaliseOfferAcceptance404ResponseHttpStatusCodeEnumSerializer =
    _$FinaliseOfferAcceptance404ResponseHttpStatusCodeEnumSerializer();

class _$FinaliseOfferAcceptance404ResponseNameEnumSerializer
    implements PrimitiveSerializer<FinaliseOfferAcceptance404ResponseNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'expiredAcceptanceError': 'ExpiredAcceptanceError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ExpiredAcceptanceError': 'expiredAcceptanceError',
  };

  @override
  final Iterable<Type> types = const <Type>[
    FinaliseOfferAcceptance404ResponseNameEnum
  ];
  @override
  final String wireName = 'FinaliseOfferAcceptance404ResponseNameEnum';

  @override
  Object serialize(Serializers serializers,
          FinaliseOfferAcceptance404ResponseNameEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  FinaliseOfferAcceptance404ResponseNameEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      FinaliseOfferAcceptance404ResponseNameEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$FinaliseOfferAcceptance404ResponseMessageEnumSerializer
    implements
        PrimitiveSerializer<FinaliseOfferAcceptance404ResponseMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'theAcceptanceHasExpired': 'The acceptance has expired',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'The acceptance has expired': 'theAcceptanceHasExpired',
  };

  @override
  final Iterable<Type> types = const <Type>[
    FinaliseOfferAcceptance404ResponseMessageEnum
  ];
  @override
  final String wireName = 'FinaliseOfferAcceptance404ResponseMessageEnum';

  @override
  Object serialize(Serializers serializers,
          FinaliseOfferAcceptance404ResponseMessageEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  FinaliseOfferAcceptance404ResponseMessageEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      FinaliseOfferAcceptance404ResponseMessageEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$FinaliseOfferAcceptance404ResponseHttpStatusCodeEnumSerializer
    implements
        PrimitiveSerializer<
            FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number404': 404,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    404: 'number404',
  };

  @override
  final Iterable<Type> types = const <Type>[
    FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum
  ];
  @override
  final String wireName =
      'FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum';

  @override
  Object serialize(Serializers serializers,
          FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      FinaliseOfferAcceptance404ResponseHttpStatusCodeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$FinaliseOfferAcceptance404Response
    extends FinaliseOfferAcceptance404Response {
  @override
  final OneOf oneOf;

  factory _$FinaliseOfferAcceptance404Response(
          [void Function(FinaliseOfferAcceptance404ResponseBuilder)?
              updates]) =>
      (FinaliseOfferAcceptance404ResponseBuilder()..update(updates))._build();

  _$FinaliseOfferAcceptance404Response._({required this.oneOf}) : super._();
  @override
  FinaliseOfferAcceptance404Response rebuild(
          void Function(FinaliseOfferAcceptance404ResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FinaliseOfferAcceptance404ResponseBuilder toBuilder() =>
      FinaliseOfferAcceptance404ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FinaliseOfferAcceptance404Response && oneOf == other.oneOf;
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
    return (newBuiltValueToStringHelper(r'FinaliseOfferAcceptance404Response')
          ..add('oneOf', oneOf))
        .toString();
  }
}

class FinaliseOfferAcceptance404ResponseBuilder
    implements
        Builder<FinaliseOfferAcceptance404Response,
            FinaliseOfferAcceptance404ResponseBuilder> {
  _$FinaliseOfferAcceptance404Response? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  FinaliseOfferAcceptance404ResponseBuilder() {
    FinaliseOfferAcceptance404Response._defaults(this);
  }

  FinaliseOfferAcceptance404ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FinaliseOfferAcceptance404Response other) {
    _$v = other as _$FinaliseOfferAcceptance404Response;
  }

  @override
  void update(
      void Function(FinaliseOfferAcceptance404ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FinaliseOfferAcceptance404Response build() => _build();

  _$FinaliseOfferAcceptance404Response _build() {
    final _$result = _$v ??
        _$FinaliseOfferAcceptance404Response._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
              oneOf, r'FinaliseOfferAcceptance404Response', 'oneOf'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

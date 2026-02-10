// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query_offer404_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const QueryOffer404ResponseNameEnum
_$queryOffer404ResponseNameEnum_expiredAcceptanceError =
    const QueryOffer404ResponseNameEnum._('expiredAcceptanceError');

QueryOffer404ResponseNameEnum _$queryOffer404ResponseNameEnumValueOf(
  String name,
) {
  switch (name) {
    case 'expiredAcceptanceError':
      return _$queryOffer404ResponseNameEnum_expiredAcceptanceError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<QueryOffer404ResponseNameEnum>
_$queryOffer404ResponseNameEnumValues = BuiltSet<QueryOffer404ResponseNameEnum>(
  const <QueryOffer404ResponseNameEnum>[
    _$queryOffer404ResponseNameEnum_expiredAcceptanceError,
  ],
);

const QueryOffer404ResponseMessageEnum
_$queryOffer404ResponseMessageEnum_theAcceptanceHasExpired =
    const QueryOffer404ResponseMessageEnum._('theAcceptanceHasExpired');

QueryOffer404ResponseMessageEnum _$queryOffer404ResponseMessageEnumValueOf(
  String name,
) {
  switch (name) {
    case 'theAcceptanceHasExpired':
      return _$queryOffer404ResponseMessageEnum_theAcceptanceHasExpired;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<QueryOffer404ResponseMessageEnum>
_$queryOffer404ResponseMessageEnumValues =
    BuiltSet<QueryOffer404ResponseMessageEnum>(
      const <QueryOffer404ResponseMessageEnum>[
        _$queryOffer404ResponseMessageEnum_theAcceptanceHasExpired,
      ],
    );

const QueryOffer404ResponseHttpStatusCodeEnum
_$queryOffer404ResponseHttpStatusCodeEnum_n404 =
    const QueryOffer404ResponseHttpStatusCodeEnum._('n404');

QueryOffer404ResponseHttpStatusCodeEnum
_$queryOffer404ResponseHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'n404':
      return _$queryOffer404ResponseHttpStatusCodeEnum_n404;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<QueryOffer404ResponseHttpStatusCodeEnum>
_$queryOffer404ResponseHttpStatusCodeEnumValues =
    BuiltSet<QueryOffer404ResponseHttpStatusCodeEnum>(
      const <QueryOffer404ResponseHttpStatusCodeEnum>[
        _$queryOffer404ResponseHttpStatusCodeEnum_n404,
      ],
    );

Serializer<QueryOffer404ResponseNameEnum>
_$queryOffer404ResponseNameEnumSerializer =
    _$QueryOffer404ResponseNameEnumSerializer();
Serializer<QueryOffer404ResponseMessageEnum>
_$queryOffer404ResponseMessageEnumSerializer =
    _$QueryOffer404ResponseMessageEnumSerializer();
Serializer<QueryOffer404ResponseHttpStatusCodeEnum>
_$queryOffer404ResponseHttpStatusCodeEnumSerializer =
    _$QueryOffer404ResponseHttpStatusCodeEnumSerializer();

class _$QueryOffer404ResponseNameEnumSerializer
    implements PrimitiveSerializer<QueryOffer404ResponseNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'expiredAcceptanceError': 'ExpiredAcceptanceError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ExpiredAcceptanceError': 'expiredAcceptanceError',
  };

  @override
  final Iterable<Type> types = const <Type>[QueryOffer404ResponseNameEnum];
  @override
  final String wireName = 'QueryOffer404ResponseNameEnum';

  @override
  Object serialize(
    Serializers serializers,
    QueryOffer404ResponseNameEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  QueryOffer404ResponseNameEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => QueryOffer404ResponseNameEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$QueryOffer404ResponseMessageEnumSerializer
    implements PrimitiveSerializer<QueryOffer404ResponseMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'theAcceptanceHasExpired': 'The acceptance has expired',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'The acceptance has expired': 'theAcceptanceHasExpired',
  };

  @override
  final Iterable<Type> types = const <Type>[QueryOffer404ResponseMessageEnum];
  @override
  final String wireName = 'QueryOffer404ResponseMessageEnum';

  @override
  Object serialize(
    Serializers serializers,
    QueryOffer404ResponseMessageEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  QueryOffer404ResponseMessageEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => QueryOffer404ResponseMessageEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$QueryOffer404ResponseHttpStatusCodeEnumSerializer
    implements PrimitiveSerializer<QueryOffer404ResponseHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'n404': '404',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    '404': 'n404',
  };

  @override
  final Iterable<Type> types = const <Type>[
    QueryOffer404ResponseHttpStatusCodeEnum,
  ];
  @override
  final String wireName = 'QueryOffer404ResponseHttpStatusCodeEnum';

  @override
  Object serialize(
    Serializers serializers,
    QueryOffer404ResponseHttpStatusCodeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  QueryOffer404ResponseHttpStatusCodeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => QueryOffer404ResponseHttpStatusCodeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$QueryOffer404Response extends QueryOffer404Response {
  @override
  final OneOf oneOf;

  factory _$QueryOffer404Response([
    void Function(QueryOffer404ResponseBuilder)? updates,
  ]) => (QueryOffer404ResponseBuilder()..update(updates))._build();

  _$QueryOffer404Response._({required this.oneOf}) : super._();
  @override
  QueryOffer404Response rebuild(
    void Function(QueryOffer404ResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  QueryOffer404ResponseBuilder toBuilder() =>
      QueryOffer404ResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is QueryOffer404Response && oneOf == other.oneOf;
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
    return (newBuiltValueToStringHelper(
      r'QueryOffer404Response',
    )..add('oneOf', oneOf)).toString();
  }
}

class QueryOffer404ResponseBuilder
    implements Builder<QueryOffer404Response, QueryOffer404ResponseBuilder> {
  _$QueryOffer404Response? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  QueryOffer404ResponseBuilder() {
    QueryOffer404Response._defaults(this);
  }

  QueryOffer404ResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(QueryOffer404Response other) {
    _$v = other as _$QueryOffer404Response;
  }

  @override
  void update(void Function(QueryOffer404ResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  QueryOffer404Response build() => _build();

  _$QueryOffer404Response _build() {
    final _$result =
        _$v ??
        _$QueryOffer404Response._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
            oneOf,
            r'QueryOffer404Response',
            'oneOf',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

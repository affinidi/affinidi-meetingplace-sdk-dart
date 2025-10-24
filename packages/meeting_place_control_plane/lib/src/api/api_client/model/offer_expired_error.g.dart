// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_expired_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const OfferExpiredErrorNameEnum _$offerExpiredErrorNameEnum_offerExpiredError =
    const OfferExpiredErrorNameEnum._('offerExpiredError');

OfferExpiredErrorNameEnum _$offerExpiredErrorNameEnumValueOf(String name) {
  switch (name) {
    case 'offerExpiredError':
      return _$offerExpiredErrorNameEnum_offerExpiredError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<OfferExpiredErrorNameEnum> _$offerExpiredErrorNameEnumValues =
    BuiltSet<OfferExpiredErrorNameEnum>(const <OfferExpiredErrorNameEnum>[
  _$offerExpiredErrorNameEnum_offerExpiredError,
]);

const OfferExpiredErrorMessageEnum
    _$offerExpiredErrorMessageEnum_theOfferHasExpired =
    const OfferExpiredErrorMessageEnum._('theOfferHasExpired');

OfferExpiredErrorMessageEnum _$offerExpiredErrorMessageEnumValueOf(
    String name) {
  switch (name) {
    case 'theOfferHasExpired':
      return _$offerExpiredErrorMessageEnum_theOfferHasExpired;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<OfferExpiredErrorMessageEnum>
    _$offerExpiredErrorMessageEnumValues =
    BuiltSet<OfferExpiredErrorMessageEnum>(const <OfferExpiredErrorMessageEnum>[
  _$offerExpiredErrorMessageEnum_theOfferHasExpired,
]);

const OfferExpiredErrorHttpStatusCodeEnum
    _$offerExpiredErrorHttpStatusCodeEnum_number404 =
    const OfferExpiredErrorHttpStatusCodeEnum._('number404');

OfferExpiredErrorHttpStatusCodeEnum
    _$offerExpiredErrorHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'number404':
      return _$offerExpiredErrorHttpStatusCodeEnum_number404;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<OfferExpiredErrorHttpStatusCodeEnum>
    _$offerExpiredErrorHttpStatusCodeEnumValues = BuiltSet<
        OfferExpiredErrorHttpStatusCodeEnum>(const <OfferExpiredErrorHttpStatusCodeEnum>[
  _$offerExpiredErrorHttpStatusCodeEnum_number404,
]);

Serializer<OfferExpiredErrorNameEnum> _$offerExpiredErrorNameEnumSerializer =
    _$OfferExpiredErrorNameEnumSerializer();
Serializer<OfferExpiredErrorMessageEnum>
    _$offerExpiredErrorMessageEnumSerializer =
    _$OfferExpiredErrorMessageEnumSerializer();
Serializer<OfferExpiredErrorHttpStatusCodeEnum>
    _$offerExpiredErrorHttpStatusCodeEnumSerializer =
    _$OfferExpiredErrorHttpStatusCodeEnumSerializer();

class _$OfferExpiredErrorNameEnumSerializer
    implements PrimitiveSerializer<OfferExpiredErrorNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'offerExpiredError': 'OfferExpiredError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OfferExpiredError': 'offerExpiredError',
  };

  @override
  final Iterable<Type> types = const <Type>[OfferExpiredErrorNameEnum];
  @override
  final String wireName = 'OfferExpiredErrorNameEnum';

  @override
  Object serialize(Serializers serializers, OfferExpiredErrorNameEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  OfferExpiredErrorNameEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      OfferExpiredErrorNameEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$OfferExpiredErrorMessageEnumSerializer
    implements PrimitiveSerializer<OfferExpiredErrorMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'theOfferHasExpired': 'The offer has expired',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'The offer has expired': 'theOfferHasExpired',
  };

  @override
  final Iterable<Type> types = const <Type>[OfferExpiredErrorMessageEnum];
  @override
  final String wireName = 'OfferExpiredErrorMessageEnum';

  @override
  Object serialize(Serializers serializers, OfferExpiredErrorMessageEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  OfferExpiredErrorMessageEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      OfferExpiredErrorMessageEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$OfferExpiredErrorHttpStatusCodeEnumSerializer
    implements PrimitiveSerializer<OfferExpiredErrorHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number404': 404,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    404: 'number404',
  };

  @override
  final Iterable<Type> types = const <Type>[
    OfferExpiredErrorHttpStatusCodeEnum
  ];
  @override
  final String wireName = 'OfferExpiredErrorHttpStatusCodeEnum';

  @override
  Object serialize(
          Serializers serializers, OfferExpiredErrorHttpStatusCodeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  OfferExpiredErrorHttpStatusCodeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      OfferExpiredErrorHttpStatusCodeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$OfferExpiredError extends OfferExpiredError {
  @override
  final OfferExpiredErrorNameEnum name;
  @override
  final OfferExpiredErrorMessageEnum message;
  @override
  final OfferExpiredErrorHttpStatusCodeEnum httpStatusCode;
  @override
  final String traceId;
  @override
  final BuiltList<NotFoundErrorDetailsInner>? details;

  factory _$OfferExpiredError(
          [void Function(OfferExpiredErrorBuilder)? updates]) =>
      (OfferExpiredErrorBuilder()..update(updates))._build();

  _$OfferExpiredError._(
      {required this.name,
      required this.message,
      required this.httpStatusCode,
      required this.traceId,
      this.details})
      : super._();
  @override
  OfferExpiredError rebuild(void Function(OfferExpiredErrorBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OfferExpiredErrorBuilder toBuilder() =>
      OfferExpiredErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OfferExpiredError &&
        name == other.name &&
        message == other.message &&
        httpStatusCode == other.httpStatusCode &&
        traceId == other.traceId &&
        details == other.details;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, httpStatusCode.hashCode);
    _$hash = $jc(_$hash, traceId.hashCode);
    _$hash = $jc(_$hash, details.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OfferExpiredError')
          ..add('name', name)
          ..add('message', message)
          ..add('httpStatusCode', httpStatusCode)
          ..add('traceId', traceId)
          ..add('details', details))
        .toString();
  }
}

class OfferExpiredErrorBuilder
    implements Builder<OfferExpiredError, OfferExpiredErrorBuilder> {
  _$OfferExpiredError? _$v;

  OfferExpiredErrorNameEnum? _name;
  OfferExpiredErrorNameEnum? get name => _$this._name;
  set name(OfferExpiredErrorNameEnum? name) => _$this._name = name;

  OfferExpiredErrorMessageEnum? _message;
  OfferExpiredErrorMessageEnum? get message => _$this._message;
  set message(OfferExpiredErrorMessageEnum? message) =>
      _$this._message = message;

  OfferExpiredErrorHttpStatusCodeEnum? _httpStatusCode;
  OfferExpiredErrorHttpStatusCodeEnum? get httpStatusCode =>
      _$this._httpStatusCode;
  set httpStatusCode(OfferExpiredErrorHttpStatusCodeEnum? httpStatusCode) =>
      _$this._httpStatusCode = httpStatusCode;

  String? _traceId;
  String? get traceId => _$this._traceId;
  set traceId(String? traceId) => _$this._traceId = traceId;

  ListBuilder<NotFoundErrorDetailsInner>? _details;
  ListBuilder<NotFoundErrorDetailsInner> get details =>
      _$this._details ??= ListBuilder<NotFoundErrorDetailsInner>();
  set details(ListBuilder<NotFoundErrorDetailsInner>? details) =>
      _$this._details = details;

  OfferExpiredErrorBuilder() {
    OfferExpiredError._defaults(this);
  }

  OfferExpiredErrorBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _name = $v.name;
      _message = $v.message;
      _httpStatusCode = $v.httpStatusCode;
      _traceId = $v.traceId;
      _details = $v.details?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OfferExpiredError other) {
    _$v = other as _$OfferExpiredError;
  }

  @override
  void update(void Function(OfferExpiredErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OfferExpiredError build() => _build();

  _$OfferExpiredError _build() {
    _$OfferExpiredError _$result;
    try {
      _$result = _$v ??
          _$OfferExpiredError._(
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'OfferExpiredError', 'name'),
            message: BuiltValueNullFieldError.checkNotNull(
                message, r'OfferExpiredError', 'message'),
            httpStatusCode: BuiltValueNullFieldError.checkNotNull(
                httpStatusCode, r'OfferExpiredError', 'httpStatusCode'),
            traceId: BuiltValueNullFieldError.checkNotNull(
                traceId, r'OfferExpiredError', 'traceId'),
            details: _details?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'details';
        _details?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'OfferExpiredError', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

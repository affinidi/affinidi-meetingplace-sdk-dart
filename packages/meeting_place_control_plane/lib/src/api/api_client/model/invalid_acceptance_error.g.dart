// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invalid_acceptance_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const InvalidAcceptanceErrorNameEnum
    _$invalidAcceptanceErrorNameEnum_invalidAcceptanceError =
    const InvalidAcceptanceErrorNameEnum._('invalidAcceptanceError');

InvalidAcceptanceErrorNameEnum _$invalidAcceptanceErrorNameEnumValueOf(
    String name) {
  switch (name) {
    case 'invalidAcceptanceError':
      return _$invalidAcceptanceErrorNameEnum_invalidAcceptanceError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<InvalidAcceptanceErrorNameEnum>
    _$invalidAcceptanceErrorNameEnumValues = BuiltSet<
        InvalidAcceptanceErrorNameEnum>(const <InvalidAcceptanceErrorNameEnum>[
  _$invalidAcceptanceErrorNameEnum_invalidAcceptanceError,
]);

const InvalidAcceptanceErrorMessageEnum
    _$invalidAcceptanceErrorMessageEnum_noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod =
    const InvalidAcceptanceErrorMessageEnum._(
        'noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod');

InvalidAcceptanceErrorMessageEnum _$invalidAcceptanceErrorMessageEnumValueOf(
    String name) {
  switch (name) {
    case 'noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod':
      return _$invalidAcceptanceErrorMessageEnum_noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<InvalidAcceptanceErrorMessageEnum>
    _$invalidAcceptanceErrorMessageEnumValues = BuiltSet<
        InvalidAcceptanceErrorMessageEnum>(const <InvalidAcceptanceErrorMessageEnum>[
  _$invalidAcceptanceErrorMessageEnum_noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod,
]);

const InvalidAcceptanceErrorHttpStatusCodeEnum
    _$invalidAcceptanceErrorHttpStatusCodeEnum_number404 =
    const InvalidAcceptanceErrorHttpStatusCodeEnum._('number404');

InvalidAcceptanceErrorHttpStatusCodeEnum
    _$invalidAcceptanceErrorHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'number404':
      return _$invalidAcceptanceErrorHttpStatusCodeEnum_number404;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<InvalidAcceptanceErrorHttpStatusCodeEnum>
    _$invalidAcceptanceErrorHttpStatusCodeEnumValues = BuiltSet<
        InvalidAcceptanceErrorHttpStatusCodeEnum>(const <InvalidAcceptanceErrorHttpStatusCodeEnum>[
  _$invalidAcceptanceErrorHttpStatusCodeEnum_number404,
]);

Serializer<InvalidAcceptanceErrorNameEnum>
    _$invalidAcceptanceErrorNameEnumSerializer =
    _$InvalidAcceptanceErrorNameEnumSerializer();
Serializer<InvalidAcceptanceErrorMessageEnum>
    _$invalidAcceptanceErrorMessageEnumSerializer =
    _$InvalidAcceptanceErrorMessageEnumSerializer();
Serializer<InvalidAcceptanceErrorHttpStatusCodeEnum>
    _$invalidAcceptanceErrorHttpStatusCodeEnumSerializer =
    _$InvalidAcceptanceErrorHttpStatusCodeEnumSerializer();

class _$InvalidAcceptanceErrorNameEnumSerializer
    implements PrimitiveSerializer<InvalidAcceptanceErrorNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'invalidAcceptanceError': 'InvalidAcceptanceError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'InvalidAcceptanceError': 'invalidAcceptanceError',
  };

  @override
  final Iterable<Type> types = const <Type>[InvalidAcceptanceErrorNameEnum];
  @override
  final String wireName = 'InvalidAcceptanceErrorNameEnum';

  @override
  Object serialize(
          Serializers serializers, InvalidAcceptanceErrorNameEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  InvalidAcceptanceErrorNameEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      InvalidAcceptanceErrorNameEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$InvalidAcceptanceErrorMessageEnumSerializer
    implements PrimitiveSerializer<InvalidAcceptanceErrorMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod':
        'No valid acceptance found that matches the details provided.',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'No valid acceptance found that matches the details provided.':
        'noValidAcceptanceFoundThatMatchesTheDetailsProvidedPeriod',
  };

  @override
  final Iterable<Type> types = const <Type>[InvalidAcceptanceErrorMessageEnum];
  @override
  final String wireName = 'InvalidAcceptanceErrorMessageEnum';

  @override
  Object serialize(
          Serializers serializers, InvalidAcceptanceErrorMessageEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  InvalidAcceptanceErrorMessageEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      InvalidAcceptanceErrorMessageEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$InvalidAcceptanceErrorHttpStatusCodeEnumSerializer
    implements PrimitiveSerializer<InvalidAcceptanceErrorHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number404': 404,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    404: 'number404',
  };

  @override
  final Iterable<Type> types = const <Type>[
    InvalidAcceptanceErrorHttpStatusCodeEnum
  ];
  @override
  final String wireName = 'InvalidAcceptanceErrorHttpStatusCodeEnum';

  @override
  Object serialize(Serializers serializers,
          InvalidAcceptanceErrorHttpStatusCodeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  InvalidAcceptanceErrorHttpStatusCodeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      InvalidAcceptanceErrorHttpStatusCodeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$InvalidAcceptanceError extends InvalidAcceptanceError {
  @override
  final InvalidAcceptanceErrorNameEnum name;
  @override
  final InvalidAcceptanceErrorMessageEnum message;
  @override
  final InvalidAcceptanceErrorHttpStatusCodeEnum httpStatusCode;
  @override
  final String traceId;
  @override
  final BuiltList<NotFoundErrorDetailsInner>? details;

  factory _$InvalidAcceptanceError(
          [void Function(InvalidAcceptanceErrorBuilder)? updates]) =>
      (InvalidAcceptanceErrorBuilder()..update(updates))._build();

  _$InvalidAcceptanceError._(
      {required this.name,
      required this.message,
      required this.httpStatusCode,
      required this.traceId,
      this.details})
      : super._();
  @override
  InvalidAcceptanceError rebuild(
          void Function(InvalidAcceptanceErrorBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InvalidAcceptanceErrorBuilder toBuilder() =>
      InvalidAcceptanceErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InvalidAcceptanceError &&
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
    return (newBuiltValueToStringHelper(r'InvalidAcceptanceError')
          ..add('name', name)
          ..add('message', message)
          ..add('httpStatusCode', httpStatusCode)
          ..add('traceId', traceId)
          ..add('details', details))
        .toString();
  }
}

class InvalidAcceptanceErrorBuilder
    implements Builder<InvalidAcceptanceError, InvalidAcceptanceErrorBuilder> {
  _$InvalidAcceptanceError? _$v;

  InvalidAcceptanceErrorNameEnum? _name;
  InvalidAcceptanceErrorNameEnum? get name => _$this._name;
  set name(InvalidAcceptanceErrorNameEnum? name) => _$this._name = name;

  InvalidAcceptanceErrorMessageEnum? _message;
  InvalidAcceptanceErrorMessageEnum? get message => _$this._message;
  set message(InvalidAcceptanceErrorMessageEnum? message) =>
      _$this._message = message;

  InvalidAcceptanceErrorHttpStatusCodeEnum? _httpStatusCode;
  InvalidAcceptanceErrorHttpStatusCodeEnum? get httpStatusCode =>
      _$this._httpStatusCode;
  set httpStatusCode(
          InvalidAcceptanceErrorHttpStatusCodeEnum? httpStatusCode) =>
      _$this._httpStatusCode = httpStatusCode;

  String? _traceId;
  String? get traceId => _$this._traceId;
  set traceId(String? traceId) => _$this._traceId = traceId;

  ListBuilder<NotFoundErrorDetailsInner>? _details;
  ListBuilder<NotFoundErrorDetailsInner> get details =>
      _$this._details ??= ListBuilder<NotFoundErrorDetailsInner>();
  set details(ListBuilder<NotFoundErrorDetailsInner>? details) =>
      _$this._details = details;

  InvalidAcceptanceErrorBuilder() {
    InvalidAcceptanceError._defaults(this);
  }

  InvalidAcceptanceErrorBuilder get _$this {
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
  void replace(InvalidAcceptanceError other) {
    _$v = other as _$InvalidAcceptanceError;
  }

  @override
  void update(void Function(InvalidAcceptanceErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  InvalidAcceptanceError build() => _build();

  _$InvalidAcceptanceError _build() {
    _$InvalidAcceptanceError _$result;
    try {
      _$result = _$v ??
          _$InvalidAcceptanceError._(
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'InvalidAcceptanceError', 'name'),
            message: BuiltValueNullFieldError.checkNotNull(
                message, r'InvalidAcceptanceError', 'message'),
            httpStatusCode: BuiltValueNullFieldError.checkNotNull(
                httpStatusCode, r'InvalidAcceptanceError', 'httpStatusCode'),
            traceId: BuiltValueNullFieldError.checkNotNull(
                traceId, r'InvalidAcceptanceError', 'traceId'),
            details: _details?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'details';
        _details?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'InvalidAcceptanceError', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

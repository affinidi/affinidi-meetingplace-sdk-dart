// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expired_acceptance_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ExpiredAcceptanceErrorNameEnum
_$expiredAcceptanceErrorNameEnum_expiredAcceptanceError =
    const ExpiredAcceptanceErrorNameEnum._('expiredAcceptanceError');

ExpiredAcceptanceErrorNameEnum _$expiredAcceptanceErrorNameEnumValueOf(
  String name,
) {
  switch (name) {
    case 'expiredAcceptanceError':
      return _$expiredAcceptanceErrorNameEnum_expiredAcceptanceError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ExpiredAcceptanceErrorNameEnum>
_$expiredAcceptanceErrorNameEnumValues =
    BuiltSet<ExpiredAcceptanceErrorNameEnum>(
      const <ExpiredAcceptanceErrorNameEnum>[
        _$expiredAcceptanceErrorNameEnum_expiredAcceptanceError,
      ],
    );

const ExpiredAcceptanceErrorMessageEnum
_$expiredAcceptanceErrorMessageEnum_theAcceptanceHasExpired =
    const ExpiredAcceptanceErrorMessageEnum._('theAcceptanceHasExpired');

ExpiredAcceptanceErrorMessageEnum _$expiredAcceptanceErrorMessageEnumValueOf(
  String name,
) {
  switch (name) {
    case 'theAcceptanceHasExpired':
      return _$expiredAcceptanceErrorMessageEnum_theAcceptanceHasExpired;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ExpiredAcceptanceErrorMessageEnum>
_$expiredAcceptanceErrorMessageEnumValues =
    BuiltSet<ExpiredAcceptanceErrorMessageEnum>(
      const <ExpiredAcceptanceErrorMessageEnum>[
        _$expiredAcceptanceErrorMessageEnum_theAcceptanceHasExpired,
      ],
    );

const ExpiredAcceptanceErrorHttpStatusCodeEnum
_$expiredAcceptanceErrorHttpStatusCodeEnum_number404 =
    const ExpiredAcceptanceErrorHttpStatusCodeEnum._('number404');

ExpiredAcceptanceErrorHttpStatusCodeEnum
_$expiredAcceptanceErrorHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'number404':
      return _$expiredAcceptanceErrorHttpStatusCodeEnum_number404;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ExpiredAcceptanceErrorHttpStatusCodeEnum>
_$expiredAcceptanceErrorHttpStatusCodeEnumValues =
    BuiltSet<ExpiredAcceptanceErrorHttpStatusCodeEnum>(
      const <ExpiredAcceptanceErrorHttpStatusCodeEnum>[
        _$expiredAcceptanceErrorHttpStatusCodeEnum_number404,
      ],
    );

Serializer<ExpiredAcceptanceErrorNameEnum>
_$expiredAcceptanceErrorNameEnumSerializer =
    _$ExpiredAcceptanceErrorNameEnumSerializer();
Serializer<ExpiredAcceptanceErrorMessageEnum>
_$expiredAcceptanceErrorMessageEnumSerializer =
    _$ExpiredAcceptanceErrorMessageEnumSerializer();
Serializer<ExpiredAcceptanceErrorHttpStatusCodeEnum>
_$expiredAcceptanceErrorHttpStatusCodeEnumSerializer =
    _$ExpiredAcceptanceErrorHttpStatusCodeEnumSerializer();

class _$ExpiredAcceptanceErrorNameEnumSerializer
    implements PrimitiveSerializer<ExpiredAcceptanceErrorNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'expiredAcceptanceError': 'ExpiredAcceptanceError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ExpiredAcceptanceError': 'expiredAcceptanceError',
  };

  @override
  final Iterable<Type> types = const <Type>[ExpiredAcceptanceErrorNameEnum];
  @override
  final String wireName = 'ExpiredAcceptanceErrorNameEnum';

  @override
  Object serialize(
    Serializers serializers,
    ExpiredAcceptanceErrorNameEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ExpiredAcceptanceErrorNameEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ExpiredAcceptanceErrorNameEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ExpiredAcceptanceErrorMessageEnumSerializer
    implements PrimitiveSerializer<ExpiredAcceptanceErrorMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'theAcceptanceHasExpired': 'The acceptance has expired',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'The acceptance has expired': 'theAcceptanceHasExpired',
  };

  @override
  final Iterable<Type> types = const <Type>[ExpiredAcceptanceErrorMessageEnum];
  @override
  final String wireName = 'ExpiredAcceptanceErrorMessageEnum';

  @override
  Object serialize(
    Serializers serializers,
    ExpiredAcceptanceErrorMessageEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ExpiredAcceptanceErrorMessageEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ExpiredAcceptanceErrorMessageEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ExpiredAcceptanceErrorHttpStatusCodeEnumSerializer
    implements PrimitiveSerializer<ExpiredAcceptanceErrorHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number404': 404,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    404: 'number404',
  };

  @override
  final Iterable<Type> types = const <Type>[
    ExpiredAcceptanceErrorHttpStatusCodeEnum,
  ];
  @override
  final String wireName = 'ExpiredAcceptanceErrorHttpStatusCodeEnum';

  @override
  Object serialize(
    Serializers serializers,
    ExpiredAcceptanceErrorHttpStatusCodeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ExpiredAcceptanceErrorHttpStatusCodeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ExpiredAcceptanceErrorHttpStatusCodeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ExpiredAcceptanceError extends ExpiredAcceptanceError {
  @override
  final ExpiredAcceptanceErrorNameEnum name;
  @override
  final ExpiredAcceptanceErrorMessageEnum message;
  @override
  final ExpiredAcceptanceErrorHttpStatusCodeEnum httpStatusCode;
  @override
  final String traceId;
  @override
  final BuiltList<NotFoundErrorDetailsInner>? details;

  factory _$ExpiredAcceptanceError([
    void Function(ExpiredAcceptanceErrorBuilder)? updates,
  ]) => (ExpiredAcceptanceErrorBuilder()..update(updates))._build();

  _$ExpiredAcceptanceError._({
    required this.name,
    required this.message,
    required this.httpStatusCode,
    required this.traceId,
    this.details,
  }) : super._();
  @override
  ExpiredAcceptanceError rebuild(
    void Function(ExpiredAcceptanceErrorBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ExpiredAcceptanceErrorBuilder toBuilder() =>
      ExpiredAcceptanceErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExpiredAcceptanceError &&
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
    return (newBuiltValueToStringHelper(r'ExpiredAcceptanceError')
          ..add('name', name)
          ..add('message', message)
          ..add('httpStatusCode', httpStatusCode)
          ..add('traceId', traceId)
          ..add('details', details))
        .toString();
  }
}

class ExpiredAcceptanceErrorBuilder
    implements Builder<ExpiredAcceptanceError, ExpiredAcceptanceErrorBuilder> {
  _$ExpiredAcceptanceError? _$v;

  ExpiredAcceptanceErrorNameEnum? _name;
  ExpiredAcceptanceErrorNameEnum? get name => _$this._name;
  set name(ExpiredAcceptanceErrorNameEnum? name) => _$this._name = name;

  ExpiredAcceptanceErrorMessageEnum? _message;
  ExpiredAcceptanceErrorMessageEnum? get message => _$this._message;
  set message(ExpiredAcceptanceErrorMessageEnum? message) =>
      _$this._message = message;

  ExpiredAcceptanceErrorHttpStatusCodeEnum? _httpStatusCode;
  ExpiredAcceptanceErrorHttpStatusCodeEnum? get httpStatusCode =>
      _$this._httpStatusCode;
  set httpStatusCode(
    ExpiredAcceptanceErrorHttpStatusCodeEnum? httpStatusCode,
  ) => _$this._httpStatusCode = httpStatusCode;

  String? _traceId;
  String? get traceId => _$this._traceId;
  set traceId(String? traceId) => _$this._traceId = traceId;

  ListBuilder<NotFoundErrorDetailsInner>? _details;
  ListBuilder<NotFoundErrorDetailsInner> get details =>
      _$this._details ??= ListBuilder<NotFoundErrorDetailsInner>();
  set details(ListBuilder<NotFoundErrorDetailsInner>? details) =>
      _$this._details = details;

  ExpiredAcceptanceErrorBuilder() {
    ExpiredAcceptanceError._defaults(this);
  }

  ExpiredAcceptanceErrorBuilder get _$this {
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
  void replace(ExpiredAcceptanceError other) {
    _$v = other as _$ExpiredAcceptanceError;
  }

  @override
  void update(void Function(ExpiredAcceptanceErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExpiredAcceptanceError build() => _build();

  _$ExpiredAcceptanceError _build() {
    _$ExpiredAcceptanceError _$result;
    try {
      _$result =
          _$v ??
          _$ExpiredAcceptanceError._(
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'ExpiredAcceptanceError',
              'name',
            ),
            message: BuiltValueNullFieldError.checkNotNull(
              message,
              r'ExpiredAcceptanceError',
              'message',
            ),
            httpStatusCode: BuiltValueNullFieldError.checkNotNull(
              httpStatusCode,
              r'ExpiredAcceptanceError',
              'httpStatusCode',
            ),
            traceId: BuiltValueNullFieldError.checkNotNull(
              traceId,
              r'ExpiredAcceptanceError',
              'traceId',
            ),
            details: _details?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'details';
        _details?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ExpiredAcceptanceError',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

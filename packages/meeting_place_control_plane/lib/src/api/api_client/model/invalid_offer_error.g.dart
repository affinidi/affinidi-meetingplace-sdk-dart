// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invalid_offer_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const InvalidOfferErrorNameEnum _$invalidOfferErrorNameEnum_invalidOfferError =
    const InvalidOfferErrorNameEnum._('invalidOfferError');

InvalidOfferErrorNameEnum _$invalidOfferErrorNameEnumValueOf(String name) {
  switch (name) {
    case 'invalidOfferError':
      return _$invalidOfferErrorNameEnum_invalidOfferError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<InvalidOfferErrorNameEnum> _$invalidOfferErrorNameEnumValues =
    BuiltSet<InvalidOfferErrorNameEnum>(const <InvalidOfferErrorNameEnum>[
      _$invalidOfferErrorNameEnum_invalidOfferError,
    ]);

const InvalidOfferErrorMessageEnum
_$invalidOfferErrorMessageEnum_noValidOfferFoundThatMatchesTheDetailsProvidedPeriod =
    const InvalidOfferErrorMessageEnum._(
      'noValidOfferFoundThatMatchesTheDetailsProvidedPeriod',
    );

InvalidOfferErrorMessageEnum _$invalidOfferErrorMessageEnumValueOf(
  String name,
) {
  switch (name) {
    case 'noValidOfferFoundThatMatchesTheDetailsProvidedPeriod':
      return _$invalidOfferErrorMessageEnum_noValidOfferFoundThatMatchesTheDetailsProvidedPeriod;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<InvalidOfferErrorMessageEnum>
_$invalidOfferErrorMessageEnumValues = BuiltSet<InvalidOfferErrorMessageEnum>(
  const <InvalidOfferErrorMessageEnum>[
    _$invalidOfferErrorMessageEnum_noValidOfferFoundThatMatchesTheDetailsProvidedPeriod,
  ],
);

const InvalidOfferErrorHttpStatusCodeEnum
_$invalidOfferErrorHttpStatusCodeEnum_number404 =
    const InvalidOfferErrorHttpStatusCodeEnum._('number404');

InvalidOfferErrorHttpStatusCodeEnum
_$invalidOfferErrorHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'number404':
      return _$invalidOfferErrorHttpStatusCodeEnum_number404;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<InvalidOfferErrorHttpStatusCodeEnum>
_$invalidOfferErrorHttpStatusCodeEnumValues =
    BuiltSet<InvalidOfferErrorHttpStatusCodeEnum>(
      const <InvalidOfferErrorHttpStatusCodeEnum>[
        _$invalidOfferErrorHttpStatusCodeEnum_number404,
      ],
    );

Serializer<InvalidOfferErrorNameEnum> _$invalidOfferErrorNameEnumSerializer =
    _$InvalidOfferErrorNameEnumSerializer();
Serializer<InvalidOfferErrorMessageEnum>
_$invalidOfferErrorMessageEnumSerializer =
    _$InvalidOfferErrorMessageEnumSerializer();
Serializer<InvalidOfferErrorHttpStatusCodeEnum>
_$invalidOfferErrorHttpStatusCodeEnumSerializer =
    _$InvalidOfferErrorHttpStatusCodeEnumSerializer();

class _$InvalidOfferErrorNameEnumSerializer
    implements PrimitiveSerializer<InvalidOfferErrorNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'invalidOfferError': 'InvalidOfferError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'InvalidOfferError': 'invalidOfferError',
  };

  @override
  final Iterable<Type> types = const <Type>[InvalidOfferErrorNameEnum];
  @override
  final String wireName = 'InvalidOfferErrorNameEnum';

  @override
  Object serialize(
    Serializers serializers,
    InvalidOfferErrorNameEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  InvalidOfferErrorNameEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => InvalidOfferErrorNameEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$InvalidOfferErrorMessageEnumSerializer
    implements PrimitiveSerializer<InvalidOfferErrorMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'noValidOfferFoundThatMatchesTheDetailsProvidedPeriod':
        'No valid offer found that matches the details provided.',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'No valid offer found that matches the details provided.':
        'noValidOfferFoundThatMatchesTheDetailsProvidedPeriod',
  };

  @override
  final Iterable<Type> types = const <Type>[InvalidOfferErrorMessageEnum];
  @override
  final String wireName = 'InvalidOfferErrorMessageEnum';

  @override
  Object serialize(
    Serializers serializers,
    InvalidOfferErrorMessageEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  InvalidOfferErrorMessageEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => InvalidOfferErrorMessageEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$InvalidOfferErrorHttpStatusCodeEnumSerializer
    implements PrimitiveSerializer<InvalidOfferErrorHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number404': 404,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    404: 'number404',
  };

  @override
  final Iterable<Type> types = const <Type>[
    InvalidOfferErrorHttpStatusCodeEnum,
  ];
  @override
  final String wireName = 'InvalidOfferErrorHttpStatusCodeEnum';

  @override
  Object serialize(
    Serializers serializers,
    InvalidOfferErrorHttpStatusCodeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  InvalidOfferErrorHttpStatusCodeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => InvalidOfferErrorHttpStatusCodeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$InvalidOfferError extends InvalidOfferError {
  @override
  final InvalidOfferErrorNameEnum name;
  @override
  final InvalidOfferErrorMessageEnum message;
  @override
  final InvalidOfferErrorHttpStatusCodeEnum httpStatusCode;
  @override
  final String traceId;
  @override
  final BuiltList<NotFoundErrorDetailsInner>? details;

  factory _$InvalidOfferError([
    void Function(InvalidOfferErrorBuilder)? updates,
  ]) => (InvalidOfferErrorBuilder()..update(updates))._build();

  _$InvalidOfferError._({
    required this.name,
    required this.message,
    required this.httpStatusCode,
    required this.traceId,
    this.details,
  }) : super._();
  @override
  InvalidOfferError rebuild(void Function(InvalidOfferErrorBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InvalidOfferErrorBuilder toBuilder() =>
      InvalidOfferErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is InvalidOfferError &&
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
    return (newBuiltValueToStringHelper(r'InvalidOfferError')
          ..add('name', name)
          ..add('message', message)
          ..add('httpStatusCode', httpStatusCode)
          ..add('traceId', traceId)
          ..add('details', details))
        .toString();
  }
}

class InvalidOfferErrorBuilder
    implements Builder<InvalidOfferError, InvalidOfferErrorBuilder> {
  _$InvalidOfferError? _$v;

  InvalidOfferErrorNameEnum? _name;
  InvalidOfferErrorNameEnum? get name => _$this._name;
  set name(InvalidOfferErrorNameEnum? name) => _$this._name = name;

  InvalidOfferErrorMessageEnum? _message;
  InvalidOfferErrorMessageEnum? get message => _$this._message;
  set message(InvalidOfferErrorMessageEnum? message) =>
      _$this._message = message;

  InvalidOfferErrorHttpStatusCodeEnum? _httpStatusCode;
  InvalidOfferErrorHttpStatusCodeEnum? get httpStatusCode =>
      _$this._httpStatusCode;
  set httpStatusCode(InvalidOfferErrorHttpStatusCodeEnum? httpStatusCode) =>
      _$this._httpStatusCode = httpStatusCode;

  String? _traceId;
  String? get traceId => _$this._traceId;
  set traceId(String? traceId) => _$this._traceId = traceId;

  ListBuilder<NotFoundErrorDetailsInner>? _details;
  ListBuilder<NotFoundErrorDetailsInner> get details =>
      _$this._details ??= ListBuilder<NotFoundErrorDetailsInner>();
  set details(ListBuilder<NotFoundErrorDetailsInner>? details) =>
      _$this._details = details;

  InvalidOfferErrorBuilder() {
    InvalidOfferError._defaults(this);
  }

  InvalidOfferErrorBuilder get _$this {
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
  void replace(InvalidOfferError other) {
    _$v = other as _$InvalidOfferError;
  }

  @override
  void update(void Function(InvalidOfferErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  InvalidOfferError build() => _build();

  _$InvalidOfferError _build() {
    _$InvalidOfferError _$result;
    try {
      _$result =
          _$v ??
          _$InvalidOfferError._(
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'InvalidOfferError',
              'name',
            ),
            message: BuiltValueNullFieldError.checkNotNull(
              message,
              r'InvalidOfferError',
              'message',
            ),
            httpStatusCode: BuiltValueNullFieldError.checkNotNull(
              httpStatusCode,
              r'InvalidOfferError',
              'httpStatusCode',
            ),
            traceId: BuiltValueNullFieldError.checkNotNull(
              traceId,
              r'InvalidOfferError',
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
          r'InvalidOfferError',
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

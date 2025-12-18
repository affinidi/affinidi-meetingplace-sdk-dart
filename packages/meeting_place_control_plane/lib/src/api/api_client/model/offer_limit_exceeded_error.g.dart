// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_limit_exceeded_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const OfferLimitExceededErrorNameEnum
_$offerLimitExceededErrorNameEnum_offerLimitExceededError =
    const OfferLimitExceededErrorNameEnum._('offerLimitExceededError');

OfferLimitExceededErrorNameEnum _$offerLimitExceededErrorNameEnumValueOf(
  String name,
) {
  switch (name) {
    case 'offerLimitExceededError':
      return _$offerLimitExceededErrorNameEnum_offerLimitExceededError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<OfferLimitExceededErrorNameEnum>
_$offerLimitExceededErrorNameEnumValues =
    BuiltSet<OfferLimitExceededErrorNameEnum>(
      const <OfferLimitExceededErrorNameEnum>[
        _$offerLimitExceededErrorNameEnum_offerLimitExceededError,
      ],
    );

const OfferLimitExceededErrorMessageEnum
_$offerLimitExceededErrorMessageEnum_theOfferIsNoLongerValid =
    const OfferLimitExceededErrorMessageEnum._('theOfferIsNoLongerValid');

OfferLimitExceededErrorMessageEnum _$offerLimitExceededErrorMessageEnumValueOf(
  String name,
) {
  switch (name) {
    case 'theOfferIsNoLongerValid':
      return _$offerLimitExceededErrorMessageEnum_theOfferIsNoLongerValid;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<OfferLimitExceededErrorMessageEnum>
_$offerLimitExceededErrorMessageEnumValues =
    BuiltSet<OfferLimitExceededErrorMessageEnum>(
      const <OfferLimitExceededErrorMessageEnum>[
        _$offerLimitExceededErrorMessageEnum_theOfferIsNoLongerValid,
      ],
    );

const OfferLimitExceededErrorHttpStatusCodeEnum
_$offerLimitExceededErrorHttpStatusCodeEnum_number404 =
    const OfferLimitExceededErrorHttpStatusCodeEnum._('number404');

OfferLimitExceededErrorHttpStatusCodeEnum
_$offerLimitExceededErrorHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'number404':
      return _$offerLimitExceededErrorHttpStatusCodeEnum_number404;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<OfferLimitExceededErrorHttpStatusCodeEnum>
_$offerLimitExceededErrorHttpStatusCodeEnumValues =
    BuiltSet<OfferLimitExceededErrorHttpStatusCodeEnum>(
      const <OfferLimitExceededErrorHttpStatusCodeEnum>[
        _$offerLimitExceededErrorHttpStatusCodeEnum_number404,
      ],
    );

Serializer<OfferLimitExceededErrorNameEnum>
_$offerLimitExceededErrorNameEnumSerializer =
    _$OfferLimitExceededErrorNameEnumSerializer();
Serializer<OfferLimitExceededErrorMessageEnum>
_$offerLimitExceededErrorMessageEnumSerializer =
    _$OfferLimitExceededErrorMessageEnumSerializer();
Serializer<OfferLimitExceededErrorHttpStatusCodeEnum>
_$offerLimitExceededErrorHttpStatusCodeEnumSerializer =
    _$OfferLimitExceededErrorHttpStatusCodeEnumSerializer();

class _$OfferLimitExceededErrorNameEnumSerializer
    implements PrimitiveSerializer<OfferLimitExceededErrorNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'offerLimitExceededError': 'OfferLimitExceededError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OfferLimitExceededError': 'offerLimitExceededError',
  };

  @override
  final Iterable<Type> types = const <Type>[OfferLimitExceededErrorNameEnum];
  @override
  final String wireName = 'OfferLimitExceededErrorNameEnum';

  @override
  Object serialize(
    Serializers serializers,
    OfferLimitExceededErrorNameEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  OfferLimitExceededErrorNameEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => OfferLimitExceededErrorNameEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$OfferLimitExceededErrorMessageEnumSerializer
    implements PrimitiveSerializer<OfferLimitExceededErrorMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'theOfferIsNoLongerValid': 'The offer is no longer valid',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'The offer is no longer valid': 'theOfferIsNoLongerValid',
  };

  @override
  final Iterable<Type> types = const <Type>[OfferLimitExceededErrorMessageEnum];
  @override
  final String wireName = 'OfferLimitExceededErrorMessageEnum';

  @override
  Object serialize(
    Serializers serializers,
    OfferLimitExceededErrorMessageEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  OfferLimitExceededErrorMessageEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => OfferLimitExceededErrorMessageEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$OfferLimitExceededErrorHttpStatusCodeEnumSerializer
    implements PrimitiveSerializer<OfferLimitExceededErrorHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number404': 404,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    404: 'number404',
  };

  @override
  final Iterable<Type> types = const <Type>[
    OfferLimitExceededErrorHttpStatusCodeEnum,
  ];
  @override
  final String wireName = 'OfferLimitExceededErrorHttpStatusCodeEnum';

  @override
  Object serialize(
    Serializers serializers,
    OfferLimitExceededErrorHttpStatusCodeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  OfferLimitExceededErrorHttpStatusCodeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => OfferLimitExceededErrorHttpStatusCodeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$OfferLimitExceededError extends OfferLimitExceededError {
  @override
  final OfferLimitExceededErrorNameEnum name;
  @override
  final OfferLimitExceededErrorMessageEnum message;
  @override
  final OfferLimitExceededErrorHttpStatusCodeEnum httpStatusCode;
  @override
  final String traceId;
  @override
  final BuiltList<NotFoundErrorDetailsInner>? details;

  factory _$OfferLimitExceededError([
    void Function(OfferLimitExceededErrorBuilder)? updates,
  ]) => (OfferLimitExceededErrorBuilder()..update(updates))._build();

  _$OfferLimitExceededError._({
    required this.name,
    required this.message,
    required this.httpStatusCode,
    required this.traceId,
    this.details,
  }) : super._();
  @override
  OfferLimitExceededError rebuild(
    void Function(OfferLimitExceededErrorBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  OfferLimitExceededErrorBuilder toBuilder() =>
      OfferLimitExceededErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OfferLimitExceededError &&
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
    return (newBuiltValueToStringHelper(r'OfferLimitExceededError')
          ..add('name', name)
          ..add('message', message)
          ..add('httpStatusCode', httpStatusCode)
          ..add('traceId', traceId)
          ..add('details', details))
        .toString();
  }
}

class OfferLimitExceededErrorBuilder
    implements
        Builder<OfferLimitExceededError, OfferLimitExceededErrorBuilder> {
  _$OfferLimitExceededError? _$v;

  OfferLimitExceededErrorNameEnum? _name;
  OfferLimitExceededErrorNameEnum? get name => _$this._name;
  set name(OfferLimitExceededErrorNameEnum? name) => _$this._name = name;

  OfferLimitExceededErrorMessageEnum? _message;
  OfferLimitExceededErrorMessageEnum? get message => _$this._message;
  set message(OfferLimitExceededErrorMessageEnum? message) =>
      _$this._message = message;

  OfferLimitExceededErrorHttpStatusCodeEnum? _httpStatusCode;
  OfferLimitExceededErrorHttpStatusCodeEnum? get httpStatusCode =>
      _$this._httpStatusCode;
  set httpStatusCode(
    OfferLimitExceededErrorHttpStatusCodeEnum? httpStatusCode,
  ) => _$this._httpStatusCode = httpStatusCode;

  String? _traceId;
  String? get traceId => _$this._traceId;
  set traceId(String? traceId) => _$this._traceId = traceId;

  ListBuilder<NotFoundErrorDetailsInner>? _details;
  ListBuilder<NotFoundErrorDetailsInner> get details =>
      _$this._details ??= ListBuilder<NotFoundErrorDetailsInner>();
  set details(ListBuilder<NotFoundErrorDetailsInner>? details) =>
      _$this._details = details;

  OfferLimitExceededErrorBuilder() {
    OfferLimitExceededError._defaults(this);
  }

  OfferLimitExceededErrorBuilder get _$this {
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
  void replace(OfferLimitExceededError other) {
    _$v = other as _$OfferLimitExceededError;
  }

  @override
  void update(void Function(OfferLimitExceededErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OfferLimitExceededError build() => _build();

  _$OfferLimitExceededError _build() {
    _$OfferLimitExceededError _$result;
    try {
      _$result =
          _$v ??
          _$OfferLimitExceededError._(
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'OfferLimitExceededError',
              'name',
            ),
            message: BuiltValueNullFieldError.checkNotNull(
              message,
              r'OfferLimitExceededError',
              'message',
            ),
            httpStatusCode: BuiltValueNullFieldError.checkNotNull(
              httpStatusCode,
              r'OfferLimitExceededError',
              'httpStatusCode',
            ),
            traceId: BuiltValueNullFieldError.checkNotNull(
              traceId,
              r'OfferLimitExceededError',
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
          r'OfferLimitExceededError',
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

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_phrase_in_use_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const OfferPhraseInUseErrorNameEnum
    _$offerPhraseInUseErrorNameEnum_offerPhraseInUseError =
    const OfferPhraseInUseErrorNameEnum._('offerPhraseInUseError');

OfferPhraseInUseErrorNameEnum _$offerPhraseInUseErrorNameEnumValueOf(
    String name) {
  switch (name) {
    case 'offerPhraseInUseError':
      return _$offerPhraseInUseErrorNameEnum_offerPhraseInUseError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<OfferPhraseInUseErrorNameEnum>
    _$offerPhraseInUseErrorNameEnumValues = BuiltSet<
        OfferPhraseInUseErrorNameEnum>(const <OfferPhraseInUseErrorNameEnum>[
  _$offerPhraseInUseErrorNameEnum_offerPhraseInUseError,
]);

const OfferPhraseInUseErrorMessageEnum
    _$offerPhraseInUseErrorMessageEnum_theOfferPhraseIsAlreadyInUseByAnotherOffer =
    const OfferPhraseInUseErrorMessageEnum._(
        'theOfferPhraseIsAlreadyInUseByAnotherOffer');

OfferPhraseInUseErrorMessageEnum _$offerPhraseInUseErrorMessageEnumValueOf(
    String name) {
  switch (name) {
    case 'theOfferPhraseIsAlreadyInUseByAnotherOffer':
      return _$offerPhraseInUseErrorMessageEnum_theOfferPhraseIsAlreadyInUseByAnotherOffer;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<OfferPhraseInUseErrorMessageEnum>
    _$offerPhraseInUseErrorMessageEnumValues = BuiltSet<
        OfferPhraseInUseErrorMessageEnum>(const <OfferPhraseInUseErrorMessageEnum>[
  _$offerPhraseInUseErrorMessageEnum_theOfferPhraseIsAlreadyInUseByAnotherOffer,
]);

const OfferPhraseInUseErrorHttpStatusCodeEnum
    _$offerPhraseInUseErrorHttpStatusCodeEnum_number409 =
    const OfferPhraseInUseErrorHttpStatusCodeEnum._('number409');

OfferPhraseInUseErrorHttpStatusCodeEnum
    _$offerPhraseInUseErrorHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'number409':
      return _$offerPhraseInUseErrorHttpStatusCodeEnum_number409;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<OfferPhraseInUseErrorHttpStatusCodeEnum>
    _$offerPhraseInUseErrorHttpStatusCodeEnumValues = BuiltSet<
        OfferPhraseInUseErrorHttpStatusCodeEnum>(const <OfferPhraseInUseErrorHttpStatusCodeEnum>[
  _$offerPhraseInUseErrorHttpStatusCodeEnum_number409,
]);

Serializer<OfferPhraseInUseErrorNameEnum>
    _$offerPhraseInUseErrorNameEnumSerializer =
    _$OfferPhraseInUseErrorNameEnumSerializer();
Serializer<OfferPhraseInUseErrorMessageEnum>
    _$offerPhraseInUseErrorMessageEnumSerializer =
    _$OfferPhraseInUseErrorMessageEnumSerializer();
Serializer<OfferPhraseInUseErrorHttpStatusCodeEnum>
    _$offerPhraseInUseErrorHttpStatusCodeEnumSerializer =
    _$OfferPhraseInUseErrorHttpStatusCodeEnumSerializer();

class _$OfferPhraseInUseErrorNameEnumSerializer
    implements PrimitiveSerializer<OfferPhraseInUseErrorNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'offerPhraseInUseError': 'OfferPhraseInUseError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'OfferPhraseInUseError': 'offerPhraseInUseError',
  };

  @override
  final Iterable<Type> types = const <Type>[OfferPhraseInUseErrorNameEnum];
  @override
  final String wireName = 'OfferPhraseInUseErrorNameEnum';

  @override
  Object serialize(
          Serializers serializers, OfferPhraseInUseErrorNameEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  OfferPhraseInUseErrorNameEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      OfferPhraseInUseErrorNameEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$OfferPhraseInUseErrorMessageEnumSerializer
    implements PrimitiveSerializer<OfferPhraseInUseErrorMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'theOfferPhraseIsAlreadyInUseByAnotherOffer':
        'The offer phrase is already in use by another offer',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'The offer phrase is already in use by another offer':
        'theOfferPhraseIsAlreadyInUseByAnotherOffer',
  };

  @override
  final Iterable<Type> types = const <Type>[OfferPhraseInUseErrorMessageEnum];
  @override
  final String wireName = 'OfferPhraseInUseErrorMessageEnum';

  @override
  Object serialize(
          Serializers serializers, OfferPhraseInUseErrorMessageEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  OfferPhraseInUseErrorMessageEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      OfferPhraseInUseErrorMessageEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$OfferPhraseInUseErrorHttpStatusCodeEnumSerializer
    implements PrimitiveSerializer<OfferPhraseInUseErrorHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number409': 409,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    409: 'number409',
  };

  @override
  final Iterable<Type> types = const <Type>[
    OfferPhraseInUseErrorHttpStatusCodeEnum
  ];
  @override
  final String wireName = 'OfferPhraseInUseErrorHttpStatusCodeEnum';

  @override
  Object serialize(Serializers serializers,
          OfferPhraseInUseErrorHttpStatusCodeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  OfferPhraseInUseErrorHttpStatusCodeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      OfferPhraseInUseErrorHttpStatusCodeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$OfferPhraseInUseError extends OfferPhraseInUseError {
  @override
  final OfferPhraseInUseErrorNameEnum name;
  @override
  final OfferPhraseInUseErrorMessageEnum message;
  @override
  final OfferPhraseInUseErrorHttpStatusCodeEnum httpStatusCode;
  @override
  final String traceId;
  @override
  final BuiltList<NotFoundErrorDetailsInner>? details;

  factory _$OfferPhraseInUseError(
          [void Function(OfferPhraseInUseErrorBuilder)? updates]) =>
      (OfferPhraseInUseErrorBuilder()..update(updates))._build();

  _$OfferPhraseInUseError._(
      {required this.name,
      required this.message,
      required this.httpStatusCode,
      required this.traceId,
      this.details})
      : super._();
  @override
  OfferPhraseInUseError rebuild(
          void Function(OfferPhraseInUseErrorBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OfferPhraseInUseErrorBuilder toBuilder() =>
      OfferPhraseInUseErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OfferPhraseInUseError &&
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
    return (newBuiltValueToStringHelper(r'OfferPhraseInUseError')
          ..add('name', name)
          ..add('message', message)
          ..add('httpStatusCode', httpStatusCode)
          ..add('traceId', traceId)
          ..add('details', details))
        .toString();
  }
}

class OfferPhraseInUseErrorBuilder
    implements Builder<OfferPhraseInUseError, OfferPhraseInUseErrorBuilder> {
  _$OfferPhraseInUseError? _$v;

  OfferPhraseInUseErrorNameEnum? _name;
  OfferPhraseInUseErrorNameEnum? get name => _$this._name;
  set name(OfferPhraseInUseErrorNameEnum? name) => _$this._name = name;

  OfferPhraseInUseErrorMessageEnum? _message;
  OfferPhraseInUseErrorMessageEnum? get message => _$this._message;
  set message(OfferPhraseInUseErrorMessageEnum? message) =>
      _$this._message = message;

  OfferPhraseInUseErrorHttpStatusCodeEnum? _httpStatusCode;
  OfferPhraseInUseErrorHttpStatusCodeEnum? get httpStatusCode =>
      _$this._httpStatusCode;
  set httpStatusCode(OfferPhraseInUseErrorHttpStatusCodeEnum? httpStatusCode) =>
      _$this._httpStatusCode = httpStatusCode;

  String? _traceId;
  String? get traceId => _$this._traceId;
  set traceId(String? traceId) => _$this._traceId = traceId;

  ListBuilder<NotFoundErrorDetailsInner>? _details;
  ListBuilder<NotFoundErrorDetailsInner> get details =>
      _$this._details ??= ListBuilder<NotFoundErrorDetailsInner>();
  set details(ListBuilder<NotFoundErrorDetailsInner>? details) =>
      _$this._details = details;

  OfferPhraseInUseErrorBuilder() {
    OfferPhraseInUseError._defaults(this);
  }

  OfferPhraseInUseErrorBuilder get _$this {
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
  void replace(OfferPhraseInUseError other) {
    _$v = other as _$OfferPhraseInUseError;
  }

  @override
  void update(void Function(OfferPhraseInUseErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OfferPhraseInUseError build() => _build();

  _$OfferPhraseInUseError _build() {
    _$OfferPhraseInUseError _$result;
    try {
      _$result = _$v ??
          _$OfferPhraseInUseError._(
            name: BuiltValueNullFieldError.checkNotNull(
                name, r'OfferPhraseInUseError', 'name'),
            message: BuiltValueNullFieldError.checkNotNull(
                message, r'OfferPhraseInUseError', 'message'),
            httpStatusCode: BuiltValueNullFieldError.checkNotNull(
                httpStatusCode, r'OfferPhraseInUseError', 'httpStatusCode'),
            traceId: BuiltValueNullFieldError.checkNotNull(
                traceId, r'OfferPhraseInUseError', 'traceId'),
            details: _details?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'details';
        _details?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'OfferPhraseInUseError', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

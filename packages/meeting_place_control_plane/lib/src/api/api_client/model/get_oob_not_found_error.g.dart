// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_oob_not_found_error.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const GetOobNotFoundErrorNameEnum
_$getOobNotFoundErrorNameEnum_getOobNotFoundError =
    const GetOobNotFoundErrorNameEnum._('getOobNotFoundError');

GetOobNotFoundErrorNameEnum _$getOobNotFoundErrorNameEnumValueOf(String name) {
  switch (name) {
    case 'getOobNotFoundError':
      return _$getOobNotFoundErrorNameEnum_getOobNotFoundError;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetOobNotFoundErrorNameEnum>
_$getOobNotFoundErrorNameEnumValues = BuiltSet<GetOobNotFoundErrorNameEnum>(
  const <GetOobNotFoundErrorNameEnum>[
    _$getOobNotFoundErrorNameEnum_getOobNotFoundError,
  ],
);

const GetOobNotFoundErrorMessageEnum
_$getOobNotFoundErrorMessageEnum_theOobCouldNotBeFound =
    const GetOobNotFoundErrorMessageEnum._('theOobCouldNotBeFound');

GetOobNotFoundErrorMessageEnum _$getOobNotFoundErrorMessageEnumValueOf(
  String name,
) {
  switch (name) {
    case 'theOobCouldNotBeFound':
      return _$getOobNotFoundErrorMessageEnum_theOobCouldNotBeFound;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetOobNotFoundErrorMessageEnum>
_$getOobNotFoundErrorMessageEnumValues =
    BuiltSet<GetOobNotFoundErrorMessageEnum>(
      const <GetOobNotFoundErrorMessageEnum>[
        _$getOobNotFoundErrorMessageEnum_theOobCouldNotBeFound,
      ],
    );

const GetOobNotFoundErrorHttpStatusCodeEnum
_$getOobNotFoundErrorHttpStatusCodeEnum_number404 =
    const GetOobNotFoundErrorHttpStatusCodeEnum._('number404');

GetOobNotFoundErrorHttpStatusCodeEnum
_$getOobNotFoundErrorHttpStatusCodeEnumValueOf(String name) {
  switch (name) {
    case 'number404':
      return _$getOobNotFoundErrorHttpStatusCodeEnum_number404;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetOobNotFoundErrorHttpStatusCodeEnum>
_$getOobNotFoundErrorHttpStatusCodeEnumValues =
    BuiltSet<GetOobNotFoundErrorHttpStatusCodeEnum>(
      const <GetOobNotFoundErrorHttpStatusCodeEnum>[
        _$getOobNotFoundErrorHttpStatusCodeEnum_number404,
      ],
    );

Serializer<GetOobNotFoundErrorNameEnum>
_$getOobNotFoundErrorNameEnumSerializer =
    _$GetOobNotFoundErrorNameEnumSerializer();
Serializer<GetOobNotFoundErrorMessageEnum>
_$getOobNotFoundErrorMessageEnumSerializer =
    _$GetOobNotFoundErrorMessageEnumSerializer();
Serializer<GetOobNotFoundErrorHttpStatusCodeEnum>
_$getOobNotFoundErrorHttpStatusCodeEnumSerializer =
    _$GetOobNotFoundErrorHttpStatusCodeEnumSerializer();

class _$GetOobNotFoundErrorNameEnumSerializer
    implements PrimitiveSerializer<GetOobNotFoundErrorNameEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'getOobNotFoundError': 'GetOobNotFoundError',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'GetOobNotFoundError': 'getOobNotFoundError',
  };

  @override
  final Iterable<Type> types = const <Type>[GetOobNotFoundErrorNameEnum];
  @override
  final String wireName = 'GetOobNotFoundErrorNameEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetOobNotFoundErrorNameEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetOobNotFoundErrorNameEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetOobNotFoundErrorNameEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetOobNotFoundErrorMessageEnumSerializer
    implements PrimitiveSerializer<GetOobNotFoundErrorMessageEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'theOobCouldNotBeFound': 'The oob could not be found',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'The oob could not be found': 'theOobCouldNotBeFound',
  };

  @override
  final Iterable<Type> types = const <Type>[GetOobNotFoundErrorMessageEnum];
  @override
  final String wireName = 'GetOobNotFoundErrorMessageEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetOobNotFoundErrorMessageEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetOobNotFoundErrorMessageEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetOobNotFoundErrorMessageEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetOobNotFoundErrorHttpStatusCodeEnumSerializer
    implements PrimitiveSerializer<GetOobNotFoundErrorHttpStatusCodeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number404': 404,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    404: 'number404',
  };

  @override
  final Iterable<Type> types = const <Type>[
    GetOobNotFoundErrorHttpStatusCodeEnum,
  ];
  @override
  final String wireName = 'GetOobNotFoundErrorHttpStatusCodeEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetOobNotFoundErrorHttpStatusCodeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetOobNotFoundErrorHttpStatusCodeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetOobNotFoundErrorHttpStatusCodeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetOobNotFoundError extends GetOobNotFoundError {
  @override
  final GetOobNotFoundErrorNameEnum name;
  @override
  final GetOobNotFoundErrorMessageEnum message;
  @override
  final GetOobNotFoundErrorHttpStatusCodeEnum httpStatusCode;
  @override
  final String traceId;
  @override
  final BuiltList<NotFoundErrorDetailsInner>? details;

  factory _$GetOobNotFoundError([
    void Function(GetOobNotFoundErrorBuilder)? updates,
  ]) => (GetOobNotFoundErrorBuilder()..update(updates))._build();

  _$GetOobNotFoundError._({
    required this.name,
    required this.message,
    required this.httpStatusCode,
    required this.traceId,
    this.details,
  }) : super._();
  @override
  GetOobNotFoundError rebuild(
    void Function(GetOobNotFoundErrorBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetOobNotFoundErrorBuilder toBuilder() =>
      GetOobNotFoundErrorBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetOobNotFoundError &&
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
    return (newBuiltValueToStringHelper(r'GetOobNotFoundError')
          ..add('name', name)
          ..add('message', message)
          ..add('httpStatusCode', httpStatusCode)
          ..add('traceId', traceId)
          ..add('details', details))
        .toString();
  }
}

class GetOobNotFoundErrorBuilder
    implements Builder<GetOobNotFoundError, GetOobNotFoundErrorBuilder> {
  _$GetOobNotFoundError? _$v;

  GetOobNotFoundErrorNameEnum? _name;
  GetOobNotFoundErrorNameEnum? get name => _$this._name;
  set name(GetOobNotFoundErrorNameEnum? name) => _$this._name = name;

  GetOobNotFoundErrorMessageEnum? _message;
  GetOobNotFoundErrorMessageEnum? get message => _$this._message;
  set message(GetOobNotFoundErrorMessageEnum? message) =>
      _$this._message = message;

  GetOobNotFoundErrorHttpStatusCodeEnum? _httpStatusCode;
  GetOobNotFoundErrorHttpStatusCodeEnum? get httpStatusCode =>
      _$this._httpStatusCode;
  set httpStatusCode(GetOobNotFoundErrorHttpStatusCodeEnum? httpStatusCode) =>
      _$this._httpStatusCode = httpStatusCode;

  String? _traceId;
  String? get traceId => _$this._traceId;
  set traceId(String? traceId) => _$this._traceId = traceId;

  ListBuilder<NotFoundErrorDetailsInner>? _details;
  ListBuilder<NotFoundErrorDetailsInner> get details =>
      _$this._details ??= ListBuilder<NotFoundErrorDetailsInner>();
  set details(ListBuilder<NotFoundErrorDetailsInner>? details) =>
      _$this._details = details;

  GetOobNotFoundErrorBuilder() {
    GetOobNotFoundError._defaults(this);
  }

  GetOobNotFoundErrorBuilder get _$this {
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
  void replace(GetOobNotFoundError other) {
    _$v = other as _$GetOobNotFoundError;
  }

  @override
  void update(void Function(GetOobNotFoundErrorBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GetOobNotFoundError build() => _build();

  _$GetOobNotFoundError _build() {
    _$GetOobNotFoundError _$result;
    try {
      _$result =
          _$v ??
          _$GetOobNotFoundError._(
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'GetOobNotFoundError',
              'name',
            ),
            message: BuiltValueNullFieldError.checkNotNull(
              message,
              r'GetOobNotFoundError',
              'message',
            ),
            httpStatusCode: BuiltValueNullFieldError.checkNotNull(
              httpStatusCode,
              r'GetOobNotFoundError',
              'httpStatusCode',
            ),
            traceId: BuiltValueNullFieldError.checkNotNull(
              traceId,
              r'GetOobNotFoundError',
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
          r'GetOobNotFoundError',
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

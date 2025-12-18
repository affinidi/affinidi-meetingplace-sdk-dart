// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_device_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RegisterDeviceInputPlatformTypeEnum
_$registerDeviceInputPlatformTypeEnum_DIDCOMM =
    const RegisterDeviceInputPlatformTypeEnum._('DIDCOMM');
const RegisterDeviceInputPlatformTypeEnum
_$registerDeviceInputPlatformTypeEnum_PUSH_NOTIFICATION =
    const RegisterDeviceInputPlatformTypeEnum._('PUSH_NOTIFICATION');
const RegisterDeviceInputPlatformTypeEnum
_$registerDeviceInputPlatformTypeEnum_NONE =
    const RegisterDeviceInputPlatformTypeEnum._('NONE');

RegisterDeviceInputPlatformTypeEnum
_$registerDeviceInputPlatformTypeEnumValueOf(String name) {
  switch (name) {
    case 'DIDCOMM':
      return _$registerDeviceInputPlatformTypeEnum_DIDCOMM;
    case 'PUSH_NOTIFICATION':
      return _$registerDeviceInputPlatformTypeEnum_PUSH_NOTIFICATION;
    case 'NONE':
      return _$registerDeviceInputPlatformTypeEnum_NONE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RegisterDeviceInputPlatformTypeEnum>
_$registerDeviceInputPlatformTypeEnumValues =
    BuiltSet<RegisterDeviceInputPlatformTypeEnum>(
      const <RegisterDeviceInputPlatformTypeEnum>[
        _$registerDeviceInputPlatformTypeEnum_DIDCOMM,
        _$registerDeviceInputPlatformTypeEnum_PUSH_NOTIFICATION,
        _$registerDeviceInputPlatformTypeEnum_NONE,
      ],
    );

Serializer<RegisterDeviceInputPlatformTypeEnum>
_$registerDeviceInputPlatformTypeEnumSerializer =
    _$RegisterDeviceInputPlatformTypeEnumSerializer();

class _$RegisterDeviceInputPlatformTypeEnumSerializer
    implements PrimitiveSerializer<RegisterDeviceInputPlatformTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'DIDCOMM': 'DIDCOMM',
    'PUSH_NOTIFICATION': 'PUSH_NOTIFICATION',
    'NONE': 'NONE',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'DIDCOMM': 'DIDCOMM',
    'PUSH_NOTIFICATION': 'PUSH_NOTIFICATION',
    'NONE': 'NONE',
  };

  @override
  final Iterable<Type> types = const <Type>[
    RegisterDeviceInputPlatformTypeEnum,
  ];
  @override
  final String wireName = 'RegisterDeviceInputPlatformTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    RegisterDeviceInputPlatformTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RegisterDeviceInputPlatformTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RegisterDeviceInputPlatformTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$RegisterDeviceInput extends RegisterDeviceInput {
  @override
  final RegisterDeviceInputPlatformTypeEnum platformType;
  @override
  final String deviceToken;

  factory _$RegisterDeviceInput([
    void Function(RegisterDeviceInputBuilder)? updates,
  ]) => (RegisterDeviceInputBuilder()..update(updates))._build();

  _$RegisterDeviceInput._({
    required this.platformType,
    required this.deviceToken,
  }) : super._();
  @override
  RegisterDeviceInput rebuild(
    void Function(RegisterDeviceInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RegisterDeviceInputBuilder toBuilder() =>
      RegisterDeviceInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterDeviceInput &&
        platformType == other.platformType &&
        deviceToken == other.deviceToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, platformType.hashCode);
    _$hash = $jc(_$hash, deviceToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterDeviceInput')
          ..add('platformType', platformType)
          ..add('deviceToken', deviceToken))
        .toString();
  }
}

class RegisterDeviceInputBuilder
    implements Builder<RegisterDeviceInput, RegisterDeviceInputBuilder> {
  _$RegisterDeviceInput? _$v;

  RegisterDeviceInputPlatformTypeEnum? _platformType;
  RegisterDeviceInputPlatformTypeEnum? get platformType => _$this._platformType;
  set platformType(RegisterDeviceInputPlatformTypeEnum? platformType) =>
      _$this._platformType = platformType;

  String? _deviceToken;
  String? get deviceToken => _$this._deviceToken;
  set deviceToken(String? deviceToken) => _$this._deviceToken = deviceToken;

  RegisterDeviceInputBuilder() {
    RegisterDeviceInput._defaults(this);
  }

  RegisterDeviceInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _platformType = $v.platformType;
      _deviceToken = $v.deviceToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterDeviceInput other) {
    _$v = other as _$RegisterDeviceInput;
  }

  @override
  void update(void Function(RegisterDeviceInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterDeviceInput build() => _build();

  _$RegisterDeviceInput _build() {
    final _$result =
        _$v ??
        _$RegisterDeviceInput._(
          platformType: BuiltValueNullFieldError.checkNotNull(
            platformType,
            r'RegisterDeviceInput',
            'platformType',
          ),
          deviceToken: BuiltValueNullFieldError.checkNotNull(
            deviceToken,
            r'RegisterDeviceInput',
            'deviceToken',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

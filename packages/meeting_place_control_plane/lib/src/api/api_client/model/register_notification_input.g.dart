// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_notification_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RegisterNotificationInputPlatformTypeEnum
    _$registerNotificationInputPlatformTypeEnum_DIDCOMM =
    const RegisterNotificationInputPlatformTypeEnum._('DIDCOMM');
const RegisterNotificationInputPlatformTypeEnum
    _$registerNotificationInputPlatformTypeEnum_PUSH_NOTIFICATION =
    const RegisterNotificationInputPlatformTypeEnum._('PUSH_NOTIFICATION');
const RegisterNotificationInputPlatformTypeEnum
    _$registerNotificationInputPlatformTypeEnum_NONE =
    const RegisterNotificationInputPlatformTypeEnum._('NONE');

RegisterNotificationInputPlatformTypeEnum
    _$registerNotificationInputPlatformTypeEnumValueOf(String name) {
  switch (name) {
    case 'DIDCOMM':
      return _$registerNotificationInputPlatformTypeEnum_DIDCOMM;
    case 'PUSH_NOTIFICATION':
      return _$registerNotificationInputPlatformTypeEnum_PUSH_NOTIFICATION;
    case 'NONE':
      return _$registerNotificationInputPlatformTypeEnum_NONE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RegisterNotificationInputPlatformTypeEnum>
    _$registerNotificationInputPlatformTypeEnumValues = BuiltSet<
        RegisterNotificationInputPlatformTypeEnum>(const <RegisterNotificationInputPlatformTypeEnum>[
  _$registerNotificationInputPlatformTypeEnum_DIDCOMM,
  _$registerNotificationInputPlatformTypeEnum_PUSH_NOTIFICATION,
  _$registerNotificationInputPlatformTypeEnum_NONE,
]);

Serializer<RegisterNotificationInputPlatformTypeEnum>
    _$registerNotificationInputPlatformTypeEnumSerializer =
    _$RegisterNotificationInputPlatformTypeEnumSerializer();

class _$RegisterNotificationInputPlatformTypeEnumSerializer
    implements PrimitiveSerializer<RegisterNotificationInputPlatformTypeEnum> {
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
    RegisterNotificationInputPlatformTypeEnum
  ];
  @override
  final String wireName = 'RegisterNotificationInputPlatformTypeEnum';

  @override
  Object serialize(Serializers serializers,
          RegisterNotificationInputPlatformTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  RegisterNotificationInputPlatformTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      RegisterNotificationInputPlatformTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$RegisterNotificationInput extends RegisterNotificationInput {
  @override
  final String myDid;
  @override
  final String theirDid;
  @override
  final String deviceToken;
  @override
  final RegisterNotificationInputPlatformTypeEnum platformType;

  factory _$RegisterNotificationInput(
          [void Function(RegisterNotificationInputBuilder)? updates]) =>
      (RegisterNotificationInputBuilder()..update(updates))._build();

  _$RegisterNotificationInput._(
      {required this.myDid,
      required this.theirDid,
      required this.deviceToken,
      required this.platformType})
      : super._();
  @override
  RegisterNotificationInput rebuild(
          void Function(RegisterNotificationInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegisterNotificationInputBuilder toBuilder() =>
      RegisterNotificationInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterNotificationInput &&
        myDid == other.myDid &&
        theirDid == other.theirDid &&
        deviceToken == other.deviceToken &&
        platformType == other.platformType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, myDid.hashCode);
    _$hash = $jc(_$hash, theirDid.hashCode);
    _$hash = $jc(_$hash, deviceToken.hashCode);
    _$hash = $jc(_$hash, platformType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterNotificationInput')
          ..add('myDid', myDid)
          ..add('theirDid', theirDid)
          ..add('deviceToken', deviceToken)
          ..add('platformType', platformType))
        .toString();
  }
}

class RegisterNotificationInputBuilder
    implements
        Builder<RegisterNotificationInput, RegisterNotificationInputBuilder> {
  _$RegisterNotificationInput? _$v;

  String? _myDid;
  String? get myDid => _$this._myDid;
  set myDid(String? myDid) => _$this._myDid = myDid;

  String? _theirDid;
  String? get theirDid => _$this._theirDid;
  set theirDid(String? theirDid) => _$this._theirDid = theirDid;

  String? _deviceToken;
  String? get deviceToken => _$this._deviceToken;
  set deviceToken(String? deviceToken) => _$this._deviceToken = deviceToken;

  RegisterNotificationInputPlatformTypeEnum? _platformType;
  RegisterNotificationInputPlatformTypeEnum? get platformType =>
      _$this._platformType;
  set platformType(RegisterNotificationInputPlatformTypeEnum? platformType) =>
      _$this._platformType = platformType;

  RegisterNotificationInputBuilder() {
    RegisterNotificationInput._defaults(this);
  }

  RegisterNotificationInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _myDid = $v.myDid;
      _theirDid = $v.theirDid;
      _deviceToken = $v.deviceToken;
      _platformType = $v.platformType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterNotificationInput other) {
    _$v = other as _$RegisterNotificationInput;
  }

  @override
  void update(void Function(RegisterNotificationInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterNotificationInput build() => _build();

  _$RegisterNotificationInput _build() {
    final _$result = _$v ??
        _$RegisterNotificationInput._(
          myDid: BuiltValueNullFieldError.checkNotNull(
              myDid, r'RegisterNotificationInput', 'myDid'),
          theirDid: BuiltValueNullFieldError.checkNotNull(
              theirDid, r'RegisterNotificationInput', 'theirDid'),
          deviceToken: BuiltValueNullFieldError.checkNotNull(
              deviceToken, r'RegisterNotificationInput', 'deviceToken'),
          platformType: BuiltValueNullFieldError.checkNotNull(
              platformType, r'RegisterNotificationInput', 'platformType'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

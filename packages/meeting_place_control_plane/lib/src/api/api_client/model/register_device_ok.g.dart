// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_device_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RegisterDeviceOK extends RegisterDeviceOK {
  @override
  final String? status;
  @override
  final String? message;
  @override
  final String deviceToken;
  @override
  final String platformType;

  factory _$RegisterDeviceOK(
          [void Function(RegisterDeviceOKBuilder)? updates]) =>
      (RegisterDeviceOKBuilder()..update(updates))._build();

  _$RegisterDeviceOK._(
      {this.status,
      this.message,
      required this.deviceToken,
      required this.platformType})
      : super._();
  @override
  RegisterDeviceOK rebuild(void Function(RegisterDeviceOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegisterDeviceOKBuilder toBuilder() =>
      RegisterDeviceOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterDeviceOK &&
        status == other.status &&
        message == other.message &&
        deviceToken == other.deviceToken &&
        platformType == other.platformType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, deviceToken.hashCode);
    _$hash = $jc(_$hash, platformType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterDeviceOK')
          ..add('status', status)
          ..add('message', message)
          ..add('deviceToken', deviceToken)
          ..add('platformType', platformType))
        .toString();
  }
}

class RegisterDeviceOKBuilder
    implements Builder<RegisterDeviceOK, RegisterDeviceOKBuilder> {
  _$RegisterDeviceOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  String? _deviceToken;
  String? get deviceToken => _$this._deviceToken;
  set deviceToken(String? deviceToken) => _$this._deviceToken = deviceToken;

  String? _platformType;
  String? get platformType => _$this._platformType;
  set platformType(String? platformType) => _$this._platformType = platformType;

  RegisterDeviceOKBuilder() {
    RegisterDeviceOK._defaults(this);
  }

  RegisterDeviceOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _deviceToken = $v.deviceToken;
      _platformType = $v.platformType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterDeviceOK other) {
    _$v = other as _$RegisterDeviceOK;
  }

  @override
  void update(void Function(RegisterDeviceOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterDeviceOK build() => _build();

  _$RegisterDeviceOK _build() {
    final _$result = _$v ??
        _$RegisterDeviceOK._(
          status: status,
          message: message,
          deviceToken: BuiltValueNullFieldError.checkNotNull(
              deviceToken, r'RegisterDeviceOK', 'deviceToken'),
          platformType: BuiltValueNullFieldError.checkNotNull(
              platformType, r'RegisterDeviceOK', 'platformType'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

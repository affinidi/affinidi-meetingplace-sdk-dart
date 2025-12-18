// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_notification_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RegisterNotificationOK extends RegisterNotificationOK {
  @override
  final String notificationToken;

  factory _$RegisterNotificationOK([
    void Function(RegisterNotificationOKBuilder)? updates,
  ]) => (RegisterNotificationOKBuilder()..update(updates))._build();

  _$RegisterNotificationOK._({required this.notificationToken}) : super._();
  @override
  RegisterNotificationOK rebuild(
    void Function(RegisterNotificationOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RegisterNotificationOKBuilder toBuilder() =>
      RegisterNotificationOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterNotificationOK &&
        notificationToken == other.notificationToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, notificationToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'RegisterNotificationOK',
    )..add('notificationToken', notificationToken)).toString();
  }
}

class RegisterNotificationOKBuilder
    implements Builder<RegisterNotificationOK, RegisterNotificationOKBuilder> {
  _$RegisterNotificationOK? _$v;

  String? _notificationToken;
  String? get notificationToken => _$this._notificationToken;
  set notificationToken(String? notificationToken) =>
      _$this._notificationToken = notificationToken;

  RegisterNotificationOKBuilder() {
    RegisterNotificationOK._defaults(this);
  }

  RegisterNotificationOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _notificationToken = $v.notificationToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterNotificationOK other) {
    _$v = other as _$RegisterNotificationOK;
  }

  @override
  void update(void Function(RegisterNotificationOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterNotificationOK build() => _build();

  _$RegisterNotificationOK _build() {
    final _$result =
        _$v ??
        _$RegisterNotificationOK._(
          notificationToken: BuiltValueNullFieldError.checkNotNull(
            notificationToken,
            r'RegisterNotificationOK',
            'notificationToken',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

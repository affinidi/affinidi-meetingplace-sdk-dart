// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deregister_notification_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeregisterNotificationInput extends DeregisterNotificationInput {
  @override
  final String notificationToken;

  factory _$DeregisterNotificationInput([
    void Function(DeregisterNotificationInputBuilder)? updates,
  ]) => (DeregisterNotificationInputBuilder()..update(updates))._build();

  _$DeregisterNotificationInput._({required this.notificationToken})
    : super._();
  @override
  DeregisterNotificationInput rebuild(
    void Function(DeregisterNotificationInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DeregisterNotificationInputBuilder toBuilder() =>
      DeregisterNotificationInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeregisterNotificationInput &&
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
      r'DeregisterNotificationInput',
    )..add('notificationToken', notificationToken)).toString();
  }
}

class DeregisterNotificationInputBuilder
    implements
        Builder<
          DeregisterNotificationInput,
          DeregisterNotificationInputBuilder
        > {
  _$DeregisterNotificationInput? _$v;

  String? _notificationToken;
  String? get notificationToken => _$this._notificationToken;
  set notificationToken(String? notificationToken) =>
      _$this._notificationToken = notificationToken;

  DeregisterNotificationInputBuilder() {
    DeregisterNotificationInput._defaults(this);
  }

  DeregisterNotificationInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _notificationToken = $v.notificationToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeregisterNotificationInput other) {
    _$v = other as _$DeregisterNotificationInput;
  }

  @override
  void update(void Function(DeregisterNotificationInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeregisterNotificationInput build() => _build();

  _$DeregisterNotificationInput _build() {
    final _$result =
        _$v ??
        _$DeregisterNotificationInput._(
          notificationToken: BuiltValueNullFieldError.checkNotNull(
            notificationToken,
            r'DeregisterNotificationInput',
            'notificationToken',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

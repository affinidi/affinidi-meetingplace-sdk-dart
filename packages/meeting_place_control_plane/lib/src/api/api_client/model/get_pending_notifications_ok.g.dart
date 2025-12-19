// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_pending_notifications_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetPendingNotificationsOK extends GetPendingNotificationsOK {
  @override
  final BuiltList<GetPendingNotificationsOKNotificationsInner>? notifications;

  factory _$GetPendingNotificationsOK([
    void Function(GetPendingNotificationsOKBuilder)? updates,
  ]) => (GetPendingNotificationsOKBuilder()..update(updates))._build();

  _$GetPendingNotificationsOK._({this.notifications}) : super._();
  @override
  GetPendingNotificationsOK rebuild(
    void Function(GetPendingNotificationsOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetPendingNotificationsOKBuilder toBuilder() =>
      GetPendingNotificationsOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetPendingNotificationsOK &&
        notifications == other.notifications;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, notifications.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'GetPendingNotificationsOK',
    )..add('notifications', notifications)).toString();
  }
}

class GetPendingNotificationsOKBuilder
    implements
        Builder<GetPendingNotificationsOK, GetPendingNotificationsOKBuilder> {
  _$GetPendingNotificationsOK? _$v;

  ListBuilder<GetPendingNotificationsOKNotificationsInner>? _notifications;
  ListBuilder<GetPendingNotificationsOKNotificationsInner> get notifications =>
      _$this._notifications ??=
          ListBuilder<GetPendingNotificationsOKNotificationsInner>();
  set notifications(
    ListBuilder<GetPendingNotificationsOKNotificationsInner>? notifications,
  ) => _$this._notifications = notifications;

  GetPendingNotificationsOKBuilder() {
    GetPendingNotificationsOK._defaults(this);
  }

  GetPendingNotificationsOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _notifications = $v.notifications?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetPendingNotificationsOK other) {
    _$v = other as _$GetPendingNotificationsOK;
  }

  @override
  void update(void Function(GetPendingNotificationsOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GetPendingNotificationsOK build() => _build();

  _$GetPendingNotificationsOK _build() {
    _$GetPendingNotificationsOK _$result;
    try {
      _$result =
          _$v ??
          _$GetPendingNotificationsOK._(notifications: _notifications?.build());
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'notifications';
        _notifications?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'GetPendingNotificationsOK',
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

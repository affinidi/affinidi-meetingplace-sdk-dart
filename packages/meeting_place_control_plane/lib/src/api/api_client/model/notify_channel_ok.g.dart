// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_channel_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyChannelOK extends NotifyChannelOK {
  @override
  final String notificationId;

  factory _$NotifyChannelOK([void Function(NotifyChannelOKBuilder)? updates]) =>
      (NotifyChannelOKBuilder()..update(updates))._build();

  _$NotifyChannelOK._({required this.notificationId}) : super._();
  @override
  NotifyChannelOK rebuild(void Function(NotifyChannelOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotifyChannelOKBuilder toBuilder() => NotifyChannelOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyChannelOK && notificationId == other.notificationId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, notificationId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyChannelOK')
          ..add('notificationId', notificationId))
        .toString();
  }
}

class NotifyChannelOKBuilder
    implements Builder<NotifyChannelOK, NotifyChannelOKBuilder> {
  _$NotifyChannelOK? _$v;

  String? _notificationId;
  String? get notificationId => _$this._notificationId;
  set notificationId(String? notificationId) =>
      _$this._notificationId = notificationId;

  NotifyChannelOKBuilder() {
    NotifyChannelOK._defaults(this);
  }

  NotifyChannelOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _notificationId = $v.notificationId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyChannelOK other) {
    _$v = other as _$NotifyChannelOK;
  }

  @override
  void update(void Function(NotifyChannelOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyChannelOK build() => _build();

  _$NotifyChannelOK _build() {
    final _$result = _$v ??
        _$NotifyChannelOK._(
          notificationId: BuiltValueNullFieldError.checkNotNull(
              notificationId, r'NotifyChannelOK', 'notificationId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

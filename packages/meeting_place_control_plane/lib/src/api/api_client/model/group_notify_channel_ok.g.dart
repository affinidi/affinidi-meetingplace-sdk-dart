// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_notify_channel_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupNotifyChannelOK extends GroupNotifyChannelOK {
  @override
  final String? status;
  @override
  final String? message;

  factory _$GroupNotifyChannelOK([
    void Function(GroupNotifyChannelOKBuilder)? updates,
  ]) => (GroupNotifyChannelOKBuilder()..update(updates))._build();

  _$GroupNotifyChannelOK._({this.status, this.message}) : super._();
  @override
  GroupNotifyChannelOK rebuild(
    void Function(GroupNotifyChannelOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GroupNotifyChannelOKBuilder toBuilder() =>
      GroupNotifyChannelOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupNotifyChannelOK &&
        status == other.status &&
        message == other.message;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GroupNotifyChannelOK')
          ..add('status', status)
          ..add('message', message))
        .toString();
  }
}

class GroupNotifyChannelOKBuilder
    implements Builder<GroupNotifyChannelOK, GroupNotifyChannelOKBuilder> {
  _$GroupNotifyChannelOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  GroupNotifyChannelOKBuilder() {
    GroupNotifyChannelOK._defaults(this);
  }

  GroupNotifyChannelOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupNotifyChannelOK other) {
    _$v = other as _$GroupNotifyChannelOK;
  }

  @override
  void update(void Function(GroupNotifyChannelOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupNotifyChannelOK build() => _build();

  _$GroupNotifyChannelOK _build() {
    final _$result =
        _$v ?? _$GroupNotifyChannelOK._(status: status, message: message);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

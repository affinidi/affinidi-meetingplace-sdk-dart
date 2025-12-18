// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_deregister_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupMemberDeregisterOK extends GroupMemberDeregisterOK {
  @override
  final String? status;
  @override
  final String? message;

  factory _$GroupMemberDeregisterOK([
    void Function(GroupMemberDeregisterOKBuilder)? updates,
  ]) => (GroupMemberDeregisterOKBuilder()..update(updates))._build();

  _$GroupMemberDeregisterOK._({this.status, this.message}) : super._();
  @override
  GroupMemberDeregisterOK rebuild(
    void Function(GroupMemberDeregisterOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GroupMemberDeregisterOKBuilder toBuilder() =>
      GroupMemberDeregisterOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupMemberDeregisterOK &&
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
    return (newBuiltValueToStringHelper(r'GroupMemberDeregisterOK')
          ..add('status', status)
          ..add('message', message))
        .toString();
  }
}

class GroupMemberDeregisterOKBuilder
    implements
        Builder<GroupMemberDeregisterOK, GroupMemberDeregisterOKBuilder> {
  _$GroupMemberDeregisterOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  GroupMemberDeregisterOKBuilder() {
    GroupMemberDeregisterOK._defaults(this);
  }

  GroupMemberDeregisterOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupMemberDeregisterOK other) {
    _$v = other as _$GroupMemberDeregisterOK;
  }

  @override
  void update(void Function(GroupMemberDeregisterOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupMemberDeregisterOK build() => _build();

  _$GroupMemberDeregisterOK _build() {
    final _$result =
        _$v ?? _$GroupMemberDeregisterOK._(status: status, message: message);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

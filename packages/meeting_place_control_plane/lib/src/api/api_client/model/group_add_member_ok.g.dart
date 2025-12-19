// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_add_member_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupAddMemberOK extends GroupAddMemberOK {
  @override
  final String? status;
  @override
  final String? message;

  factory _$GroupAddMemberOK([
    void Function(GroupAddMemberOKBuilder)? updates,
  ]) => (GroupAddMemberOKBuilder()..update(updates))._build();

  _$GroupAddMemberOK._({this.status, this.message}) : super._();
  @override
  GroupAddMemberOK rebuild(void Function(GroupAddMemberOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GroupAddMemberOKBuilder toBuilder() =>
      GroupAddMemberOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupAddMemberOK &&
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
    return (newBuiltValueToStringHelper(r'GroupAddMemberOK')
          ..add('status', status)
          ..add('message', message))
        .toString();
  }
}

class GroupAddMemberOKBuilder
    implements Builder<GroupAddMemberOK, GroupAddMemberOKBuilder> {
  _$GroupAddMemberOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  GroupAddMemberOKBuilder() {
    GroupAddMemberOK._defaults(this);
  }

  GroupAddMemberOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupAddMemberOK other) {
    _$v = other as _$GroupAddMemberOK;
  }

  @override
  void update(void Function(GroupAddMemberOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupAddMemberOK build() => _build();

  _$GroupAddMemberOK _build() {
    final _$result =
        _$v ?? _$GroupAddMemberOK._(status: status, message: message);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

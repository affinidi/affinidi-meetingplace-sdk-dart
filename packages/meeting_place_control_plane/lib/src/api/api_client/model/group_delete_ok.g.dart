// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_delete_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupDeleteOK extends GroupDeleteOK {
  @override
  final String? status;
  @override
  final String? message;

  factory _$GroupDeleteOK([void Function(GroupDeleteOKBuilder)? updates]) =>
      (GroupDeleteOKBuilder()..update(updates))._build();

  _$GroupDeleteOK._({this.status, this.message}) : super._();
  @override
  GroupDeleteOK rebuild(void Function(GroupDeleteOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GroupDeleteOKBuilder toBuilder() => GroupDeleteOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupDeleteOK &&
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
    return (newBuiltValueToStringHelper(r'GroupDeleteOK')
          ..add('status', status)
          ..add('message', message))
        .toString();
  }
}

class GroupDeleteOKBuilder
    implements Builder<GroupDeleteOK, GroupDeleteOKBuilder> {
  _$GroupDeleteOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  GroupDeleteOKBuilder() {
    GroupDeleteOK._defaults(this);
  }

  GroupDeleteOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupDeleteOK other) {
    _$v = other as _$GroupDeleteOK;
  }

  @override
  void update(void Function(GroupDeleteOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupDeleteOK build() => _build();

  _$GroupDeleteOK _build() {
    final _$result = _$v ??
        _$GroupDeleteOK._(
          status: status,
          message: message,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

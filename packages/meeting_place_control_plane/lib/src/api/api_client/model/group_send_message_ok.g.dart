// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_send_message_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupSendMessageOK extends GroupSendMessageOK {
  @override
  final String? status;
  @override
  final String? message;

  factory _$GroupSendMessageOK([
    void Function(GroupSendMessageOKBuilder)? updates,
  ]) => (GroupSendMessageOKBuilder()..update(updates))._build();

  _$GroupSendMessageOK._({this.status, this.message}) : super._();
  @override
  GroupSendMessageOK rebuild(
    void Function(GroupSendMessageOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GroupSendMessageOKBuilder toBuilder() =>
      GroupSendMessageOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupSendMessageOK &&
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
    return (newBuiltValueToStringHelper(r'GroupSendMessageOK')
          ..add('status', status)
          ..add('message', message))
        .toString();
  }
}

class GroupSendMessageOKBuilder
    implements Builder<GroupSendMessageOK, GroupSendMessageOKBuilder> {
  _$GroupSendMessageOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  GroupSendMessageOKBuilder() {
    GroupSendMessageOK._defaults(this);
  }

  GroupSendMessageOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupSendMessageOK other) {
    _$v = other as _$GroupSendMessageOK;
  }

  @override
  void update(void Function(GroupSendMessageOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupSendMessageOK build() => _build();

  _$GroupSendMessageOK _build() {
    final _$result =
        _$v ?? _$GroupSendMessageOK._(status: status, message: message);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

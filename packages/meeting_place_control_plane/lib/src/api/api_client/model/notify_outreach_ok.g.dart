// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_outreach_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyOutreachOK extends NotifyOutreachOK {
  @override
  final String? status;
  @override
  final String? message;

  factory _$NotifyOutreachOK(
          [void Function(NotifyOutreachOKBuilder)? updates]) =>
      (NotifyOutreachOKBuilder()..update(updates))._build();

  _$NotifyOutreachOK._({this.status, this.message}) : super._();
  @override
  NotifyOutreachOK rebuild(void Function(NotifyOutreachOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotifyOutreachOKBuilder toBuilder() =>
      NotifyOutreachOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyOutreachOK &&
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
    return (newBuiltValueToStringHelper(r'NotifyOutreachOK')
          ..add('status', status)
          ..add('message', message))
        .toString();
  }
}

class NotifyOutreachOKBuilder
    implements Builder<NotifyOutreachOK, NotifyOutreachOKBuilder> {
  _$NotifyOutreachOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  NotifyOutreachOKBuilder() {
    NotifyOutreachOK._defaults(this);
  }

  NotifyOutreachOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyOutreachOK other) {
    _$v = other as _$NotifyOutreachOK;
  }

  @override
  void update(void Function(NotifyOutreachOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyOutreachOK build() => _build();

  _$NotifyOutreachOK _build() {
    final _$result = _$v ??
        _$NotifyOutreachOK._(
          status: status,
          message: message,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

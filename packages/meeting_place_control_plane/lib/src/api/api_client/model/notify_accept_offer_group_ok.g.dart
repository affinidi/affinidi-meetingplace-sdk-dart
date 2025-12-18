// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_accept_offer_group_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyAcceptOfferGroupOK extends NotifyAcceptOfferGroupOK {
  @override
  final String? status;
  @override
  final String? message;

  factory _$NotifyAcceptOfferGroupOK([
    void Function(NotifyAcceptOfferGroupOKBuilder)? updates,
  ]) => (NotifyAcceptOfferGroupOKBuilder()..update(updates))._build();

  _$NotifyAcceptOfferGroupOK._({this.status, this.message}) : super._();
  @override
  NotifyAcceptOfferGroupOK rebuild(
    void Function(NotifyAcceptOfferGroupOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyAcceptOfferGroupOKBuilder toBuilder() =>
      NotifyAcceptOfferGroupOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyAcceptOfferGroupOK &&
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
    return (newBuiltValueToStringHelper(r'NotifyAcceptOfferGroupOK')
          ..add('status', status)
          ..add('message', message))
        .toString();
  }
}

class NotifyAcceptOfferGroupOKBuilder
    implements
        Builder<NotifyAcceptOfferGroupOK, NotifyAcceptOfferGroupOKBuilder> {
  _$NotifyAcceptOfferGroupOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  NotifyAcceptOfferGroupOKBuilder() {
    NotifyAcceptOfferGroupOK._defaults(this);
  }

  NotifyAcceptOfferGroupOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyAcceptOfferGroupOK other) {
    _$v = other as _$NotifyAcceptOfferGroupOK;
  }

  @override
  void update(void Function(NotifyAcceptOfferGroupOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyAcceptOfferGroupOK build() => _build();

  _$NotifyAcceptOfferGroupOK _build() {
    final _$result =
        _$v ?? _$NotifyAcceptOfferGroupOK._(status: status, message: message);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

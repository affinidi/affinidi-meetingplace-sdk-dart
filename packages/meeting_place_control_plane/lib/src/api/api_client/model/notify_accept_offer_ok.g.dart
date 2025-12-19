// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_accept_offer_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyAcceptOfferOK extends NotifyAcceptOfferOK {
  @override
  final String? status;
  @override
  final String? message;

  factory _$NotifyAcceptOfferOK([
    void Function(NotifyAcceptOfferOKBuilder)? updates,
  ]) => (NotifyAcceptOfferOKBuilder()..update(updates))._build();

  _$NotifyAcceptOfferOK._({this.status, this.message}) : super._();
  @override
  NotifyAcceptOfferOK rebuild(
    void Function(NotifyAcceptOfferOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyAcceptOfferOKBuilder toBuilder() =>
      NotifyAcceptOfferOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyAcceptOfferOK &&
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
    return (newBuiltValueToStringHelper(r'NotifyAcceptOfferOK')
          ..add('status', status)
          ..add('message', message))
        .toString();
  }
}

class NotifyAcceptOfferOKBuilder
    implements Builder<NotifyAcceptOfferOK, NotifyAcceptOfferOKBuilder> {
  _$NotifyAcceptOfferOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  NotifyAcceptOfferOKBuilder() {
    NotifyAcceptOfferOK._defaults(this);
  }

  NotifyAcceptOfferOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyAcceptOfferOK other) {
    _$v = other as _$NotifyAcceptOfferOK;
  }

  @override
  void update(void Function(NotifyAcceptOfferOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyAcceptOfferOK build() => _build();

  _$NotifyAcceptOfferOK _build() {
    final _$result =
        _$v ?? _$NotifyAcceptOfferOK._(status: status, message: message);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

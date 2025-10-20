// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deregister_offer_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeregisterOfferOK extends DeregisterOfferOK {
  @override
  final String? status;
  @override
  final String? message;

  factory _$DeregisterOfferOK(
          [void Function(DeregisterOfferOKBuilder)? updates]) =>
      (DeregisterOfferOKBuilder()..update(updates))._build();

  _$DeregisterOfferOK._({this.status, this.message}) : super._();
  @override
  DeregisterOfferOK rebuild(void Function(DeregisterOfferOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeregisterOfferOKBuilder toBuilder() =>
      DeregisterOfferOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeregisterOfferOK &&
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
    return (newBuiltValueToStringHelper(r'DeregisterOfferOK')
          ..add('status', status)
          ..add('message', message))
        .toString();
  }
}

class DeregisterOfferOKBuilder
    implements Builder<DeregisterOfferOK, DeregisterOfferOKBuilder> {
  _$DeregisterOfferOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  DeregisterOfferOKBuilder() {
    DeregisterOfferOK._defaults(this);
  }

  DeregisterOfferOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeregisterOfferOK other) {
    _$v = other as _$DeregisterOfferOK;
  }

  @override
  void update(void Function(DeregisterOfferOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeregisterOfferOK build() => _build();

  _$DeregisterOfferOK _build() {
    final _$result = _$v ??
        _$DeregisterOfferOK._(
          status: status,
          message: message,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

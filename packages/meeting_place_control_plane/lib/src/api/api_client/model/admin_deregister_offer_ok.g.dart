// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_deregister_offer_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AdminDeregisterOfferOK extends AdminDeregisterOfferOK {
  @override
  final String? status;
  @override
  final String? message;

  factory _$AdminDeregisterOfferOK([
    void Function(AdminDeregisterOfferOKBuilder)? updates,
  ]) => (AdminDeregisterOfferOKBuilder()..update(updates))._build();

  _$AdminDeregisterOfferOK._({this.status, this.message}) : super._();
  @override
  AdminDeregisterOfferOK rebuild(
    void Function(AdminDeregisterOfferOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AdminDeregisterOfferOKBuilder toBuilder() =>
      AdminDeregisterOfferOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AdminDeregisterOfferOK &&
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
    return (newBuiltValueToStringHelper(r'AdminDeregisterOfferOK')
          ..add('status', status)
          ..add('message', message))
        .toString();
  }
}

class AdminDeregisterOfferOKBuilder
    implements Builder<AdminDeregisterOfferOK, AdminDeregisterOfferOKBuilder> {
  _$AdminDeregisterOfferOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  AdminDeregisterOfferOKBuilder() {
    AdminDeregisterOfferOK._defaults(this);
  }

  AdminDeregisterOfferOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AdminDeregisterOfferOK other) {
    _$v = other as _$AdminDeregisterOfferOK;
  }

  @override
  void update(void Function(AdminDeregisterOfferOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AdminDeregisterOfferOK build() => _build();

  _$AdminDeregisterOfferOK _build() {
    final _$result =
        _$v ?? _$AdminDeregisterOfferOK._(status: status, message: message);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

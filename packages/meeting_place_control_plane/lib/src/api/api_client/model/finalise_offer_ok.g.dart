// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finalise_offer_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FinaliseOfferOK extends FinaliseOfferOK {
  @override
  final String? status;
  @override
  final String? message;
  @override
  final String notificationToken;

  factory _$FinaliseOfferOK([void Function(FinaliseOfferOKBuilder)? updates]) =>
      (FinaliseOfferOKBuilder()..update(updates))._build();

  _$FinaliseOfferOK._({
    this.status,
    this.message,
    required this.notificationToken,
  }) : super._();
  @override
  FinaliseOfferOK rebuild(void Function(FinaliseOfferOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FinaliseOfferOKBuilder toBuilder() => FinaliseOfferOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FinaliseOfferOK &&
        status == other.status &&
        message == other.message &&
        notificationToken == other.notificationToken;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, notificationToken.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FinaliseOfferOK')
          ..add('status', status)
          ..add('message', message)
          ..add('notificationToken', notificationToken))
        .toString();
  }
}

class FinaliseOfferOKBuilder
    implements Builder<FinaliseOfferOK, FinaliseOfferOKBuilder> {
  _$FinaliseOfferOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  String? _notificationToken;
  String? get notificationToken => _$this._notificationToken;
  set notificationToken(String? notificationToken) =>
      _$this._notificationToken = notificationToken;

  FinaliseOfferOKBuilder() {
    FinaliseOfferOK._defaults(this);
  }

  FinaliseOfferOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _notificationToken = $v.notificationToken;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FinaliseOfferOK other) {
    _$v = other as _$FinaliseOfferOK;
  }

  @override
  void update(void Function(FinaliseOfferOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FinaliseOfferOK build() => _build();

  _$FinaliseOfferOK _build() {
    final _$result =
        _$v ??
        _$FinaliseOfferOK._(
          status: status,
          message: message,
          notificationToken: BuiltValueNullFieldError.checkNotNull(
            notificationToken,
            r'FinaliseOfferOK',
            'notificationToken',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

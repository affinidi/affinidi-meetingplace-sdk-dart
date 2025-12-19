// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_offer_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RegisterOfferOK extends RegisterOfferOK {
  @override
  final String? message;
  @override
  final String mnemonic;
  @override
  final String? validUntil;
  @override
  final int? maximumUsage;
  @override
  final String offerLink;

  factory _$RegisterOfferOK([void Function(RegisterOfferOKBuilder)? updates]) =>
      (RegisterOfferOKBuilder()..update(updates))._build();

  _$RegisterOfferOK._({
    this.message,
    required this.mnemonic,
    this.validUntil,
    this.maximumUsage,
    required this.offerLink,
  }) : super._();
  @override
  RegisterOfferOK rebuild(void Function(RegisterOfferOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegisterOfferOKBuilder toBuilder() => RegisterOfferOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterOfferOK &&
        message == other.message &&
        mnemonic == other.mnemonic &&
        validUntil == other.validUntil &&
        maximumUsage == other.maximumUsage &&
        offerLink == other.offerLink;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, mnemonic.hashCode);
    _$hash = $jc(_$hash, validUntil.hashCode);
    _$hash = $jc(_$hash, maximumUsage.hashCode);
    _$hash = $jc(_$hash, offerLink.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterOfferOK')
          ..add('message', message)
          ..add('mnemonic', mnemonic)
          ..add('validUntil', validUntil)
          ..add('maximumUsage', maximumUsage)
          ..add('offerLink', offerLink))
        .toString();
  }
}

class RegisterOfferOKBuilder
    implements Builder<RegisterOfferOK, RegisterOfferOKBuilder> {
  _$RegisterOfferOK? _$v;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  String? _mnemonic;
  String? get mnemonic => _$this._mnemonic;
  set mnemonic(String? mnemonic) => _$this._mnemonic = mnemonic;

  String? _validUntil;
  String? get validUntil => _$this._validUntil;
  set validUntil(String? validUntil) => _$this._validUntil = validUntil;

  int? _maximumUsage;
  int? get maximumUsage => _$this._maximumUsage;
  set maximumUsage(int? maximumUsage) => _$this._maximumUsage = maximumUsage;

  String? _offerLink;
  String? get offerLink => _$this._offerLink;
  set offerLink(String? offerLink) => _$this._offerLink = offerLink;

  RegisterOfferOKBuilder() {
    RegisterOfferOK._defaults(this);
  }

  RegisterOfferOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _message = $v.message;
      _mnemonic = $v.mnemonic;
      _validUntil = $v.validUntil;
      _maximumUsage = $v.maximumUsage;
      _offerLink = $v.offerLink;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterOfferOK other) {
    _$v = other as _$RegisterOfferOK;
  }

  @override
  void update(void Function(RegisterOfferOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterOfferOK build() => _build();

  _$RegisterOfferOK _build() {
    final _$result =
        _$v ??
        _$RegisterOfferOK._(
          message: message,
          mnemonic: BuiltValueNullFieldError.checkNotNull(
            mnemonic,
            r'RegisterOfferOK',
            'mnemonic',
          ),
          validUntil: validUntil,
          maximumUsage: maximumUsage,
          offerLink: BuiltValueNullFieldError.checkNotNull(
            offerLink,
            r'RegisterOfferOK',
            'offerLink',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

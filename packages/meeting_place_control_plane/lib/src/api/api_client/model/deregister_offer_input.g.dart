// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deregister_offer_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeregisterOfferInput extends DeregisterOfferInput {
  @override
  final String mnemonic;
  @override
  final String offerLink;

  factory _$DeregisterOfferInput(
          [void Function(DeregisterOfferInputBuilder)? updates]) =>
      (DeregisterOfferInputBuilder()..update(updates))._build();

  _$DeregisterOfferInput._({required this.mnemonic, required this.offerLink})
      : super._();
  @override
  DeregisterOfferInput rebuild(
          void Function(DeregisterOfferInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeregisterOfferInputBuilder toBuilder() =>
      DeregisterOfferInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeregisterOfferInput &&
        mnemonic == other.mnemonic &&
        offerLink == other.offerLink;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mnemonic.hashCode);
    _$hash = $jc(_$hash, offerLink.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeregisterOfferInput')
          ..add('mnemonic', mnemonic)
          ..add('offerLink', offerLink))
        .toString();
  }
}

class DeregisterOfferInputBuilder
    implements Builder<DeregisterOfferInput, DeregisterOfferInputBuilder> {
  _$DeregisterOfferInput? _$v;

  String? _mnemonic;
  String? get mnemonic => _$this._mnemonic;
  set mnemonic(String? mnemonic) => _$this._mnemonic = mnemonic;

  String? _offerLink;
  String? get offerLink => _$this._offerLink;
  set offerLink(String? offerLink) => _$this._offerLink = offerLink;

  DeregisterOfferInputBuilder() {
    DeregisterOfferInput._defaults(this);
  }

  DeregisterOfferInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mnemonic = $v.mnemonic;
      _offerLink = $v.offerLink;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeregisterOfferInput other) {
    _$v = other as _$DeregisterOfferInput;
  }

  @override
  void update(void Function(DeregisterOfferInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeregisterOfferInput build() => _build();

  _$DeregisterOfferInput _build() {
    final _$result = _$v ??
        _$DeregisterOfferInput._(
          mnemonic: BuiltValueNullFieldError.checkNotNull(
              mnemonic, r'DeregisterOfferInput', 'mnemonic'),
          offerLink: BuiltValueNullFieldError.checkNotNull(
              offerLink, r'DeregisterOfferInput', 'offerLink'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

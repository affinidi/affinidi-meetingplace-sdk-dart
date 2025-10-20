// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_accept_offer_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyAcceptOfferInput extends NotifyAcceptOfferInput {
  @override
  final String mnemonic;
  @override
  final String did;
  @override
  final String offerLink;
  @override
  final String senderInfo;

  factory _$NotifyAcceptOfferInput(
          [void Function(NotifyAcceptOfferInputBuilder)? updates]) =>
      (NotifyAcceptOfferInputBuilder()..update(updates))._build();

  _$NotifyAcceptOfferInput._(
      {required this.mnemonic,
      required this.did,
      required this.offerLink,
      required this.senderInfo})
      : super._();
  @override
  NotifyAcceptOfferInput rebuild(
          void Function(NotifyAcceptOfferInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotifyAcceptOfferInputBuilder toBuilder() =>
      NotifyAcceptOfferInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyAcceptOfferInput &&
        mnemonic == other.mnemonic &&
        did == other.did &&
        offerLink == other.offerLink &&
        senderInfo == other.senderInfo;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mnemonic.hashCode);
    _$hash = $jc(_$hash, did.hashCode);
    _$hash = $jc(_$hash, offerLink.hashCode);
    _$hash = $jc(_$hash, senderInfo.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyAcceptOfferInput')
          ..add('mnemonic', mnemonic)
          ..add('did', did)
          ..add('offerLink', offerLink)
          ..add('senderInfo', senderInfo))
        .toString();
  }
}

class NotifyAcceptOfferInputBuilder
    implements Builder<NotifyAcceptOfferInput, NotifyAcceptOfferInputBuilder> {
  _$NotifyAcceptOfferInput? _$v;

  String? _mnemonic;
  String? get mnemonic => _$this._mnemonic;
  set mnemonic(String? mnemonic) => _$this._mnemonic = mnemonic;

  String? _did;
  String? get did => _$this._did;
  set did(String? did) => _$this._did = did;

  String? _offerLink;
  String? get offerLink => _$this._offerLink;
  set offerLink(String? offerLink) => _$this._offerLink = offerLink;

  String? _senderInfo;
  String? get senderInfo => _$this._senderInfo;
  set senderInfo(String? senderInfo) => _$this._senderInfo = senderInfo;

  NotifyAcceptOfferInputBuilder() {
    NotifyAcceptOfferInput._defaults(this);
  }

  NotifyAcceptOfferInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mnemonic = $v.mnemonic;
      _did = $v.did;
      _offerLink = $v.offerLink;
      _senderInfo = $v.senderInfo;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyAcceptOfferInput other) {
    _$v = other as _$NotifyAcceptOfferInput;
  }

  @override
  void update(void Function(NotifyAcceptOfferInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyAcceptOfferInput build() => _build();

  _$NotifyAcceptOfferInput _build() {
    final _$result = _$v ??
        _$NotifyAcceptOfferInput._(
          mnemonic: BuiltValueNullFieldError.checkNotNull(
              mnemonic, r'NotifyAcceptOfferInput', 'mnemonic'),
          did: BuiltValueNullFieldError.checkNotNull(
              did, r'NotifyAcceptOfferInput', 'did'),
          offerLink: BuiltValueNullFieldError.checkNotNull(
              offerLink, r'NotifyAcceptOfferInput', 'offerLink'),
          senderInfo: BuiltValueNullFieldError.checkNotNull(
              senderInfo, r'NotifyAcceptOfferInput', 'senderInfo'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

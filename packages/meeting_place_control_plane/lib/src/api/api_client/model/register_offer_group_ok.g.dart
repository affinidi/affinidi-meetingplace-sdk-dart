// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_offer_group_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RegisterOfferGroupOK extends RegisterOfferGroupOK {
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
  @override
  final String groupId;
  @override
  final String groupDid;

  factory _$RegisterOfferGroupOK([
    void Function(RegisterOfferGroupOKBuilder)? updates,
  ]) => (RegisterOfferGroupOKBuilder()..update(updates))._build();

  _$RegisterOfferGroupOK._({
    this.message,
    required this.mnemonic,
    this.validUntil,
    this.maximumUsage,
    required this.offerLink,
    required this.groupId,
    required this.groupDid,
  }) : super._();
  @override
  RegisterOfferGroupOK rebuild(
    void Function(RegisterOfferGroupOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RegisterOfferGroupOKBuilder toBuilder() =>
      RegisterOfferGroupOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterOfferGroupOK &&
        message == other.message &&
        mnemonic == other.mnemonic &&
        validUntil == other.validUntil &&
        maximumUsage == other.maximumUsage &&
        offerLink == other.offerLink &&
        groupId == other.groupId &&
        groupDid == other.groupDid;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, mnemonic.hashCode);
    _$hash = $jc(_$hash, validUntil.hashCode);
    _$hash = $jc(_$hash, maximumUsage.hashCode);
    _$hash = $jc(_$hash, offerLink.hashCode);
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, groupDid.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterOfferGroupOK')
          ..add('message', message)
          ..add('mnemonic', mnemonic)
          ..add('validUntil', validUntil)
          ..add('maximumUsage', maximumUsage)
          ..add('offerLink', offerLink)
          ..add('groupId', groupId)
          ..add('groupDid', groupDid))
        .toString();
  }
}

class RegisterOfferGroupOKBuilder
    implements Builder<RegisterOfferGroupOK, RegisterOfferGroupOKBuilder> {
  _$RegisterOfferGroupOK? _$v;

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

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  String? _groupDid;
  String? get groupDid => _$this._groupDid;
  set groupDid(String? groupDid) => _$this._groupDid = groupDid;

  RegisterOfferGroupOKBuilder() {
    RegisterOfferGroupOK._defaults(this);
  }

  RegisterOfferGroupOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _message = $v.message;
      _mnemonic = $v.mnemonic;
      _validUntil = $v.validUntil;
      _maximumUsage = $v.maximumUsage;
      _offerLink = $v.offerLink;
      _groupId = $v.groupId;
      _groupDid = $v.groupDid;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterOfferGroupOK other) {
    _$v = other as _$RegisterOfferGroupOK;
  }

  @override
  void update(void Function(RegisterOfferGroupOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterOfferGroupOK build() => _build();

  _$RegisterOfferGroupOK _build() {
    final _$result =
        _$v ??
        _$RegisterOfferGroupOK._(
          message: message,
          mnemonic: BuiltValueNullFieldError.checkNotNull(
            mnemonic,
            r'RegisterOfferGroupOK',
            'mnemonic',
          ),
          validUntil: validUntil,
          maximumUsage: maximumUsage,
          offerLink: BuiltValueNullFieldError.checkNotNull(
            offerLink,
            r'RegisterOfferGroupOK',
            'offerLink',
          ),
          groupId: BuiltValueNullFieldError.checkNotNull(
            groupId,
            r'RegisterOfferGroupOK',
            'groupId',
          ),
          groupDid: BuiltValueNullFieldError.checkNotNull(
            groupDid,
            r'RegisterOfferGroupOK',
            'groupDid',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

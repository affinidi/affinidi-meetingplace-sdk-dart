// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_offer_group_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AcceptOfferGroupOK extends AcceptOfferGroupOK {
  @override
  final String? status;
  @override
  final String? message;
  @override
  final String didcommMessage;
  @override
  final String offerLink;
  @override
  final String name;
  @override
  final String description;
  @override
  final String? validUntil;
  @override
  final String vcard;
  @override
  final String mediatorDid;
  @override
  final String mediatorEndpoint;
  @override
  final String mediatorWSSEndpoint;

  factory _$AcceptOfferGroupOK(
          [void Function(AcceptOfferGroupOKBuilder)? updates]) =>
      (AcceptOfferGroupOKBuilder()..update(updates))._build();

  _$AcceptOfferGroupOK._(
      {this.status,
      this.message,
      required this.didcommMessage,
      required this.offerLink,
      required this.name,
      required this.description,
      this.validUntil,
      required this.vcard,
      required this.mediatorDid,
      required this.mediatorEndpoint,
      required this.mediatorWSSEndpoint})
      : super._();
  @override
  AcceptOfferGroupOK rebuild(
          void Function(AcceptOfferGroupOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AcceptOfferGroupOKBuilder toBuilder() =>
      AcceptOfferGroupOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcceptOfferGroupOK &&
        status == other.status &&
        message == other.message &&
        didcommMessage == other.didcommMessage &&
        offerLink == other.offerLink &&
        name == other.name &&
        description == other.description &&
        validUntil == other.validUntil &&
        vcard == other.vcard &&
        mediatorDid == other.mediatorDid &&
        mediatorEndpoint == other.mediatorEndpoint &&
        mediatorWSSEndpoint == other.mediatorWSSEndpoint;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, didcommMessage.hashCode);
    _$hash = $jc(_$hash, offerLink.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, validUntil.hashCode);
    _$hash = $jc(_$hash, vcard.hashCode);
    _$hash = $jc(_$hash, mediatorDid.hashCode);
    _$hash = $jc(_$hash, mediatorEndpoint.hashCode);
    _$hash = $jc(_$hash, mediatorWSSEndpoint.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AcceptOfferGroupOK')
          ..add('status', status)
          ..add('message', message)
          ..add('didcommMessage', didcommMessage)
          ..add('offerLink', offerLink)
          ..add('name', name)
          ..add('description', description)
          ..add('validUntil', validUntil)
          ..add('vcard', vcard)
          ..add('mediatorDid', mediatorDid)
          ..add('mediatorEndpoint', mediatorEndpoint)
          ..add('mediatorWSSEndpoint', mediatorWSSEndpoint))
        .toString();
  }
}

class AcceptOfferGroupOKBuilder
    implements Builder<AcceptOfferGroupOK, AcceptOfferGroupOKBuilder> {
  _$AcceptOfferGroupOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  String? _didcommMessage;
  String? get didcommMessage => _$this._didcommMessage;
  set didcommMessage(String? didcommMessage) =>
      _$this._didcommMessage = didcommMessage;

  String? _offerLink;
  String? get offerLink => _$this._offerLink;
  set offerLink(String? offerLink) => _$this._offerLink = offerLink;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  String? _validUntil;
  String? get validUntil => _$this._validUntil;
  set validUntil(String? validUntil) => _$this._validUntil = validUntil;

  String? _vcard;
  String? get vcard => _$this._vcard;
  set vcard(String? vcard) => _$this._vcard = vcard;

  String? _mediatorDid;
  String? get mediatorDid => _$this._mediatorDid;
  set mediatorDid(String? mediatorDid) => _$this._mediatorDid = mediatorDid;

  String? _mediatorEndpoint;
  String? get mediatorEndpoint => _$this._mediatorEndpoint;
  set mediatorEndpoint(String? mediatorEndpoint) =>
      _$this._mediatorEndpoint = mediatorEndpoint;

  String? _mediatorWSSEndpoint;
  String? get mediatorWSSEndpoint => _$this._mediatorWSSEndpoint;
  set mediatorWSSEndpoint(String? mediatorWSSEndpoint) =>
      _$this._mediatorWSSEndpoint = mediatorWSSEndpoint;

  AcceptOfferGroupOKBuilder() {
    AcceptOfferGroupOK._defaults(this);
  }

  AcceptOfferGroupOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _didcommMessage = $v.didcommMessage;
      _offerLink = $v.offerLink;
      _name = $v.name;
      _description = $v.description;
      _validUntil = $v.validUntil;
      _vcard = $v.vcard;
      _mediatorDid = $v.mediatorDid;
      _mediatorEndpoint = $v.mediatorEndpoint;
      _mediatorWSSEndpoint = $v.mediatorWSSEndpoint;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AcceptOfferGroupOK other) {
    _$v = other as _$AcceptOfferGroupOK;
  }

  @override
  void update(void Function(AcceptOfferGroupOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcceptOfferGroupOK build() => _build();

  _$AcceptOfferGroupOK _build() {
    final _$result = _$v ??
        _$AcceptOfferGroupOK._(
          status: status,
          message: message,
          didcommMessage: BuiltValueNullFieldError.checkNotNull(
              didcommMessage, r'AcceptOfferGroupOK', 'didcommMessage'),
          offerLink: BuiltValueNullFieldError.checkNotNull(
              offerLink, r'AcceptOfferGroupOK', 'offerLink'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'AcceptOfferGroupOK', 'name'),
          description: BuiltValueNullFieldError.checkNotNull(
              description, r'AcceptOfferGroupOK', 'description'),
          validUntil: validUntil,
          vcard: BuiltValueNullFieldError.checkNotNull(
              vcard, r'AcceptOfferGroupOK', 'vcard'),
          mediatorDid: BuiltValueNullFieldError.checkNotNull(
              mediatorDid, r'AcceptOfferGroupOK', 'mediatorDid'),
          mediatorEndpoint: BuiltValueNullFieldError.checkNotNull(
              mediatorEndpoint, r'AcceptOfferGroupOK', 'mediatorEndpoint'),
          mediatorWSSEndpoint: BuiltValueNullFieldError.checkNotNull(
              mediatorWSSEndpoint,
              r'AcceptOfferGroupOK',
              'mediatorWSSEndpoint'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

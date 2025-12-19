// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query_offer_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$QueryOfferOK extends QueryOfferOK {
  @override
  final String status;
  @override
  final String? message;
  @override
  final String offerLink;
  @override
  final String name;
  @override
  final String description;
  @override
  final String? validUntil;
  @override
  final String contactCard;
  @override
  final int contactAttributes;
  @override
  final int? offerType;
  @override
  final String mediatorDid;
  @override
  final String mediatorEndpoint;
  @override
  final String mediatorWSSEndpoint;
  @override
  final String didcommMessage;
  @override
  final int? maximumUsage;
  @override
  final String? groupId;
  @override
  final String? groupDid;

  factory _$QueryOfferOK([void Function(QueryOfferOKBuilder)? updates]) =>
      (QueryOfferOKBuilder()..update(updates))._build();

  _$QueryOfferOK._({
    required this.status,
    this.message,
    required this.offerLink,
    required this.name,
    required this.description,
    this.validUntil,
    required this.contactCard,
    required this.contactAttributes,
    this.offerType,
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
    required this.didcommMessage,
    this.maximumUsage,
    this.groupId,
    this.groupDid,
  }) : super._();
  @override
  QueryOfferOK rebuild(void Function(QueryOfferOKBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  QueryOfferOKBuilder toBuilder() => QueryOfferOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is QueryOfferOK &&
        status == other.status &&
        message == other.message &&
        offerLink == other.offerLink &&
        name == other.name &&
        description == other.description &&
        validUntil == other.validUntil &&
        contactCard == other.contactCard &&
        contactAttributes == other.contactAttributes &&
        offerType == other.offerType &&
        mediatorDid == other.mediatorDid &&
        mediatorEndpoint == other.mediatorEndpoint &&
        mediatorWSSEndpoint == other.mediatorWSSEndpoint &&
        didcommMessage == other.didcommMessage &&
        maximumUsage == other.maximumUsage &&
        groupId == other.groupId &&
        groupDid == other.groupDid;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, offerLink.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jc(_$hash, validUntil.hashCode);
    _$hash = $jc(_$hash, contactCard.hashCode);
    _$hash = $jc(_$hash, contactAttributes.hashCode);
    _$hash = $jc(_$hash, offerType.hashCode);
    _$hash = $jc(_$hash, mediatorDid.hashCode);
    _$hash = $jc(_$hash, mediatorEndpoint.hashCode);
    _$hash = $jc(_$hash, mediatorWSSEndpoint.hashCode);
    _$hash = $jc(_$hash, didcommMessage.hashCode);
    _$hash = $jc(_$hash, maximumUsage.hashCode);
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, groupDid.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'QueryOfferOK')
          ..add('status', status)
          ..add('message', message)
          ..add('offerLink', offerLink)
          ..add('name', name)
          ..add('description', description)
          ..add('validUntil', validUntil)
          ..add('contactCard', contactCard)
          ..add('contactAttributes', contactAttributes)
          ..add('offerType', offerType)
          ..add('mediatorDid', mediatorDid)
          ..add('mediatorEndpoint', mediatorEndpoint)
          ..add('mediatorWSSEndpoint', mediatorWSSEndpoint)
          ..add('didcommMessage', didcommMessage)
          ..add('maximumUsage', maximumUsage)
          ..add('groupId', groupId)
          ..add('groupDid', groupDid))
        .toString();
  }
}

class QueryOfferOKBuilder
    implements Builder<QueryOfferOK, QueryOfferOKBuilder> {
  _$QueryOfferOK? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

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

  String? _contactCard;
  String? get contactCard => _$this._contactCard;
  set contactCard(String? contactCard) => _$this._contactCard = contactCard;

  int? _contactAttributes;
  int? get contactAttributes => _$this._contactAttributes;
  set contactAttributes(int? contactAttributes) =>
      _$this._contactAttributes = contactAttributes;

  int? _offerType;
  int? get offerType => _$this._offerType;
  set offerType(int? offerType) => _$this._offerType = offerType;

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

  String? _didcommMessage;
  String? get didcommMessage => _$this._didcommMessage;
  set didcommMessage(String? didcommMessage) =>
      _$this._didcommMessage = didcommMessage;

  int? _maximumUsage;
  int? get maximumUsage => _$this._maximumUsage;
  set maximumUsage(int? maximumUsage) => _$this._maximumUsage = maximumUsage;

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  String? _groupDid;
  String? get groupDid => _$this._groupDid;
  set groupDid(String? groupDid) => _$this._groupDid = groupDid;

  QueryOfferOKBuilder() {
    QueryOfferOK._defaults(this);
  }

  QueryOfferOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _message = $v.message;
      _offerLink = $v.offerLink;
      _name = $v.name;
      _description = $v.description;
      _validUntil = $v.validUntil;
      _contactCard = $v.contactCard;
      _contactAttributes = $v.contactAttributes;
      _offerType = $v.offerType;
      _mediatorDid = $v.mediatorDid;
      _mediatorEndpoint = $v.mediatorEndpoint;
      _mediatorWSSEndpoint = $v.mediatorWSSEndpoint;
      _didcommMessage = $v.didcommMessage;
      _maximumUsage = $v.maximumUsage;
      _groupId = $v.groupId;
      _groupDid = $v.groupDid;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(QueryOfferOK other) {
    _$v = other as _$QueryOfferOK;
  }

  @override
  void update(void Function(QueryOfferOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  QueryOfferOK build() => _build();

  _$QueryOfferOK _build() {
    final _$result =
        _$v ??
        _$QueryOfferOK._(
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'QueryOfferOK',
            'status',
          ),
          message: message,
          offerLink: BuiltValueNullFieldError.checkNotNull(
            offerLink,
            r'QueryOfferOK',
            'offerLink',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'QueryOfferOK',
            'name',
          ),
          description: BuiltValueNullFieldError.checkNotNull(
            description,
            r'QueryOfferOK',
            'description',
          ),
          validUntil: validUntil,
          contactCard: BuiltValueNullFieldError.checkNotNull(
            contactCard,
            r'QueryOfferOK',
            'contactCard',
          ),
          contactAttributes: BuiltValueNullFieldError.checkNotNull(
            contactAttributes,
            r'QueryOfferOK',
            'contactAttributes',
          ),
          offerType: offerType,
          mediatorDid: BuiltValueNullFieldError.checkNotNull(
            mediatorDid,
            r'QueryOfferOK',
            'mediatorDid',
          ),
          mediatorEndpoint: BuiltValueNullFieldError.checkNotNull(
            mediatorEndpoint,
            r'QueryOfferOK',
            'mediatorEndpoint',
          ),
          mediatorWSSEndpoint: BuiltValueNullFieldError.checkNotNull(
            mediatorWSSEndpoint,
            r'QueryOfferOK',
            'mediatorWSSEndpoint',
          ),
          didcommMessage: BuiltValueNullFieldError.checkNotNull(
            didcommMessage,
            r'QueryOfferOK',
            'didcommMessage',
          ),
          maximumUsage: maximumUsage,
          groupId: groupId,
          groupDid: groupDid,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

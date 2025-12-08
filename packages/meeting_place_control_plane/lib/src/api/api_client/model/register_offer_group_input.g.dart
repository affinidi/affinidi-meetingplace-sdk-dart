// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_offer_group_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RegisterOfferGroupInputPlatformTypeEnum
    _$registerOfferGroupInputPlatformTypeEnum_DIDCOMM =
    const RegisterOfferGroupInputPlatformTypeEnum._('DIDCOMM');
const RegisterOfferGroupInputPlatformTypeEnum
    _$registerOfferGroupInputPlatformTypeEnum_PUSH_NOTIFICATION =
    const RegisterOfferGroupInputPlatformTypeEnum._('PUSH_NOTIFICATION');
const RegisterOfferGroupInputPlatformTypeEnum
    _$registerOfferGroupInputPlatformTypeEnum_NONE =
    const RegisterOfferGroupInputPlatformTypeEnum._('NONE');

RegisterOfferGroupInputPlatformTypeEnum
    _$registerOfferGroupInputPlatformTypeEnumValueOf(String name) {
  switch (name) {
    case 'DIDCOMM':
      return _$registerOfferGroupInputPlatformTypeEnum_DIDCOMM;
    case 'PUSH_NOTIFICATION':
      return _$registerOfferGroupInputPlatformTypeEnum_PUSH_NOTIFICATION;
    case 'NONE':
      return _$registerOfferGroupInputPlatformTypeEnum_NONE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RegisterOfferGroupInputPlatformTypeEnum>
    _$registerOfferGroupInputPlatformTypeEnumValues = BuiltSet<
        RegisterOfferGroupInputPlatformTypeEnum>(const <RegisterOfferGroupInputPlatformTypeEnum>[
  _$registerOfferGroupInputPlatformTypeEnum_DIDCOMM,
  _$registerOfferGroupInputPlatformTypeEnum_PUSH_NOTIFICATION,
  _$registerOfferGroupInputPlatformTypeEnum_NONE,
]);

Serializer<RegisterOfferGroupInputPlatformTypeEnum>
    _$registerOfferGroupInputPlatformTypeEnumSerializer =
    _$RegisterOfferGroupInputPlatformTypeEnumSerializer();

class _$RegisterOfferGroupInputPlatformTypeEnumSerializer
    implements PrimitiveSerializer<RegisterOfferGroupInputPlatformTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'DIDCOMM': 'DIDCOMM',
    'PUSH_NOTIFICATION': 'PUSH_NOTIFICATION',
    'NONE': 'NONE',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'DIDCOMM': 'DIDCOMM',
    'PUSH_NOTIFICATION': 'PUSH_NOTIFICATION',
    'NONE': 'NONE',
  };

  @override
  final Iterable<Type> types = const <Type>[
    RegisterOfferGroupInputPlatformTypeEnum
  ];
  @override
  final String wireName = 'RegisterOfferGroupInputPlatformTypeEnum';

  @override
  Object serialize(Serializers serializers,
          RegisterOfferGroupInputPlatformTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  RegisterOfferGroupInputPlatformTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      RegisterOfferGroupInputPlatformTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$RegisterOfferGroupInput extends RegisterOfferGroupInput {
  @override
  final String offerName;
  @override
  final String offerDescription;
  @override
  final String didcommMessage;
  @override
  final String contactCard;
  @override
  final String? validUntil;
  @override
  final int? maximumUsage;
  @override
  final String deviceToken;
  @override
  final RegisterOfferGroupInputPlatformTypeEnum platformType;
  @override
  final String mediatorDid;
  @override
  final String mediatorEndpoint;
  @override
  final String mediatorWSSEndpoint;
  @override
  final String? customPhrase;
  @override
  final bool? isSearchable;
  @override
  final String? metadata;
  @override
  final String adminReencryptionKey;
  @override
  final String adminDid;
  @override
  final String adminPublicKey;
  @override
  final String memberContactCard;

  factory _$RegisterOfferGroupInput(
          [void Function(RegisterOfferGroupInputBuilder)? updates]) =>
      (RegisterOfferGroupInputBuilder()..update(updates))._build();

  _$RegisterOfferGroupInput._(
      {required this.offerName,
      required this.offerDescription,
      required this.didcommMessage,
      required this.contactCard,
      this.validUntil,
      this.maximumUsage,
      required this.deviceToken,
      required this.platformType,
      required this.mediatorDid,
      required this.mediatorEndpoint,
      required this.mediatorWSSEndpoint,
      this.customPhrase,
      this.isSearchable,
      this.metadata,
      required this.adminReencryptionKey,
      required this.adminDid,
      required this.adminPublicKey,
      required this.memberContactCard})
      : super._();
  @override
  RegisterOfferGroupInput rebuild(
          void Function(RegisterOfferGroupInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegisterOfferGroupInputBuilder toBuilder() =>
      RegisterOfferGroupInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterOfferGroupInput &&
        offerName == other.offerName &&
        offerDescription == other.offerDescription &&
        didcommMessage == other.didcommMessage &&
        contactCard == other.contactCard &&
        validUntil == other.validUntil &&
        maximumUsage == other.maximumUsage &&
        deviceToken == other.deviceToken &&
        platformType == other.platformType &&
        mediatorDid == other.mediatorDid &&
        mediatorEndpoint == other.mediatorEndpoint &&
        mediatorWSSEndpoint == other.mediatorWSSEndpoint &&
        customPhrase == other.customPhrase &&
        isSearchable == other.isSearchable &&
        metadata == other.metadata &&
        adminReencryptionKey == other.adminReencryptionKey &&
        adminDid == other.adminDid &&
        adminPublicKey == other.adminPublicKey &&
        memberContactCard == other.memberContactCard;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, offerName.hashCode);
    _$hash = $jc(_$hash, offerDescription.hashCode);
    _$hash = $jc(_$hash, didcommMessage.hashCode);
    _$hash = $jc(_$hash, contactCard.hashCode);
    _$hash = $jc(_$hash, validUntil.hashCode);
    _$hash = $jc(_$hash, maximumUsage.hashCode);
    _$hash = $jc(_$hash, deviceToken.hashCode);
    _$hash = $jc(_$hash, platformType.hashCode);
    _$hash = $jc(_$hash, mediatorDid.hashCode);
    _$hash = $jc(_$hash, mediatorEndpoint.hashCode);
    _$hash = $jc(_$hash, mediatorWSSEndpoint.hashCode);
    _$hash = $jc(_$hash, customPhrase.hashCode);
    _$hash = $jc(_$hash, isSearchable.hashCode);
    _$hash = $jc(_$hash, metadata.hashCode);
    _$hash = $jc(_$hash, adminReencryptionKey.hashCode);
    _$hash = $jc(_$hash, adminDid.hashCode);
    _$hash = $jc(_$hash, adminPublicKey.hashCode);
    _$hash = $jc(_$hash, memberContactCard.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterOfferGroupInput')
          ..add('offerName', offerName)
          ..add('offerDescription', offerDescription)
          ..add('didcommMessage', didcommMessage)
          ..add('contactCard', contactCard)
          ..add('validUntil', validUntil)
          ..add('maximumUsage', maximumUsage)
          ..add('deviceToken', deviceToken)
          ..add('platformType', platformType)
          ..add('mediatorDid', mediatorDid)
          ..add('mediatorEndpoint', mediatorEndpoint)
          ..add('mediatorWSSEndpoint', mediatorWSSEndpoint)
          ..add('customPhrase', customPhrase)
          ..add('isSearchable', isSearchable)
          ..add('metadata', metadata)
          ..add('adminReencryptionKey', adminReencryptionKey)
          ..add('adminDid', adminDid)
          ..add('adminPublicKey', adminPublicKey)
          ..add('memberContactCard', memberContactCard))
        .toString();
  }
}

class RegisterOfferGroupInputBuilder
    implements
        Builder<RegisterOfferGroupInput, RegisterOfferGroupInputBuilder> {
  _$RegisterOfferGroupInput? _$v;

  String? _offerName;
  String? get offerName => _$this._offerName;
  set offerName(String? offerName) => _$this._offerName = offerName;

  String? _offerDescription;
  String? get offerDescription => _$this._offerDescription;
  set offerDescription(String? offerDescription) =>
      _$this._offerDescription = offerDescription;

  String? _didcommMessage;
  String? get didcommMessage => _$this._didcommMessage;
  set didcommMessage(String? didcommMessage) =>
      _$this._didcommMessage = didcommMessage;

  String? _contactCard;
  String? get contactCard => _$this._contactCard;
  set contactCard(String? contactCard) => _$this._contactCard = contactCard;

  String? _validUntil;
  String? get validUntil => _$this._validUntil;
  set validUntil(String? validUntil) => _$this._validUntil = validUntil;

  int? _maximumUsage;
  int? get maximumUsage => _$this._maximumUsage;
  set maximumUsage(int? maximumUsage) => _$this._maximumUsage = maximumUsage;

  String? _deviceToken;
  String? get deviceToken => _$this._deviceToken;
  set deviceToken(String? deviceToken) => _$this._deviceToken = deviceToken;

  RegisterOfferGroupInputPlatformTypeEnum? _platformType;
  RegisterOfferGroupInputPlatformTypeEnum? get platformType =>
      _$this._platformType;
  set platformType(RegisterOfferGroupInputPlatformTypeEnum? platformType) =>
      _$this._platformType = platformType;

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

  String? _customPhrase;
  String? get customPhrase => _$this._customPhrase;
  set customPhrase(String? customPhrase) => _$this._customPhrase = customPhrase;

  bool? _isSearchable;
  bool? get isSearchable => _$this._isSearchable;
  set isSearchable(bool? isSearchable) => _$this._isSearchable = isSearchable;

  String? _metadata;
  String? get metadata => _$this._metadata;
  set metadata(String? metadata) => _$this._metadata = metadata;

  String? _adminReencryptionKey;
  String? get adminReencryptionKey => _$this._adminReencryptionKey;
  set adminReencryptionKey(String? adminReencryptionKey) =>
      _$this._adminReencryptionKey = adminReencryptionKey;

  String? _adminDid;
  String? get adminDid => _$this._adminDid;
  set adminDid(String? adminDid) => _$this._adminDid = adminDid;

  String? _adminPublicKey;
  String? get adminPublicKey => _$this._adminPublicKey;
  set adminPublicKey(String? adminPublicKey) =>
      _$this._adminPublicKey = adminPublicKey;

  String? _memberContactCard;
  String? get memberContactCard => _$this._memberContactCard;
  set memberContactCard(String? memberContactCard) =>
      _$this._memberContactCard = memberContactCard;

  RegisterOfferGroupInputBuilder() {
    RegisterOfferGroupInput._defaults(this);
  }

  RegisterOfferGroupInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _offerName = $v.offerName;
      _offerDescription = $v.offerDescription;
      _didcommMessage = $v.didcommMessage;
      _contactCard = $v.contactCard;
      _validUntil = $v.validUntil;
      _maximumUsage = $v.maximumUsage;
      _deviceToken = $v.deviceToken;
      _platformType = $v.platformType;
      _mediatorDid = $v.mediatorDid;
      _mediatorEndpoint = $v.mediatorEndpoint;
      _mediatorWSSEndpoint = $v.mediatorWSSEndpoint;
      _customPhrase = $v.customPhrase;
      _isSearchable = $v.isSearchable;
      _metadata = $v.metadata;
      _adminReencryptionKey = $v.adminReencryptionKey;
      _adminDid = $v.adminDid;
      _adminPublicKey = $v.adminPublicKey;
      _memberContactCard = $v.memberContactCard;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterOfferGroupInput other) {
    _$v = other as _$RegisterOfferGroupInput;
  }

  @override
  void update(void Function(RegisterOfferGroupInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterOfferGroupInput build() => _build();

  _$RegisterOfferGroupInput _build() {
    final _$result = _$v ??
        _$RegisterOfferGroupInput._(
          offerName: BuiltValueNullFieldError.checkNotNull(
              offerName, r'RegisterOfferGroupInput', 'offerName'),
          offerDescription: BuiltValueNullFieldError.checkNotNull(
              offerDescription, r'RegisterOfferGroupInput', 'offerDescription'),
          didcommMessage: BuiltValueNullFieldError.checkNotNull(
              didcommMessage, r'RegisterOfferGroupInput', 'didcommMessage'),
          contactCard: BuiltValueNullFieldError.checkNotNull(
              contactCard, r'RegisterOfferGroupInput', 'contactCard'),
          validUntil: validUntil,
          maximumUsage: maximumUsage,
          deviceToken: BuiltValueNullFieldError.checkNotNull(
              deviceToken, r'RegisterOfferGroupInput', 'deviceToken'),
          platformType: BuiltValueNullFieldError.checkNotNull(
              platformType, r'RegisterOfferGroupInput', 'platformType'),
          mediatorDid: BuiltValueNullFieldError.checkNotNull(
              mediatorDid, r'RegisterOfferGroupInput', 'mediatorDid'),
          mediatorEndpoint: BuiltValueNullFieldError.checkNotNull(
              mediatorEndpoint, r'RegisterOfferGroupInput', 'mediatorEndpoint'),
          mediatorWSSEndpoint: BuiltValueNullFieldError.checkNotNull(
              mediatorWSSEndpoint,
              r'RegisterOfferGroupInput',
              'mediatorWSSEndpoint'),
          customPhrase: customPhrase,
          isSearchable: isSearchable,
          metadata: metadata,
          adminReencryptionKey: BuiltValueNullFieldError.checkNotNull(
              adminReencryptionKey,
              r'RegisterOfferGroupInput',
              'adminReencryptionKey'),
          adminDid: BuiltValueNullFieldError.checkNotNull(
              adminDid, r'RegisterOfferGroupInput', 'adminDid'),
          adminPublicKey: BuiltValueNullFieldError.checkNotNull(
              adminPublicKey, r'RegisterOfferGroupInput', 'adminPublicKey'),
          memberContactCard: BuiltValueNullFieldError.checkNotNull(
              memberContactCard,
              r'RegisterOfferGroupInput',
              'memberContactCard'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

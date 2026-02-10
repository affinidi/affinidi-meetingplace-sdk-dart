// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_offer_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const RegisterOfferInputOfferTypeEnum
_$registerOfferInputOfferTypeEnum_number1 =
    const RegisterOfferInputOfferTypeEnum._('number1');
const RegisterOfferInputOfferTypeEnum
_$registerOfferInputOfferTypeEnum_number2 =
    const RegisterOfferInputOfferTypeEnum._('number2');
const RegisterOfferInputOfferTypeEnum
_$registerOfferInputOfferTypeEnum_number3 =
    const RegisterOfferInputOfferTypeEnum._('number3');
const RegisterOfferInputOfferTypeEnum
_$registerOfferInputOfferTypeEnum_number4 =
    const RegisterOfferInputOfferTypeEnum._('number4');

RegisterOfferInputOfferTypeEnum _$registerOfferInputOfferTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'number1':
      return _$registerOfferInputOfferTypeEnum_number1;
    case 'number2':
      return _$registerOfferInputOfferTypeEnum_number2;
    case 'number3':
      return _$registerOfferInputOfferTypeEnum_number3;
    case 'number4':
      return _$registerOfferInputOfferTypeEnum_number4;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RegisterOfferInputOfferTypeEnum>
_$registerOfferInputOfferTypeEnumValues =
    BuiltSet<RegisterOfferInputOfferTypeEnum>(
      const <RegisterOfferInputOfferTypeEnum>[
        _$registerOfferInputOfferTypeEnum_number1,
        _$registerOfferInputOfferTypeEnum_number2,
        _$registerOfferInputOfferTypeEnum_number3,
        _$registerOfferInputOfferTypeEnum_number4,
      ],
    );

const RegisterOfferInputPlatformTypeEnum
_$registerOfferInputPlatformTypeEnum_DIDCOMM =
    const RegisterOfferInputPlatformTypeEnum._('DIDCOMM');
const RegisterOfferInputPlatformTypeEnum
_$registerOfferInputPlatformTypeEnum_PUSH_NOTIFICATION =
    const RegisterOfferInputPlatformTypeEnum._('PUSH_NOTIFICATION');
const RegisterOfferInputPlatformTypeEnum
_$registerOfferInputPlatformTypeEnum_NONE =
    const RegisterOfferInputPlatformTypeEnum._('NONE');

RegisterOfferInputPlatformTypeEnum _$registerOfferInputPlatformTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'DIDCOMM':
      return _$registerOfferInputPlatformTypeEnum_DIDCOMM;
    case 'PUSH_NOTIFICATION':
      return _$registerOfferInputPlatformTypeEnum_PUSH_NOTIFICATION;
    case 'NONE':
      return _$registerOfferInputPlatformTypeEnum_NONE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<RegisterOfferInputPlatformTypeEnum>
_$registerOfferInputPlatformTypeEnumValues =
    BuiltSet<RegisterOfferInputPlatformTypeEnum>(
      const <RegisterOfferInputPlatformTypeEnum>[
        _$registerOfferInputPlatformTypeEnum_DIDCOMM,
        _$registerOfferInputPlatformTypeEnum_PUSH_NOTIFICATION,
        _$registerOfferInputPlatformTypeEnum_NONE,
      ],
    );

Serializer<RegisterOfferInputOfferTypeEnum>
_$registerOfferInputOfferTypeEnumSerializer =
    _$RegisterOfferInputOfferTypeEnumSerializer();
Serializer<RegisterOfferInputPlatformTypeEnum>
_$registerOfferInputPlatformTypeEnumSerializer =
    _$RegisterOfferInputPlatformTypeEnumSerializer();

class _$RegisterOfferInputOfferTypeEnumSerializer
    implements PrimitiveSerializer<RegisterOfferInputOfferTypeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'number1': 1,
    'number2': 2,
    'number3': 3,
    'number4': 4,
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    1: 'number1',
    2: 'number2',
    3: 'number3',
    4: 'number4',
  };

  @override
  final Iterable<Type> types = const <Type>[RegisterOfferInputOfferTypeEnum];
  @override
  final String wireName = 'RegisterOfferInputOfferTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    RegisterOfferInputOfferTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RegisterOfferInputOfferTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RegisterOfferInputOfferTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$RegisterOfferInputPlatformTypeEnumSerializer
    implements PrimitiveSerializer<RegisterOfferInputPlatformTypeEnum> {
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
  final Iterable<Type> types = const <Type>[RegisterOfferInputPlatformTypeEnum];
  @override
  final String wireName = 'RegisterOfferInputPlatformTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    RegisterOfferInputPlatformTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  RegisterOfferInputPlatformTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => RegisterOfferInputPlatformTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$RegisterOfferInput extends RegisterOfferInput {
  @override
  final String offerName;
  @override
  final String offerDescription;
  @override
  final RegisterOfferInputOfferTypeEnum? offerType;
  @override
  final String didcommMessage;
  @override
  final String contactCard;
  @override
  final String? validUntil;
  @override
  final num? maximumUsage;
  @override
  final String deviceToken;
  @override
  final RegisterOfferInputPlatformTypeEnum platformType;
  @override
  final num contactAttributes;
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
  final int? score;

  factory _$RegisterOfferInput([
    void Function(RegisterOfferInputBuilder)? updates,
  ]) => (RegisterOfferInputBuilder()..update(updates))._build();

  _$RegisterOfferInput._({
    required this.offerName,
    required this.offerDescription,
    this.offerType,
    required this.didcommMessage,
    required this.contactCard,
    this.validUntil,
    this.maximumUsage,
    required this.deviceToken,
    required this.platformType,
    required this.contactAttributes,
    required this.mediatorDid,
    required this.mediatorEndpoint,
    required this.mediatorWSSEndpoint,
    this.customPhrase,
    this.isSearchable,
    this.metadata,
    this.score,
  }) : super._();
  @override
  RegisterOfferInput rebuild(
    void Function(RegisterOfferInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RegisterOfferInputBuilder toBuilder() =>
      RegisterOfferInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegisterOfferInput &&
        offerName == other.offerName &&
        offerDescription == other.offerDescription &&
        offerType == other.offerType &&
        didcommMessage == other.didcommMessage &&
        contactCard == other.contactCard &&
        validUntil == other.validUntil &&
        maximumUsage == other.maximumUsage &&
        deviceToken == other.deviceToken &&
        platformType == other.platformType &&
        contactAttributes == other.contactAttributes &&
        mediatorDid == other.mediatorDid &&
        mediatorEndpoint == other.mediatorEndpoint &&
        mediatorWSSEndpoint == other.mediatorWSSEndpoint &&
        customPhrase == other.customPhrase &&
        isSearchable == other.isSearchable &&
        metadata == other.metadata &&
        score == other.score;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, offerName.hashCode);
    _$hash = $jc(_$hash, offerDescription.hashCode);
    _$hash = $jc(_$hash, offerType.hashCode);
    _$hash = $jc(_$hash, didcommMessage.hashCode);
    _$hash = $jc(_$hash, contactCard.hashCode);
    _$hash = $jc(_$hash, validUntil.hashCode);
    _$hash = $jc(_$hash, maximumUsage.hashCode);
    _$hash = $jc(_$hash, deviceToken.hashCode);
    _$hash = $jc(_$hash, platformType.hashCode);
    _$hash = $jc(_$hash, contactAttributes.hashCode);
    _$hash = $jc(_$hash, mediatorDid.hashCode);
    _$hash = $jc(_$hash, mediatorEndpoint.hashCode);
    _$hash = $jc(_$hash, mediatorWSSEndpoint.hashCode);
    _$hash = $jc(_$hash, customPhrase.hashCode);
    _$hash = $jc(_$hash, isSearchable.hashCode);
    _$hash = $jc(_$hash, metadata.hashCode);
    _$hash = $jc(_$hash, score.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegisterOfferInput')
          ..add('offerName', offerName)
          ..add('offerDescription', offerDescription)
          ..add('offerType', offerType)
          ..add('didcommMessage', didcommMessage)
          ..add('contactCard', contactCard)
          ..add('validUntil', validUntil)
          ..add('maximumUsage', maximumUsage)
          ..add('deviceToken', deviceToken)
          ..add('platformType', platformType)
          ..add('contactAttributes', contactAttributes)
          ..add('mediatorDid', mediatorDid)
          ..add('mediatorEndpoint', mediatorEndpoint)
          ..add('mediatorWSSEndpoint', mediatorWSSEndpoint)
          ..add('customPhrase', customPhrase)
          ..add('isSearchable', isSearchable)
          ..add('metadata', metadata)
          ..add('score', score))
        .toString();
  }
}

class RegisterOfferInputBuilder
    implements Builder<RegisterOfferInput, RegisterOfferInputBuilder> {
  _$RegisterOfferInput? _$v;

  String? _offerName;
  String? get offerName => _$this._offerName;
  set offerName(String? offerName) => _$this._offerName = offerName;

  String? _offerDescription;
  String? get offerDescription => _$this._offerDescription;
  set offerDescription(String? offerDescription) =>
      _$this._offerDescription = offerDescription;

  RegisterOfferInputOfferTypeEnum? _offerType;
  RegisterOfferInputOfferTypeEnum? get offerType => _$this._offerType;
  set offerType(RegisterOfferInputOfferTypeEnum? offerType) =>
      _$this._offerType = offerType;

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

  num? _maximumUsage;
  num? get maximumUsage => _$this._maximumUsage;
  set maximumUsage(num? maximumUsage) => _$this._maximumUsage = maximumUsage;

  String? _deviceToken;
  String? get deviceToken => _$this._deviceToken;
  set deviceToken(String? deviceToken) => _$this._deviceToken = deviceToken;

  RegisterOfferInputPlatformTypeEnum? _platformType;
  RegisterOfferInputPlatformTypeEnum? get platformType => _$this._platformType;
  set platformType(RegisterOfferInputPlatformTypeEnum? platformType) =>
      _$this._platformType = platformType;

  num? _contactAttributes;
  num? get contactAttributes => _$this._contactAttributes;
  set contactAttributes(num? contactAttributes) =>
      _$this._contactAttributes = contactAttributes;

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

  int? _score;
  int? get score => _$this._score;
  set score(int? score) => _$this._score = score;

  RegisterOfferInputBuilder() {
    RegisterOfferInput._defaults(this);
  }

  RegisterOfferInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _offerName = $v.offerName;
      _offerDescription = $v.offerDescription;
      _offerType = $v.offerType;
      _didcommMessage = $v.didcommMessage;
      _contactCard = $v.contactCard;
      _validUntil = $v.validUntil;
      _maximumUsage = $v.maximumUsage;
      _deviceToken = $v.deviceToken;
      _platformType = $v.platformType;
      _contactAttributes = $v.contactAttributes;
      _mediatorDid = $v.mediatorDid;
      _mediatorEndpoint = $v.mediatorEndpoint;
      _mediatorWSSEndpoint = $v.mediatorWSSEndpoint;
      _customPhrase = $v.customPhrase;
      _isSearchable = $v.isSearchable;
      _metadata = $v.metadata;
      _score = $v.score;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegisterOfferInput other) {
    _$v = other as _$RegisterOfferInput;
  }

  @override
  void update(void Function(RegisterOfferInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegisterOfferInput build() => _build();

  _$RegisterOfferInput _build() {
    final _$result =
        _$v ??
        _$RegisterOfferInput._(
          offerName: BuiltValueNullFieldError.checkNotNull(
            offerName,
            r'RegisterOfferInput',
            'offerName',
          ),
          offerDescription: BuiltValueNullFieldError.checkNotNull(
            offerDescription,
            r'RegisterOfferInput',
            'offerDescription',
          ),
          offerType: offerType,
          didcommMessage: BuiltValueNullFieldError.checkNotNull(
            didcommMessage,
            r'RegisterOfferInput',
            'didcommMessage',
          ),
          contactCard: BuiltValueNullFieldError.checkNotNull(
            contactCard,
            r'RegisterOfferInput',
            'contactCard',
          ),
          validUntil: validUntil,
          maximumUsage: maximumUsage,
          deviceToken: BuiltValueNullFieldError.checkNotNull(
            deviceToken,
            r'RegisterOfferInput',
            'deviceToken',
          ),
          platformType: BuiltValueNullFieldError.checkNotNull(
            platformType,
            r'RegisterOfferInput',
            'platformType',
          ),
          contactAttributes: BuiltValueNullFieldError.checkNotNull(
            contactAttributes,
            r'RegisterOfferInput',
            'contactAttributes',
          ),
          mediatorDid: BuiltValueNullFieldError.checkNotNull(
            mediatorDid,
            r'RegisterOfferInput',
            'mediatorDid',
          ),
          mediatorEndpoint: BuiltValueNullFieldError.checkNotNull(
            mediatorEndpoint,
            r'RegisterOfferInput',
            'mediatorEndpoint',
          ),
          mediatorWSSEndpoint: BuiltValueNullFieldError.checkNotNull(
            mediatorWSSEndpoint,
            r'RegisterOfferInput',
            'mediatorWSSEndpoint',
          ),
          customPhrase: customPhrase,
          isSearchable: isSearchable,
          metadata: metadata,
          score: score,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

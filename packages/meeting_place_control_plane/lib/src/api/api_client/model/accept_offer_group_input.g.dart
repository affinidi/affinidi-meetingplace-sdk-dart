// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_offer_group_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AcceptOfferGroupInputPlatformTypeEnum
_$acceptOfferGroupInputPlatformTypeEnum_DIDCOMM =
    const AcceptOfferGroupInputPlatformTypeEnum._('DIDCOMM');
const AcceptOfferGroupInputPlatformTypeEnum
_$acceptOfferGroupInputPlatformTypeEnum_PUSH_NOTIFICATION =
    const AcceptOfferGroupInputPlatformTypeEnum._('PUSH_NOTIFICATION');
const AcceptOfferGroupInputPlatformTypeEnum
_$acceptOfferGroupInputPlatformTypeEnum_NONE =
    const AcceptOfferGroupInputPlatformTypeEnum._('NONE');

AcceptOfferGroupInputPlatformTypeEnum
_$acceptOfferGroupInputPlatformTypeEnumValueOf(String name) {
  switch (name) {
    case 'DIDCOMM':
      return _$acceptOfferGroupInputPlatformTypeEnum_DIDCOMM;
    case 'PUSH_NOTIFICATION':
      return _$acceptOfferGroupInputPlatformTypeEnum_PUSH_NOTIFICATION;
    case 'NONE':
      return _$acceptOfferGroupInputPlatformTypeEnum_NONE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AcceptOfferGroupInputPlatformTypeEnum>
_$acceptOfferGroupInputPlatformTypeEnumValues =
    BuiltSet<AcceptOfferGroupInputPlatformTypeEnum>(
      const <AcceptOfferGroupInputPlatformTypeEnum>[
        _$acceptOfferGroupInputPlatformTypeEnum_DIDCOMM,
        _$acceptOfferGroupInputPlatformTypeEnum_PUSH_NOTIFICATION,
        _$acceptOfferGroupInputPlatformTypeEnum_NONE,
      ],
    );

Serializer<AcceptOfferGroupInputPlatformTypeEnum>
_$acceptOfferGroupInputPlatformTypeEnumSerializer =
    _$AcceptOfferGroupInputPlatformTypeEnumSerializer();

class _$AcceptOfferGroupInputPlatformTypeEnumSerializer
    implements PrimitiveSerializer<AcceptOfferGroupInputPlatformTypeEnum> {
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
    AcceptOfferGroupInputPlatformTypeEnum,
  ];
  @override
  final String wireName = 'AcceptOfferGroupInputPlatformTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    AcceptOfferGroupInputPlatformTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  AcceptOfferGroupInputPlatformTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AcceptOfferGroupInputPlatformTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$AcceptOfferGroupInput extends AcceptOfferGroupInput {
  @override
  final String mnemonic;
  @override
  final String did;
  @override
  final String deviceToken;
  @override
  final AcceptOfferGroupInputPlatformTypeEnum platformType;
  @override
  final String contactCard;
  @override
  final String offerLink;

  factory _$AcceptOfferGroupInput([
    void Function(AcceptOfferGroupInputBuilder)? updates,
  ]) => (AcceptOfferGroupInputBuilder()..update(updates))._build();

  _$AcceptOfferGroupInput._({
    required this.mnemonic,
    required this.did,
    required this.deviceToken,
    required this.platformType,
    required this.contactCard,
    required this.offerLink,
  }) : super._();
  @override
  AcceptOfferGroupInput rebuild(
    void Function(AcceptOfferGroupInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  AcceptOfferGroupInputBuilder toBuilder() =>
      AcceptOfferGroupInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcceptOfferGroupInput &&
        mnemonic == other.mnemonic &&
        did == other.did &&
        deviceToken == other.deviceToken &&
        platformType == other.platformType &&
        contactCard == other.contactCard &&
        offerLink == other.offerLink;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mnemonic.hashCode);
    _$hash = $jc(_$hash, did.hashCode);
    _$hash = $jc(_$hash, deviceToken.hashCode);
    _$hash = $jc(_$hash, platformType.hashCode);
    _$hash = $jc(_$hash, contactCard.hashCode);
    _$hash = $jc(_$hash, offerLink.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AcceptOfferGroupInput')
          ..add('mnemonic', mnemonic)
          ..add('did', did)
          ..add('deviceToken', deviceToken)
          ..add('platformType', platformType)
          ..add('contactCard', contactCard)
          ..add('offerLink', offerLink))
        .toString();
  }
}

class AcceptOfferGroupInputBuilder
    implements Builder<AcceptOfferGroupInput, AcceptOfferGroupInputBuilder> {
  _$AcceptOfferGroupInput? _$v;

  String? _mnemonic;
  String? get mnemonic => _$this._mnemonic;
  set mnemonic(String? mnemonic) => _$this._mnemonic = mnemonic;

  String? _did;
  String? get did => _$this._did;
  set did(String? did) => _$this._did = did;

  String? _deviceToken;
  String? get deviceToken => _$this._deviceToken;
  set deviceToken(String? deviceToken) => _$this._deviceToken = deviceToken;

  AcceptOfferGroupInputPlatformTypeEnum? _platformType;
  AcceptOfferGroupInputPlatformTypeEnum? get platformType =>
      _$this._platformType;
  set platformType(AcceptOfferGroupInputPlatformTypeEnum? platformType) =>
      _$this._platformType = platformType;

  String? _contactCard;
  String? get contactCard => _$this._contactCard;
  set contactCard(String? contactCard) => _$this._contactCard = contactCard;

  String? _offerLink;
  String? get offerLink => _$this._offerLink;
  set offerLink(String? offerLink) => _$this._offerLink = offerLink;

  AcceptOfferGroupInputBuilder() {
    AcceptOfferGroupInput._defaults(this);
  }

  AcceptOfferGroupInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mnemonic = $v.mnemonic;
      _did = $v.did;
      _deviceToken = $v.deviceToken;
      _platformType = $v.platformType;
      _contactCard = $v.contactCard;
      _offerLink = $v.offerLink;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AcceptOfferGroupInput other) {
    _$v = other as _$AcceptOfferGroupInput;
  }

  @override
  void update(void Function(AcceptOfferGroupInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcceptOfferGroupInput build() => _build();

  _$AcceptOfferGroupInput _build() {
    final _$result =
        _$v ??
        _$AcceptOfferGroupInput._(
          mnemonic: BuiltValueNullFieldError.checkNotNull(
            mnemonic,
            r'AcceptOfferGroupInput',
            'mnemonic',
          ),
          did: BuiltValueNullFieldError.checkNotNull(
            did,
            r'AcceptOfferGroupInput',
            'did',
          ),
          deviceToken: BuiltValueNullFieldError.checkNotNull(
            deviceToken,
            r'AcceptOfferGroupInput',
            'deviceToken',
          ),
          platformType: BuiltValueNullFieldError.checkNotNull(
            platformType,
            r'AcceptOfferGroupInput',
            'platformType',
          ),
          contactCard: BuiltValueNullFieldError.checkNotNull(
            contactCard,
            r'AcceptOfferGroupInput',
            'contactCard',
          ),
          offerLink: BuiltValueNullFieldError.checkNotNull(
            offerLink,
            r'AcceptOfferGroupInput',
            'offerLink',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

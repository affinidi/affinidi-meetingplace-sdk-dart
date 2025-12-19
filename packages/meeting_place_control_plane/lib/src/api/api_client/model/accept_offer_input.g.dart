// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_offer_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const AcceptOfferInputPlatformTypeEnum
_$acceptOfferInputPlatformTypeEnum_DIDCOMM =
    const AcceptOfferInputPlatformTypeEnum._('DIDCOMM');
const AcceptOfferInputPlatformTypeEnum
_$acceptOfferInputPlatformTypeEnum_PUSH_NOTIFICATION =
    const AcceptOfferInputPlatformTypeEnum._('PUSH_NOTIFICATION');
const AcceptOfferInputPlatformTypeEnum _$acceptOfferInputPlatformTypeEnum_NONE =
    const AcceptOfferInputPlatformTypeEnum._('NONE');

AcceptOfferInputPlatformTypeEnum _$acceptOfferInputPlatformTypeEnumValueOf(
  String name,
) {
  switch (name) {
    case 'DIDCOMM':
      return _$acceptOfferInputPlatformTypeEnum_DIDCOMM;
    case 'PUSH_NOTIFICATION':
      return _$acceptOfferInputPlatformTypeEnum_PUSH_NOTIFICATION;
    case 'NONE':
      return _$acceptOfferInputPlatformTypeEnum_NONE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<AcceptOfferInputPlatformTypeEnum>
_$acceptOfferInputPlatformTypeEnumValues =
    BuiltSet<AcceptOfferInputPlatformTypeEnum>(
      const <AcceptOfferInputPlatformTypeEnum>[
        _$acceptOfferInputPlatformTypeEnum_DIDCOMM,
        _$acceptOfferInputPlatformTypeEnum_PUSH_NOTIFICATION,
        _$acceptOfferInputPlatformTypeEnum_NONE,
      ],
    );

Serializer<AcceptOfferInputPlatformTypeEnum>
_$acceptOfferInputPlatformTypeEnumSerializer =
    _$AcceptOfferInputPlatformTypeEnumSerializer();

class _$AcceptOfferInputPlatformTypeEnumSerializer
    implements PrimitiveSerializer<AcceptOfferInputPlatformTypeEnum> {
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
  final Iterable<Type> types = const <Type>[AcceptOfferInputPlatformTypeEnum];
  @override
  final String wireName = 'AcceptOfferInputPlatformTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    AcceptOfferInputPlatformTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  AcceptOfferInputPlatformTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => AcceptOfferInputPlatformTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$AcceptOfferInput extends AcceptOfferInput {
  @override
  final String mnemonic;
  @override
  final String did;
  @override
  final String deviceToken;
  @override
  final AcceptOfferInputPlatformTypeEnum platformType;
  @override
  final String contactCard;
  @override
  final String offerLink;

  factory _$AcceptOfferInput([
    void Function(AcceptOfferInputBuilder)? updates,
  ]) => (AcceptOfferInputBuilder()..update(updates))._build();

  _$AcceptOfferInput._({
    required this.mnemonic,
    required this.did,
    required this.deviceToken,
    required this.platformType,
    required this.contactCard,
    required this.offerLink,
  }) : super._();
  @override
  AcceptOfferInput rebuild(void Function(AcceptOfferInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AcceptOfferInputBuilder toBuilder() =>
      AcceptOfferInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcceptOfferInput &&
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
    return (newBuiltValueToStringHelper(r'AcceptOfferInput')
          ..add('mnemonic', mnemonic)
          ..add('did', did)
          ..add('deviceToken', deviceToken)
          ..add('platformType', platformType)
          ..add('contactCard', contactCard)
          ..add('offerLink', offerLink))
        .toString();
  }
}

class AcceptOfferInputBuilder
    implements Builder<AcceptOfferInput, AcceptOfferInputBuilder> {
  _$AcceptOfferInput? _$v;

  String? _mnemonic;
  String? get mnemonic => _$this._mnemonic;
  set mnemonic(String? mnemonic) => _$this._mnemonic = mnemonic;

  String? _did;
  String? get did => _$this._did;
  set did(String? did) => _$this._did = did;

  String? _deviceToken;
  String? get deviceToken => _$this._deviceToken;
  set deviceToken(String? deviceToken) => _$this._deviceToken = deviceToken;

  AcceptOfferInputPlatformTypeEnum? _platformType;
  AcceptOfferInputPlatformTypeEnum? get platformType => _$this._platformType;
  set platformType(AcceptOfferInputPlatformTypeEnum? platformType) =>
      _$this._platformType = platformType;

  String? _contactCard;
  String? get contactCard => _$this._contactCard;
  set contactCard(String? contactCard) => _$this._contactCard = contactCard;

  String? _offerLink;
  String? get offerLink => _$this._offerLink;
  set offerLink(String? offerLink) => _$this._offerLink = offerLink;

  AcceptOfferInputBuilder() {
    AcceptOfferInput._defaults(this);
  }

  AcceptOfferInputBuilder get _$this {
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
  void replace(AcceptOfferInput other) {
    _$v = other as _$AcceptOfferInput;
  }

  @override
  void update(void Function(AcceptOfferInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcceptOfferInput build() => _build();

  _$AcceptOfferInput _build() {
    final _$result =
        _$v ??
        _$AcceptOfferInput._(
          mnemonic: BuiltValueNullFieldError.checkNotNull(
            mnemonic,
            r'AcceptOfferInput',
            'mnemonic',
          ),
          did: BuiltValueNullFieldError.checkNotNull(
            did,
            r'AcceptOfferInput',
            'did',
          ),
          deviceToken: BuiltValueNullFieldError.checkNotNull(
            deviceToken,
            r'AcceptOfferInput',
            'deviceToken',
          ),
          platformType: BuiltValueNullFieldError.checkNotNull(
            platformType,
            r'AcceptOfferInput',
            'platformType',
          ),
          contactCard: BuiltValueNullFieldError.checkNotNull(
            contactCard,
            r'AcceptOfferInput',
            'contactCard',
          ),
          offerLink: BuiltValueNullFieldError.checkNotNull(
            offerLink,
            r'AcceptOfferInput',
            'offerLink',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

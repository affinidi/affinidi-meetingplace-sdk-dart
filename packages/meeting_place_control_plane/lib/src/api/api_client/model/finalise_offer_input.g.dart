// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finalise_offer_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const FinaliseOfferInputPlatformTypeEnum
    _$finaliseOfferInputPlatformTypeEnum_DIDCOMM =
    const FinaliseOfferInputPlatformTypeEnum._('DIDCOMM');
const FinaliseOfferInputPlatformTypeEnum
    _$finaliseOfferInputPlatformTypeEnum_PUSH_NOTIFICATION =
    const FinaliseOfferInputPlatformTypeEnum._('PUSH_NOTIFICATION');
const FinaliseOfferInputPlatformTypeEnum
    _$finaliseOfferInputPlatformTypeEnum_NONE =
    const FinaliseOfferInputPlatformTypeEnum._('NONE');

FinaliseOfferInputPlatformTypeEnum _$finaliseOfferInputPlatformTypeEnumValueOf(
    String name) {
  switch (name) {
    case 'DIDCOMM':
      return _$finaliseOfferInputPlatformTypeEnum_DIDCOMM;
    case 'PUSH_NOTIFICATION':
      return _$finaliseOfferInputPlatformTypeEnum_PUSH_NOTIFICATION;
    case 'NONE':
      return _$finaliseOfferInputPlatformTypeEnum_NONE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<FinaliseOfferInputPlatformTypeEnum>
    _$finaliseOfferInputPlatformTypeEnumValues = BuiltSet<
        FinaliseOfferInputPlatformTypeEnum>(const <FinaliseOfferInputPlatformTypeEnum>[
  _$finaliseOfferInputPlatformTypeEnum_DIDCOMM,
  _$finaliseOfferInputPlatformTypeEnum_PUSH_NOTIFICATION,
  _$finaliseOfferInputPlatformTypeEnum_NONE,
]);

Serializer<FinaliseOfferInputPlatformTypeEnum>
    _$finaliseOfferInputPlatformTypeEnumSerializer =
    _$FinaliseOfferInputPlatformTypeEnumSerializer();

class _$FinaliseOfferInputPlatformTypeEnumSerializer
    implements PrimitiveSerializer<FinaliseOfferInputPlatformTypeEnum> {
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
  final Iterable<Type> types = const <Type>[FinaliseOfferInputPlatformTypeEnum];
  @override
  final String wireName = 'FinaliseOfferInputPlatformTypeEnum';

  @override
  Object serialize(
          Serializers serializers, FinaliseOfferInputPlatformTypeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  FinaliseOfferInputPlatformTypeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      FinaliseOfferInputPlatformTypeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$FinaliseOfferInput extends FinaliseOfferInput {
  @override
  final String mnemonic;
  @override
  final String did;
  @override
  final String offerLink;
  @override
  final String theirDid;
  @override
  final String? deviceToken;
  @override
  final FinaliseOfferInputPlatformTypeEnum? platformType;

  factory _$FinaliseOfferInput(
          [void Function(FinaliseOfferInputBuilder)? updates]) =>
      (FinaliseOfferInputBuilder()..update(updates))._build();

  _$FinaliseOfferInput._(
      {required this.mnemonic,
      required this.did,
      required this.offerLink,
      required this.theirDid,
      this.deviceToken,
      this.platformType})
      : super._();
  @override
  FinaliseOfferInput rebuild(
          void Function(FinaliseOfferInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FinaliseOfferInputBuilder toBuilder() =>
      FinaliseOfferInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FinaliseOfferInput &&
        mnemonic == other.mnemonic &&
        did == other.did &&
        offerLink == other.offerLink &&
        theirDid == other.theirDid &&
        deviceToken == other.deviceToken &&
        platformType == other.platformType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mnemonic.hashCode);
    _$hash = $jc(_$hash, did.hashCode);
    _$hash = $jc(_$hash, offerLink.hashCode);
    _$hash = $jc(_$hash, theirDid.hashCode);
    _$hash = $jc(_$hash, deviceToken.hashCode);
    _$hash = $jc(_$hash, platformType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FinaliseOfferInput')
          ..add('mnemonic', mnemonic)
          ..add('did', did)
          ..add('offerLink', offerLink)
          ..add('theirDid', theirDid)
          ..add('deviceToken', deviceToken)
          ..add('platformType', platformType))
        .toString();
  }
}

class FinaliseOfferInputBuilder
    implements Builder<FinaliseOfferInput, FinaliseOfferInputBuilder> {
  _$FinaliseOfferInput? _$v;

  String? _mnemonic;
  String? get mnemonic => _$this._mnemonic;
  set mnemonic(String? mnemonic) => _$this._mnemonic = mnemonic;

  String? _did;
  String? get did => _$this._did;
  set did(String? did) => _$this._did = did;

  String? _offerLink;
  String? get offerLink => _$this._offerLink;
  set offerLink(String? offerLink) => _$this._offerLink = offerLink;

  String? _theirDid;
  String? get theirDid => _$this._theirDid;
  set theirDid(String? theirDid) => _$this._theirDid = theirDid;

  String? _deviceToken;
  String? get deviceToken => _$this._deviceToken;
  set deviceToken(String? deviceToken) => _$this._deviceToken = deviceToken;

  FinaliseOfferInputPlatformTypeEnum? _platformType;
  FinaliseOfferInputPlatformTypeEnum? get platformType => _$this._platformType;
  set platformType(FinaliseOfferInputPlatformTypeEnum? platformType) =>
      _$this._platformType = platformType;

  FinaliseOfferInputBuilder() {
    FinaliseOfferInput._defaults(this);
  }

  FinaliseOfferInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mnemonic = $v.mnemonic;
      _did = $v.did;
      _offerLink = $v.offerLink;
      _theirDid = $v.theirDid;
      _deviceToken = $v.deviceToken;
      _platformType = $v.platformType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FinaliseOfferInput other) {
    _$v = other as _$FinaliseOfferInput;
  }

  @override
  void update(void Function(FinaliseOfferInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FinaliseOfferInput build() => _build();

  _$FinaliseOfferInput _build() {
    final _$result = _$v ??
        _$FinaliseOfferInput._(
          mnemonic: BuiltValueNullFieldError.checkNotNull(
              mnemonic, r'FinaliseOfferInput', 'mnemonic'),
          did: BuiltValueNullFieldError.checkNotNull(
              did, r'FinaliseOfferInput', 'did'),
          offerLink: BuiltValueNullFieldError.checkNotNull(
              offerLink, r'FinaliseOfferInput', 'offerLink'),
          theirDid: BuiltValueNullFieldError.checkNotNull(
              theirDid, r'FinaliseOfferInput', 'theirDid'),
          deviceToken: deviceToken,
          platformType: platformType,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

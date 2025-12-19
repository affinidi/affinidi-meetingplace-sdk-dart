// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_pending_notifications_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const GetPendingNotificationsInputPlatformTypeEnum
_$getPendingNotificationsInputPlatformTypeEnum_DIDCOMM =
    const GetPendingNotificationsInputPlatformTypeEnum._('DIDCOMM');
const GetPendingNotificationsInputPlatformTypeEnum
_$getPendingNotificationsInputPlatformTypeEnum_PUSH_NOTIFICATION =
    const GetPendingNotificationsInputPlatformTypeEnum._('PUSH_NOTIFICATION');
const GetPendingNotificationsInputPlatformTypeEnum
_$getPendingNotificationsInputPlatformTypeEnum_NONE =
    const GetPendingNotificationsInputPlatformTypeEnum._('NONE');

GetPendingNotificationsInputPlatformTypeEnum
_$getPendingNotificationsInputPlatformTypeEnumValueOf(String name) {
  switch (name) {
    case 'DIDCOMM':
      return _$getPendingNotificationsInputPlatformTypeEnum_DIDCOMM;
    case 'PUSH_NOTIFICATION':
      return _$getPendingNotificationsInputPlatformTypeEnum_PUSH_NOTIFICATION;
    case 'NONE':
      return _$getPendingNotificationsInputPlatformTypeEnum_NONE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<GetPendingNotificationsInputPlatformTypeEnum>
_$getPendingNotificationsInputPlatformTypeEnumValues =
    BuiltSet<GetPendingNotificationsInputPlatformTypeEnum>(
      const <GetPendingNotificationsInputPlatformTypeEnum>[
        _$getPendingNotificationsInputPlatformTypeEnum_DIDCOMM,
        _$getPendingNotificationsInputPlatformTypeEnum_PUSH_NOTIFICATION,
        _$getPendingNotificationsInputPlatformTypeEnum_NONE,
      ],
    );

Serializer<GetPendingNotificationsInputPlatformTypeEnum>
_$getPendingNotificationsInputPlatformTypeEnumSerializer =
    _$GetPendingNotificationsInputPlatformTypeEnumSerializer();

class _$GetPendingNotificationsInputPlatformTypeEnumSerializer
    implements
        PrimitiveSerializer<GetPendingNotificationsInputPlatformTypeEnum> {
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
    GetPendingNotificationsInputPlatformTypeEnum,
  ];
  @override
  final String wireName = 'GetPendingNotificationsInputPlatformTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    GetPendingNotificationsInputPlatformTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  GetPendingNotificationsInputPlatformTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => GetPendingNotificationsInputPlatformTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$GetPendingNotificationsInput extends GetPendingNotificationsInput {
  @override
  final String deviceToken;
  @override
  final GetPendingNotificationsInputPlatformTypeEnum platformType;

  factory _$GetPendingNotificationsInput([
    void Function(GetPendingNotificationsInputBuilder)? updates,
  ]) => (GetPendingNotificationsInputBuilder()..update(updates))._build();

  _$GetPendingNotificationsInput._({
    required this.deviceToken,
    required this.platformType,
  }) : super._();
  @override
  GetPendingNotificationsInput rebuild(
    void Function(GetPendingNotificationsInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GetPendingNotificationsInputBuilder toBuilder() =>
      GetPendingNotificationsInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetPendingNotificationsInput &&
        deviceToken == other.deviceToken &&
        platformType == other.platformType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, deviceToken.hashCode);
    _$hash = $jc(_$hash, platformType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GetPendingNotificationsInput')
          ..add('deviceToken', deviceToken)
          ..add('platformType', platformType))
        .toString();
  }
}

class GetPendingNotificationsInputBuilder
    implements
        Builder<
          GetPendingNotificationsInput,
          GetPendingNotificationsInputBuilder
        > {
  _$GetPendingNotificationsInput? _$v;

  String? _deviceToken;
  String? get deviceToken => _$this._deviceToken;
  set deviceToken(String? deviceToken) => _$this._deviceToken = deviceToken;

  GetPendingNotificationsInputPlatformTypeEnum? _platformType;
  GetPendingNotificationsInputPlatformTypeEnum? get platformType =>
      _$this._platformType;
  set platformType(
    GetPendingNotificationsInputPlatformTypeEnum? platformType,
  ) => _$this._platformType = platformType;

  GetPendingNotificationsInputBuilder() {
    GetPendingNotificationsInput._defaults(this);
  }

  GetPendingNotificationsInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _deviceToken = $v.deviceToken;
      _platformType = $v.platformType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetPendingNotificationsInput other) {
    _$v = other as _$GetPendingNotificationsInput;
  }

  @override
  void update(void Function(GetPendingNotificationsInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GetPendingNotificationsInput build() => _build();

  _$GetPendingNotificationsInput _build() {
    final _$result =
        _$v ??
        _$GetPendingNotificationsInput._(
          deviceToken: BuiltValueNullFieldError.checkNotNull(
            deviceToken,
            r'GetPendingNotificationsInput',
            'deviceToken',
          ),
          platformType: BuiltValueNullFieldError.checkNotNull(
            platformType,
            r'GetPendingNotificationsInput',
            'platformType',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

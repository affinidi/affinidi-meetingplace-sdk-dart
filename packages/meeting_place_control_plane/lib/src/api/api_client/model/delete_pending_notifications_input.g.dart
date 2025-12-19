// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_pending_notifications_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const DeletePendingNotificationsInputPlatformTypeEnum
_$deletePendingNotificationsInputPlatformTypeEnum_DIDCOMM =
    const DeletePendingNotificationsInputPlatformTypeEnum._('DIDCOMM');
const DeletePendingNotificationsInputPlatformTypeEnum
_$deletePendingNotificationsInputPlatformTypeEnum_PUSH_NOTIFICATION =
    const DeletePendingNotificationsInputPlatformTypeEnum._(
      'PUSH_NOTIFICATION',
    );
const DeletePendingNotificationsInputPlatformTypeEnum
_$deletePendingNotificationsInputPlatformTypeEnum_NONE =
    const DeletePendingNotificationsInputPlatformTypeEnum._('NONE');

DeletePendingNotificationsInputPlatformTypeEnum
_$deletePendingNotificationsInputPlatformTypeEnumValueOf(String name) {
  switch (name) {
    case 'DIDCOMM':
      return _$deletePendingNotificationsInputPlatformTypeEnum_DIDCOMM;
    case 'PUSH_NOTIFICATION':
      return _$deletePendingNotificationsInputPlatformTypeEnum_PUSH_NOTIFICATION;
    case 'NONE':
      return _$deletePendingNotificationsInputPlatformTypeEnum_NONE;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<DeletePendingNotificationsInputPlatformTypeEnum>
_$deletePendingNotificationsInputPlatformTypeEnumValues =
    BuiltSet<DeletePendingNotificationsInputPlatformTypeEnum>(
      const <DeletePendingNotificationsInputPlatformTypeEnum>[
        _$deletePendingNotificationsInputPlatformTypeEnum_DIDCOMM,
        _$deletePendingNotificationsInputPlatformTypeEnum_PUSH_NOTIFICATION,
        _$deletePendingNotificationsInputPlatformTypeEnum_NONE,
      ],
    );

Serializer<DeletePendingNotificationsInputPlatformTypeEnum>
_$deletePendingNotificationsInputPlatformTypeEnumSerializer =
    _$DeletePendingNotificationsInputPlatformTypeEnumSerializer();

class _$DeletePendingNotificationsInputPlatformTypeEnumSerializer
    implements
        PrimitiveSerializer<DeletePendingNotificationsInputPlatformTypeEnum> {
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
    DeletePendingNotificationsInputPlatformTypeEnum,
  ];
  @override
  final String wireName = 'DeletePendingNotificationsInputPlatformTypeEnum';

  @override
  Object serialize(
    Serializers serializers,
    DeletePendingNotificationsInputPlatformTypeEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  DeletePendingNotificationsInputPlatformTypeEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => DeletePendingNotificationsInputPlatformTypeEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$DeletePendingNotificationsInput
    extends DeletePendingNotificationsInput {
  @override
  final BuiltList<String> notificationIds;
  @override
  final String deviceToken;
  @override
  final DeletePendingNotificationsInputPlatformTypeEnum platformType;

  factory _$DeletePendingNotificationsInput([
    void Function(DeletePendingNotificationsInputBuilder)? updates,
  ]) => (DeletePendingNotificationsInputBuilder()..update(updates))._build();

  _$DeletePendingNotificationsInput._({
    required this.notificationIds,
    required this.deviceToken,
    required this.platformType,
  }) : super._();
  @override
  DeletePendingNotificationsInput rebuild(
    void Function(DeletePendingNotificationsInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DeletePendingNotificationsInputBuilder toBuilder() =>
      DeletePendingNotificationsInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeletePendingNotificationsInput &&
        notificationIds == other.notificationIds &&
        deviceToken == other.deviceToken &&
        platformType == other.platformType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, notificationIds.hashCode);
    _$hash = $jc(_$hash, deviceToken.hashCode);
    _$hash = $jc(_$hash, platformType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeletePendingNotificationsInput')
          ..add('notificationIds', notificationIds)
          ..add('deviceToken', deviceToken)
          ..add('platformType', platformType))
        .toString();
  }
}

class DeletePendingNotificationsInputBuilder
    implements
        Builder<
          DeletePendingNotificationsInput,
          DeletePendingNotificationsInputBuilder
        > {
  _$DeletePendingNotificationsInput? _$v;

  ListBuilder<String>? _notificationIds;
  ListBuilder<String> get notificationIds =>
      _$this._notificationIds ??= ListBuilder<String>();
  set notificationIds(ListBuilder<String>? notificationIds) =>
      _$this._notificationIds = notificationIds;

  String? _deviceToken;
  String? get deviceToken => _$this._deviceToken;
  set deviceToken(String? deviceToken) => _$this._deviceToken = deviceToken;

  DeletePendingNotificationsInputPlatformTypeEnum? _platformType;
  DeletePendingNotificationsInputPlatformTypeEnum? get platformType =>
      _$this._platformType;
  set platformType(
    DeletePendingNotificationsInputPlatformTypeEnum? platformType,
  ) => _$this._platformType = platformType;

  DeletePendingNotificationsInputBuilder() {
    DeletePendingNotificationsInput._defaults(this);
  }

  DeletePendingNotificationsInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _notificationIds = $v.notificationIds.toBuilder();
      _deviceToken = $v.deviceToken;
      _platformType = $v.platformType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeletePendingNotificationsInput other) {
    _$v = other as _$DeletePendingNotificationsInput;
  }

  @override
  void update(void Function(DeletePendingNotificationsInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeletePendingNotificationsInput build() => _build();

  _$DeletePendingNotificationsInput _build() {
    _$DeletePendingNotificationsInput _$result;
    try {
      _$result =
          _$v ??
          _$DeletePendingNotificationsInput._(
            notificationIds: notificationIds.build(),
            deviceToken: BuiltValueNullFieldError.checkNotNull(
              deviceToken,
              r'DeletePendingNotificationsInput',
              'deviceToken',
            ),
            platformType: BuiltValueNullFieldError.checkNotNull(
              platformType,
              r'DeletePendingNotificationsInput',
              'platformType',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'notificationIds';
        notificationIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DeletePendingNotificationsInput',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

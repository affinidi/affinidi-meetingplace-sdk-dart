// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_channel_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyChannelInput extends NotifyChannelInput {
  @override
  final String notificationChannelId;
  @override
  final String did;
  @override
  final String type;

  factory _$NotifyChannelInput(
          [void Function(NotifyChannelInputBuilder)? updates]) =>
      (NotifyChannelInputBuilder()..update(updates))._build();

  _$NotifyChannelInput._(
      {required this.notificationChannelId,
      required this.did,
      required this.type})
      : super._();
  @override
  NotifyChannelInput rebuild(
          void Function(NotifyChannelInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  NotifyChannelInputBuilder toBuilder() =>
      NotifyChannelInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyChannelInput &&
        notificationChannelId == other.notificationChannelId &&
        did == other.did &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, notificationChannelId.hashCode);
    _$hash = $jc(_$hash, did.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyChannelInput')
          ..add('notificationChannelId', notificationChannelId)
          ..add('did', did)
          ..add('type', type))
        .toString();
  }
}

class NotifyChannelInputBuilder
    implements Builder<NotifyChannelInput, NotifyChannelInputBuilder> {
  _$NotifyChannelInput? _$v;

  String? _notificationChannelId;
  String? get notificationChannelId => _$this._notificationChannelId;
  set notificationChannelId(String? notificationChannelId) =>
      _$this._notificationChannelId = notificationChannelId;

  String? _did;
  String? get did => _$this._did;
  set did(String? did) => _$this._did = did;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  NotifyChannelInputBuilder() {
    NotifyChannelInput._defaults(this);
  }

  NotifyChannelInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _notificationChannelId = $v.notificationChannelId;
      _did = $v.did;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyChannelInput other) {
    _$v = other as _$NotifyChannelInput;
  }

  @override
  void update(void Function(NotifyChannelInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyChannelInput build() => _build();

  _$NotifyChannelInput _build() {
    final _$result = _$v ??
        _$NotifyChannelInput._(
          notificationChannelId: BuiltValueNullFieldError.checkNotNull(
              notificationChannelId,
              r'NotifyChannelInput',
              'notificationChannelId'),
          did: BuiltValueNullFieldError.checkNotNull(
              did, r'NotifyChannelInput', 'did'),
          type: BuiltValueNullFieldError.checkNotNull(
              type, r'NotifyChannelInput', 'type'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

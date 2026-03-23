// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_channel_group_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyChannelGroupInput extends NotifyChannelGroupInput {
  @override
  final String groupId;
  @override
  final String type;

  factory _$NotifyChannelGroupInput([
    void Function(NotifyChannelGroupInputBuilder)? updates,
  ]) => (NotifyChannelGroupInputBuilder()..update(updates))._build();

  _$NotifyChannelGroupInput._({required this.groupId, required this.type})
    : super._();
  @override
  NotifyChannelGroupInput rebuild(
    void Function(NotifyChannelGroupInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyChannelGroupInputBuilder toBuilder() =>
      NotifyChannelGroupInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyChannelGroupInput &&
        groupId == other.groupId &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'NotifyChannelGroupInput')
          ..add('groupId', groupId)
          ..add('type', type))
        .toString();
  }
}

class NotifyChannelGroupInputBuilder
    implements
        Builder<NotifyChannelGroupInput, NotifyChannelGroupInputBuilder> {
  _$NotifyChannelGroupInput? _$v;

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  NotifyChannelGroupInputBuilder() {
    NotifyChannelGroupInput._defaults(this);
  }

  NotifyChannelGroupInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _groupId = $v.groupId;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyChannelGroupInput other) {
    _$v = other as _$NotifyChannelGroupInput;
  }

  @override
  void update(void Function(NotifyChannelGroupInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyChannelGroupInput build() => _build();

  _$NotifyChannelGroupInput _build() {
    final _$result =
        _$v ??
        _$NotifyChannelGroupInput._(
          groupId: BuiltValueNullFieldError.checkNotNull(
            groupId,
            r'NotifyChannelGroupInput',
            'groupId',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'NotifyChannelGroupInput',
            'type',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

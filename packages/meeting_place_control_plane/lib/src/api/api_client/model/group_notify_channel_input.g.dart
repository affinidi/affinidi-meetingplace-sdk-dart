// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_notify_channel_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupNotifyChannelInput extends GroupNotifyChannelInput {
  @override
  final String groupId;
  @override
  final String type;
  @override
  final String? memberDid;

  factory _$GroupNotifyChannelInput([
    void Function(GroupNotifyChannelInputBuilder)? updates,
  ]) => (GroupNotifyChannelInputBuilder()..update(updates))._build();

  _$GroupNotifyChannelInput._({
    required this.groupId,
    required this.type,
    this.memberDid,
  }) : super._();
  @override
  GroupNotifyChannelInput rebuild(
    void Function(GroupNotifyChannelInputBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  GroupNotifyChannelInputBuilder toBuilder() =>
      GroupNotifyChannelInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupNotifyChannelInput &&
        groupId == other.groupId &&
        type == other.type &&
        memberDid == other.memberDid;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, memberDid.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GroupNotifyChannelInput')
          ..add('groupId', groupId)
          ..add('type', type)
          ..add('memberDid', memberDid))
        .toString();
  }
}

class GroupNotifyChannelInputBuilder
    implements
        Builder<GroupNotifyChannelInput, GroupNotifyChannelInputBuilder> {
  _$GroupNotifyChannelInput? _$v;

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  String? _memberDid;
  String? get memberDid => _$this._memberDid;
  set memberDid(String? memberDid) => _$this._memberDid = memberDid;

  GroupNotifyChannelInputBuilder() {
    GroupNotifyChannelInput._defaults(this);
  }

  GroupNotifyChannelInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _groupId = $v.groupId;
      _type = $v.type;
      _memberDid = $v.memberDid;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupNotifyChannelInput other) {
    _$v = other as _$GroupNotifyChannelInput;
  }

  @override
  void update(void Function(GroupNotifyChannelInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupNotifyChannelInput build() => _build();

  _$GroupNotifyChannelInput _build() {
    final _$result =
        _$v ??
        _$GroupNotifyChannelInput._(
          groupId: BuiltValueNullFieldError.checkNotNull(
            groupId,
            r'GroupNotifyChannelInput',
            'groupId',
          ),
          type: BuiltValueNullFieldError.checkNotNull(
            type,
            r'GroupNotifyChannelInput',
            'type',
          ),
          memberDid: memberDid,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

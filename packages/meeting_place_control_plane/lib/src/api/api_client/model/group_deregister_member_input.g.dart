// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_deregister_member_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupDeregisterMemberInput extends GroupDeregisterMemberInput {
  @override
  final String memberDid;
  @override
  final String groupId;
  @override
  final String? messageToRelay;

  factory _$GroupDeregisterMemberInput(
          [void Function(GroupDeregisterMemberInputBuilder)? updates]) =>
      (GroupDeregisterMemberInputBuilder()..update(updates))._build();

  _$GroupDeregisterMemberInput._(
      {required this.memberDid, required this.groupId, this.messageToRelay})
      : super._();
  @override
  GroupDeregisterMemberInput rebuild(
          void Function(GroupDeregisterMemberInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GroupDeregisterMemberInputBuilder toBuilder() =>
      GroupDeregisterMemberInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupDeregisterMemberInput &&
        memberDid == other.memberDid &&
        groupId == other.groupId &&
        messageToRelay == other.messageToRelay;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, memberDid.hashCode);
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, messageToRelay.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GroupDeregisterMemberInput')
          ..add('memberDid', memberDid)
          ..add('groupId', groupId)
          ..add('messageToRelay', messageToRelay))
        .toString();
  }
}

class GroupDeregisterMemberInputBuilder
    implements
        Builder<GroupDeregisterMemberInput, GroupDeregisterMemberInputBuilder> {
  _$GroupDeregisterMemberInput? _$v;

  String? _memberDid;
  String? get memberDid => _$this._memberDid;
  set memberDid(String? memberDid) => _$this._memberDid = memberDid;

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  String? _messageToRelay;
  String? get messageToRelay => _$this._messageToRelay;
  set messageToRelay(String? messageToRelay) =>
      _$this._messageToRelay = messageToRelay;

  GroupDeregisterMemberInputBuilder() {
    GroupDeregisterMemberInput._defaults(this);
  }

  GroupDeregisterMemberInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _memberDid = $v.memberDid;
      _groupId = $v.groupId;
      _messageToRelay = $v.messageToRelay;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupDeregisterMemberInput other) {
    _$v = other as _$GroupDeregisterMemberInput;
  }

  @override
  void update(void Function(GroupDeregisterMemberInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupDeregisterMemberInput build() => _build();

  _$GroupDeregisterMemberInput _build() {
    final _$result = _$v ??
        _$GroupDeregisterMemberInput._(
          memberDid: BuiltValueNullFieldError.checkNotNull(
              memberDid, r'GroupDeregisterMemberInput', 'memberDid'),
          groupId: BuiltValueNullFieldError.checkNotNull(
              groupId, r'GroupDeregisterMemberInput', 'groupId'),
          messageToRelay: messageToRelay,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

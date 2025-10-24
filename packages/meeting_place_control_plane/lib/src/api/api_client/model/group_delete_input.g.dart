// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_delete_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupDeleteInput extends GroupDeleteInput {
  @override
  final String groupId;
  @override
  final String messageToRelay;

  factory _$GroupDeleteInput(
          [void Function(GroupDeleteInputBuilder)? updates]) =>
      (GroupDeleteInputBuilder()..update(updates))._build();

  _$GroupDeleteInput._({required this.groupId, required this.messageToRelay})
      : super._();
  @override
  GroupDeleteInput rebuild(void Function(GroupDeleteInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GroupDeleteInputBuilder toBuilder() =>
      GroupDeleteInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupDeleteInput &&
        groupId == other.groupId &&
        messageToRelay == other.messageToRelay;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, messageToRelay.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GroupDeleteInput')
          ..add('groupId', groupId)
          ..add('messageToRelay', messageToRelay))
        .toString();
  }
}

class GroupDeleteInputBuilder
    implements Builder<GroupDeleteInput, GroupDeleteInputBuilder> {
  _$GroupDeleteInput? _$v;

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  String? _messageToRelay;
  String? get messageToRelay => _$this._messageToRelay;
  set messageToRelay(String? messageToRelay) =>
      _$this._messageToRelay = messageToRelay;

  GroupDeleteInputBuilder() {
    GroupDeleteInput._defaults(this);
  }

  GroupDeleteInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _groupId = $v.groupId;
      _messageToRelay = $v.messageToRelay;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupDeleteInput other) {
    _$v = other as _$GroupDeleteInput;
  }

  @override
  void update(void Function(GroupDeleteInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupDeleteInput build() => _build();

  _$GroupDeleteInput _build() {
    final _$result = _$v ??
        _$GroupDeleteInput._(
          groupId: BuiltValueNullFieldError.checkNotNull(
              groupId, r'GroupDeleteInput', 'groupId'),
          messageToRelay: BuiltValueNullFieldError.checkNotNull(
              messageToRelay, r'GroupDeleteInput', 'messageToRelay'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

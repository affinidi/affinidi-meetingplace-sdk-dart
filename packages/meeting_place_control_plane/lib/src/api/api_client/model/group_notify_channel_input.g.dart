// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_notify_channel_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupNotifyChannelInput extends GroupNotifyChannelInput {
  @override
  final String offerLink;
  @override
  final String groupDid;
  @override
  final String type;
  @override
  final String? memberDid;

  factory _$GroupNotifyChannelInput([
    void Function(GroupNotifyChannelInputBuilder)? updates,
  ]) => (GroupNotifyChannelInputBuilder()..update(updates))._build();

  _$GroupNotifyChannelInput._({
    required this.offerLink,
    required this.groupDid,
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
        offerLink == other.offerLink &&
        groupDid == other.groupDid &&
        type == other.type &&
        memberDid == other.memberDid;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, offerLink.hashCode);
    _$hash = $jc(_$hash, groupDid.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, memberDid.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GroupNotifyChannelInput')
          ..add('offerLink', offerLink)
          ..add('groupDid', groupDid)
          ..add('type', type)
          ..add('memberDid', memberDid))
        .toString();
  }
}

class GroupNotifyChannelInputBuilder
    implements
        Builder<GroupNotifyChannelInput, GroupNotifyChannelInputBuilder> {
  _$GroupNotifyChannelInput? _$v;

  String? _offerLink;
  String? get offerLink => _$this._offerLink;
  set offerLink(String? offerLink) => _$this._offerLink = offerLink;

  String? _groupDid;
  String? get groupDid => _$this._groupDid;
  set groupDid(String? groupDid) => _$this._groupDid = groupDid;

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
      _offerLink = $v.offerLink;
      _groupDid = $v.groupDid;
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
          offerLink: BuiltValueNullFieldError.checkNotNull(
            offerLink,
            r'GroupNotifyChannelInput',
            'offerLink',
          ),
          groupDid: BuiltValueNullFieldError.checkNotNull(
            groupDid,
            r'GroupNotifyChannelInput',
            'groupDid',
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

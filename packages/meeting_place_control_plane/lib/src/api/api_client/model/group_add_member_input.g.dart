// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_add_member_input.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupAddMemberInput extends GroupAddMemberInput {
  @override
  final String mnemonic;
  @override
  final String offerLink;
  @override
  final String groupId;
  @override
  final String memberDid;
  @override
  final String acceptOfferAsDid;
  @override
  final String reencryptionKey;
  @override
  final String publicKey;
  @override
  final String contactCard;

  factory _$GroupAddMemberInput(
          [void Function(GroupAddMemberInputBuilder)? updates]) =>
      (GroupAddMemberInputBuilder()..update(updates))._build();

  _$GroupAddMemberInput._(
      {required this.mnemonic,
      required this.offerLink,
      required this.groupId,
      required this.memberDid,
      required this.acceptOfferAsDid,
      required this.reencryptionKey,
      required this.publicKey,
      required this.contactCard})
      : super._();
  @override
  GroupAddMemberInput rebuild(
          void Function(GroupAddMemberInputBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GroupAddMemberInputBuilder toBuilder() =>
      GroupAddMemberInputBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupAddMemberInput &&
        mnemonic == other.mnemonic &&
        offerLink == other.offerLink &&
        groupId == other.groupId &&
        memberDid == other.memberDid &&
        acceptOfferAsDid == other.acceptOfferAsDid &&
        reencryptionKey == other.reencryptionKey &&
        publicKey == other.publicKey &&
        contactCard == other.contactCard;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mnemonic.hashCode);
    _$hash = $jc(_$hash, offerLink.hashCode);
    _$hash = $jc(_$hash, groupId.hashCode);
    _$hash = $jc(_$hash, memberDid.hashCode);
    _$hash = $jc(_$hash, acceptOfferAsDid.hashCode);
    _$hash = $jc(_$hash, reencryptionKey.hashCode);
    _$hash = $jc(_$hash, publicKey.hashCode);
    _$hash = $jc(_$hash, contactCard.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GroupAddMemberInput')
          ..add('mnemonic', mnemonic)
          ..add('offerLink', offerLink)
          ..add('groupId', groupId)
          ..add('memberDid', memberDid)
          ..add('acceptOfferAsDid', acceptOfferAsDid)
          ..add('reencryptionKey', reencryptionKey)
          ..add('publicKey', publicKey)
          ..add('contactCard', contactCard))
        .toString();
  }
}

class GroupAddMemberInputBuilder
    implements Builder<GroupAddMemberInput, GroupAddMemberInputBuilder> {
  _$GroupAddMemberInput? _$v;

  String? _mnemonic;
  String? get mnemonic => _$this._mnemonic;
  set mnemonic(String? mnemonic) => _$this._mnemonic = mnemonic;

  String? _offerLink;
  String? get offerLink => _$this._offerLink;
  set offerLink(String? offerLink) => _$this._offerLink = offerLink;

  String? _groupId;
  String? get groupId => _$this._groupId;
  set groupId(String? groupId) => _$this._groupId = groupId;

  String? _memberDid;
  String? get memberDid => _$this._memberDid;
  set memberDid(String? memberDid) => _$this._memberDid = memberDid;

  String? _acceptOfferAsDid;
  String? get acceptOfferAsDid => _$this._acceptOfferAsDid;
  set acceptOfferAsDid(String? acceptOfferAsDid) =>
      _$this._acceptOfferAsDid = acceptOfferAsDid;

  String? _reencryptionKey;
  String? get reencryptionKey => _$this._reencryptionKey;
  set reencryptionKey(String? reencryptionKey) =>
      _$this._reencryptionKey = reencryptionKey;

  String? _publicKey;
  String? get publicKey => _$this._publicKey;
  set publicKey(String? publicKey) => _$this._publicKey = publicKey;

  String? _contactCard;
  String? get contactCard => _$this._contactCard;
  set contactCard(String? contactCard) => _$this._contactCard = contactCard;

  GroupAddMemberInputBuilder() {
    GroupAddMemberInput._defaults(this);
  }

  GroupAddMemberInputBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mnemonic = $v.mnemonic;
      _offerLink = $v.offerLink;
      _groupId = $v.groupId;
      _memberDid = $v.memberDid;
      _acceptOfferAsDid = $v.acceptOfferAsDid;
      _reencryptionKey = $v.reencryptionKey;
      _publicKey = $v.publicKey;
      _contactCard = $v.contactCard;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupAddMemberInput other) {
    _$v = other as _$GroupAddMemberInput;
  }

  @override
  void update(void Function(GroupAddMemberInputBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupAddMemberInput build() => _build();

  _$GroupAddMemberInput _build() {
    final _$result = _$v ??
        _$GroupAddMemberInput._(
          mnemonic: BuiltValueNullFieldError.checkNotNull(
              mnemonic, r'GroupAddMemberInput', 'mnemonic'),
          offerLink: BuiltValueNullFieldError.checkNotNull(
              offerLink, r'GroupAddMemberInput', 'offerLink'),
          groupId: BuiltValueNullFieldError.checkNotNull(
              groupId, r'GroupAddMemberInput', 'groupId'),
          memberDid: BuiltValueNullFieldError.checkNotNull(
              memberDid, r'GroupAddMemberInput', 'memberDid'),
          acceptOfferAsDid: BuiltValueNullFieldError.checkNotNull(
              acceptOfferAsDid, r'GroupAddMemberInput', 'acceptOfferAsDid'),
          reencryptionKey: BuiltValueNullFieldError.checkNotNull(
              reencryptionKey, r'GroupAddMemberInput', 'reencryptionKey'),
          publicKey: BuiltValueNullFieldError.checkNotNull(
              publicKey, r'GroupAddMemberInput', 'publicKey'),
          contactCard: BuiltValueNullFieldError.checkNotNull(
              contactCard, r'GroupAddMemberInput', 'contactCard'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

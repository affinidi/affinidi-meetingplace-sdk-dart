// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'groups_database.dart';

// ignore_for_file: type=lint
class $MeetingPlaceGroupsTable extends MeetingPlaceGroups
    with TableInfo<$MeetingPlaceGroupsTable, MeetingPlaceGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MeetingPlaceGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _didMeta = const VerificationMeta('did');
  @override
  late final GeneratedColumn<String> did = GeneratedColumn<String>(
      'did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _offerLinkMeta =
      const VerificationMeta('offerLink');
  @override
  late final GeneratedColumn<String> offerLink = GeneratedColumn<String>(
      'offer_link', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<GroupStatus, int> status =
      GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<GroupStatus>(
              $MeetingPlaceGroupsTable.$converterstatus);
  static const VerificationMeta _createdMeta =
      const VerificationMeta('created');
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
      'created', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _groupKeyPairMeta =
      const VerificationMeta('groupKeyPair');
  @override
  late final GeneratedColumn<String> groupKeyPair = GeneratedColumn<String>(
      'group_key_pair', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _publicKeyMeta =
      const VerificationMeta('publicKey');
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
      'public_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ownerDidMeta =
      const VerificationMeta('ownerDid');
  @override
  late final GeneratedColumn<String> ownerDid = GeneratedColumn<String>(
      'owner_did', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, did, offerLink, status, created, groupKeyPair, publicKey, ownerDid];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meeting_place_groups';
  @override
  VerificationContext validateIntegrity(Insertable<MeetingPlaceGroup> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('did')) {
      context.handle(
          _didMeta, did.isAcceptableOrUnknown(data['did']!, _didMeta));
    } else if (isInserting) {
      context.missing(_didMeta);
    }
    if (data.containsKey('offer_link')) {
      context.handle(_offerLinkMeta,
          offerLink.isAcceptableOrUnknown(data['offer_link']!, _offerLinkMeta));
    } else if (isInserting) {
      context.missing(_offerLinkMeta);
    }
    if (data.containsKey('created')) {
      context.handle(_createdMeta,
          created.isAcceptableOrUnknown(data['created']!, _createdMeta));
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('group_key_pair')) {
      context.handle(
          _groupKeyPairMeta,
          groupKeyPair.isAcceptableOrUnknown(
              data['group_key_pair']!, _groupKeyPairMeta));
    }
    if (data.containsKey('public_key')) {
      context.handle(_publicKeyMeta,
          publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta));
    }
    if (data.containsKey('owner_did')) {
      context.handle(_ownerDidMeta,
          ownerDid.isAcceptableOrUnknown(data['owner_did']!, _ownerDidMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MeetingPlaceGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MeetingPlaceGroup(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      did: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}did'])!,
      offerLink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}offer_link'])!,
      status: $MeetingPlaceGroupsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      created: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created'])!,
      groupKeyPair: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_key_pair']),
      publicKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}public_key']),
      ownerDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_did']),
    );
  }

  @override
  $MeetingPlaceGroupsTable createAlias(String alias) {
    return $MeetingPlaceGroupsTable(attachedDatabase, alias);
  }

  static TypeConverter<GroupStatus, int> $converterstatus =
      const _GroupStatusConverter();
}

class MeetingPlaceGroup extends DataClass
    implements Insertable<MeetingPlaceGroup> {
  /// The unique identifier for the group.
  final String id;

  /// The DID of the group.
  final String did;

  /// The offer link associated with the group.
  final String offerLink;

  /// The status of the group.
  final GroupStatus status;

  /// The date and time when the group was created.
  final DateTime created;

  /// The key pair associated with the group.
  final String? groupKeyPair;

  /// The public key of the group.
  final String? publicKey;

  /// The DID of the owner of the group.
  final String? ownerDid;
  const MeetingPlaceGroup(
      {required this.id,
      required this.did,
      required this.offerLink,
      required this.status,
      required this.created,
      this.groupKeyPair,
      this.publicKey,
      this.ownerDid});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['did'] = Variable<String>(did);
    map['offer_link'] = Variable<String>(offerLink);
    {
      map['status'] = Variable<int>(
          $MeetingPlaceGroupsTable.$converterstatus.toSql(status));
    }
    map['created'] = Variable<DateTime>(created);
    if (!nullToAbsent || groupKeyPair != null) {
      map['group_key_pair'] = Variable<String>(groupKeyPair);
    }
    if (!nullToAbsent || publicKey != null) {
      map['public_key'] = Variable<String>(publicKey);
    }
    if (!nullToAbsent || ownerDid != null) {
      map['owner_did'] = Variable<String>(ownerDid);
    }
    return map;
  }

  MeetingPlaceGroupsCompanion toCompanion(bool nullToAbsent) {
    return MeetingPlaceGroupsCompanion(
      id: Value(id),
      did: Value(did),
      offerLink: Value(offerLink),
      status: Value(status),
      created: Value(created),
      groupKeyPair: groupKeyPair == null && nullToAbsent
          ? const Value.absent()
          : Value(groupKeyPair),
      publicKey: publicKey == null && nullToAbsent
          ? const Value.absent()
          : Value(publicKey),
      ownerDid: ownerDid == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerDid),
    );
  }

  factory MeetingPlaceGroup.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MeetingPlaceGroup(
      id: serializer.fromJson<String>(json['id']),
      did: serializer.fromJson<String>(json['did']),
      offerLink: serializer.fromJson<String>(json['offerLink']),
      status: serializer.fromJson<GroupStatus>(json['status']),
      created: serializer.fromJson<DateTime>(json['created']),
      groupKeyPair: serializer.fromJson<String?>(json['groupKeyPair']),
      publicKey: serializer.fromJson<String?>(json['publicKey']),
      ownerDid: serializer.fromJson<String?>(json['ownerDid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'did': serializer.toJson<String>(did),
      'offerLink': serializer.toJson<String>(offerLink),
      'status': serializer.toJson<GroupStatus>(status),
      'created': serializer.toJson<DateTime>(created),
      'groupKeyPair': serializer.toJson<String?>(groupKeyPair),
      'publicKey': serializer.toJson<String?>(publicKey),
      'ownerDid': serializer.toJson<String?>(ownerDid),
    };
  }

  MeetingPlaceGroup copyWith(
          {String? id,
          String? did,
          String? offerLink,
          GroupStatus? status,
          DateTime? created,
          Value<String?> groupKeyPair = const Value.absent(),
          Value<String?> publicKey = const Value.absent(),
          Value<String?> ownerDid = const Value.absent()}) =>
      MeetingPlaceGroup(
        id: id ?? this.id,
        did: did ?? this.did,
        offerLink: offerLink ?? this.offerLink,
        status: status ?? this.status,
        created: created ?? this.created,
        groupKeyPair:
            groupKeyPair.present ? groupKeyPair.value : this.groupKeyPair,
        publicKey: publicKey.present ? publicKey.value : this.publicKey,
        ownerDid: ownerDid.present ? ownerDid.value : this.ownerDid,
      );
  MeetingPlaceGroup copyWithCompanion(MeetingPlaceGroupsCompanion data) {
    return MeetingPlaceGroup(
      id: data.id.present ? data.id.value : this.id,
      did: data.did.present ? data.did.value : this.did,
      offerLink: data.offerLink.present ? data.offerLink.value : this.offerLink,
      status: data.status.present ? data.status.value : this.status,
      created: data.created.present ? data.created.value : this.created,
      groupKeyPair: data.groupKeyPair.present
          ? data.groupKeyPair.value
          : this.groupKeyPair,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      ownerDid: data.ownerDid.present ? data.ownerDid.value : this.ownerDid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MeetingPlaceGroup(')
          ..write('id: $id, ')
          ..write('did: $did, ')
          ..write('offerLink: $offerLink, ')
          ..write('status: $status, ')
          ..write('created: $created, ')
          ..write('groupKeyPair: $groupKeyPair, ')
          ..write('publicKey: $publicKey, ')
          ..write('ownerDid: $ownerDid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, did, offerLink, status, created, groupKeyPair, publicKey, ownerDid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MeetingPlaceGroup &&
          other.id == this.id &&
          other.did == this.did &&
          other.offerLink == this.offerLink &&
          other.status == this.status &&
          other.created == this.created &&
          other.groupKeyPair == this.groupKeyPair &&
          other.publicKey == this.publicKey &&
          other.ownerDid == this.ownerDid);
}

class MeetingPlaceGroupsCompanion extends UpdateCompanion<MeetingPlaceGroup> {
  final Value<String> id;
  final Value<String> did;
  final Value<String> offerLink;
  final Value<GroupStatus> status;
  final Value<DateTime> created;
  final Value<String?> groupKeyPair;
  final Value<String?> publicKey;
  final Value<String?> ownerDid;
  final Value<int> rowid;
  const MeetingPlaceGroupsCompanion({
    this.id = const Value.absent(),
    this.did = const Value.absent(),
    this.offerLink = const Value.absent(),
    this.status = const Value.absent(),
    this.created = const Value.absent(),
    this.groupKeyPair = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.ownerDid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MeetingPlaceGroupsCompanion.insert({
    required String id,
    required String did,
    required String offerLink,
    required GroupStatus status,
    required DateTime created,
    this.groupKeyPair = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.ownerDid = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        did = Value(did),
        offerLink = Value(offerLink),
        status = Value(status),
        created = Value(created);
  static Insertable<MeetingPlaceGroup> custom({
    Expression<String>? id,
    Expression<String>? did,
    Expression<String>? offerLink,
    Expression<int>? status,
    Expression<DateTime>? created,
    Expression<String>? groupKeyPair,
    Expression<String>? publicKey,
    Expression<String>? ownerDid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (did != null) 'did': did,
      if (offerLink != null) 'offer_link': offerLink,
      if (status != null) 'status': status,
      if (created != null) 'created': created,
      if (groupKeyPair != null) 'group_key_pair': groupKeyPair,
      if (publicKey != null) 'public_key': publicKey,
      if (ownerDid != null) 'owner_did': ownerDid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MeetingPlaceGroupsCompanion copyWith(
      {Value<String>? id,
      Value<String>? did,
      Value<String>? offerLink,
      Value<GroupStatus>? status,
      Value<DateTime>? created,
      Value<String?>? groupKeyPair,
      Value<String?>? publicKey,
      Value<String?>? ownerDid,
      Value<int>? rowid}) {
    return MeetingPlaceGroupsCompanion(
      id: id ?? this.id,
      did: did ?? this.did,
      offerLink: offerLink ?? this.offerLink,
      status: status ?? this.status,
      created: created ?? this.created,
      groupKeyPair: groupKeyPair ?? this.groupKeyPair,
      publicKey: publicKey ?? this.publicKey,
      ownerDid: ownerDid ?? this.ownerDid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (did.present) {
      map['did'] = Variable<String>(did.value);
    }
    if (offerLink.present) {
      map['offer_link'] = Variable<String>(offerLink.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
          $MeetingPlaceGroupsTable.$converterstatus.toSql(status.value));
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (groupKeyPair.present) {
      map['group_key_pair'] = Variable<String>(groupKeyPair.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (ownerDid.present) {
      map['owner_did'] = Variable<String>(ownerDid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MeetingPlaceGroupsCompanion(')
          ..write('id: $id, ')
          ..write('did: $did, ')
          ..write('offerLink: $offerLink, ')
          ..write('status: $status, ')
          ..write('created: $created, ')
          ..write('groupKeyPair: $groupKeyPair, ')
          ..write('publicKey: $publicKey, ')
          ..write('ownerDid: $ownerDid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GroupMembersTable extends GroupMembers
    with TableInfo<$GroupMembersTable, GroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints:
          'REFERENCES meeting_place_groups(id) ON DELETE CASCADE NOT NULL');
  static const VerificationMeta _memberDidMeta =
      const VerificationMeta('memberDid');
  @override
  late final GeneratedColumn<String> memberDid = GeneratedColumn<String>(
      'member_did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupOwnerDidMeta =
      const VerificationMeta('groupOwnerDid');
  @override
  late final GeneratedColumn<String> groupOwnerDid = GeneratedColumn<String>(
      'group_owner_did', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupDidMeta =
      const VerificationMeta('groupDid');
  @override
  late final GeneratedColumn<String> groupDid = GeneratedColumn<String>(
      'group_did', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _acceptOfferAsDidMeta =
      const VerificationMeta('acceptOfferAsDid');
  @override
  late final GeneratedColumn<String> acceptOfferAsDid = GeneratedColumn<String>(
      'accept_offer_as_did', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _dateAddedMeta =
      const VerificationMeta('dateAdded');
  @override
  late final GeneratedColumn<DateTime> dateAdded = GeneratedColumn<DateTime>(
      'date_added', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: clock.now);
  static const VerificationMeta _publicKeyMeta =
      const VerificationMeta('publicKey');
  @override
  late final GeneratedColumn<String> publicKey = GeneratedColumn<String>(
      'public_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<GroupMembershipType, int>
      membershipType = GeneratedColumn<int>(
              'membership_type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<GroupMembershipType>(
              $GroupMembersTable.$convertermembershipType);
  static const VerificationMeta _peerProfileHashMeta =
      const VerificationMeta('peerProfileHash');
  @override
  late final GeneratedColumn<String> peerProfileHash = GeneratedColumn<String>(
      'peer_profile_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<GroupMemberStatus, int> status =
      GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<GroupMemberStatus>(
              $GroupMembersTable.$converterstatus);
  static const VerificationMeta _firstNameMeta =
      const VerificationMeta('firstName');
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
      'first_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastNameMeta =
      const VerificationMeta('lastName');
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
      'last_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
      'mobile', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profilePicMeta =
      const VerificationMeta('profilePic');
  @override
  late final GeneratedColumn<String> profilePic = GeneratedColumn<String>(
      'profile_pic', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meetingplaceIdentityCardColorMeta =
      const VerificationMeta('meetingplaceIdentityCardColor');
  @override
  late final GeneratedColumn<String> meetingplaceIdentityCardColor =
      GeneratedColumn<String>(
          'meetingplace_identity_card_color', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        groupId,
        memberDid,
        groupOwnerDid,
        groupDid,
        metadata,
        acceptOfferAsDid,
        dateAdded,
        publicKey,
        membershipType,
        peerProfileHash,
        status,
        firstName,
        lastName,
        email,
        mobile,
        profilePic,
        meetingplaceIdentityCardColor
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(Insertable<GroupMember> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('member_did')) {
      context.handle(_memberDidMeta,
          memberDid.isAcceptableOrUnknown(data['member_did']!, _memberDidMeta));
    } else if (isInserting) {
      context.missing(_memberDidMeta);
    }
    if (data.containsKey('group_owner_did')) {
      context.handle(
          _groupOwnerDidMeta,
          groupOwnerDid.isAcceptableOrUnknown(
              data['group_owner_did']!, _groupOwnerDidMeta));
    }
    if (data.containsKey('group_did')) {
      context.handle(_groupDidMeta,
          groupDid.isAcceptableOrUnknown(data['group_did']!, _groupDidMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    if (data.containsKey('accept_offer_as_did')) {
      context.handle(
          _acceptOfferAsDidMeta,
          acceptOfferAsDid.isAcceptableOrUnknown(
              data['accept_offer_as_did']!, _acceptOfferAsDidMeta));
    }
    if (data.containsKey('date_added')) {
      context.handle(_dateAddedMeta,
          dateAdded.isAcceptableOrUnknown(data['date_added']!, _dateAddedMeta));
    }
    if (data.containsKey('public_key')) {
      context.handle(_publicKeyMeta,
          publicKey.isAcceptableOrUnknown(data['public_key']!, _publicKeyMeta));
    } else if (isInserting) {
      context.missing(_publicKeyMeta);
    }
    if (data.containsKey('peer_profile_hash')) {
      context.handle(
          _peerProfileHashMeta,
          peerProfileHash.isAcceptableOrUnknown(
              data['peer_profile_hash']!, _peerProfileHashMeta));
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(_lastNameMeta,
          lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta));
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('mobile')) {
      context.handle(_mobileMeta,
          mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta));
    } else if (isInserting) {
      context.missing(_mobileMeta);
    }
    if (data.containsKey('profile_pic')) {
      context.handle(
          _profilePicMeta,
          profilePic.isAcceptableOrUnknown(
              data['profile_pic']!, _profilePicMeta));
    } else if (isInserting) {
      context.missing(_profilePicMeta);
    }
    if (data.containsKey('meetingplace_identity_card_color')) {
      context.handle(
          _meetingplaceIdentityCardColorMeta,
          meetingplaceIdentityCardColor.isAcceptableOrUnknown(
              data['meetingplace_identity_card_color']!,
              _meetingplaceIdentityCardColorMeta));
    } else if (isInserting) {
      context.missing(_meetingplaceIdentityCardColorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  GroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMember(
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      memberDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_did'])!,
      groupOwnerDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_owner_did']),
      groupDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_did']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
      acceptOfferAsDid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}accept_offer_as_did']),
      dateAdded: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_added'])!,
      publicKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}public_key'])!,
      membershipType: $GroupMembersTable.$convertermembershipType.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}membership_type'])!),
      peerProfileHash: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}peer_profile_hash']),
      status: $GroupMembersTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      lastName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      mobile: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mobile'])!,
      profilePic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_pic'])!,
      meetingplaceIdentityCardColor: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meetingplace_identity_card_color'])!,
    );
  }

  @override
  $GroupMembersTable createAlias(String alias) {
    return $GroupMembersTable(attachedDatabase, alias);
  }

  static TypeConverter<GroupMembershipType, int> $convertermembershipType =
      const _GroupMembershipTypeConverter();
  static TypeConverter<GroupMemberStatus, int> $converterstatus =
      const _GroupMemberStatusConverter();
}

class GroupMember extends DataClass implements Insertable<GroupMember> {
  /// The group id of the member.
  final String groupId;

  /// The DID of the group member.
  final String memberDid;

  /// The DID of the group owner.
  final String? groupOwnerDid;

  /// The DID of the group.
  final String? groupDid;

  /// Additional metadata for the group member.
  final String? metadata;

  /// The accept offer as DID of the group member.
  final String? acceptOfferAsDid;

  /// The date and time when the member was added to the group.
  final DateTime dateAdded;

  /// The public key of the group member.
  final String publicKey;

  /// The membership type of the group member.
  final GroupMembershipType membershipType;

  /// The profile hash of the group member.
  final String? peerProfileHash;

  /// The status of the group member.
  final GroupMemberStatus status;

  // The identity DID of the group member.
  final String identityDid;

  /// The first name of the group member.
  final String firstName;

  /// The last name of the group member.
  final String lastName;

  /// The email of the group member.
  final String email;

  /// The mobile number of the group member.
  final String mobile;

  /// The profile picture of the group member.
  final String profilePic;

  /// The MeetingPlace identity card color of the group member.
  final String meetingplaceIdentityCardColor;
  const GroupMember(
      {required this.groupId,
      required this.memberDid,
      this.groupOwnerDid,
      this.groupDid,
      this.metadata,
      this.acceptOfferAsDid,
      required this.dateAdded,
      required this.publicKey,
      required this.membershipType,
      this.peerProfileHash,
      required this.status,
      required this.identityDid,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.mobile,
      required this.profilePic,
      required this.meetingplaceIdentityCardColor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['member_did'] = Variable<String>(memberDid);
    if (!nullToAbsent || groupOwnerDid != null) {
      map['group_owner_did'] = Variable<String>(groupOwnerDid);
    }
    if (!nullToAbsent || groupDid != null) {
      map['group_did'] = Variable<String>(groupDid);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    if (!nullToAbsent || acceptOfferAsDid != null) {
      map['accept_offer_as_did'] = Variable<String>(acceptOfferAsDid);
    }
    map['date_added'] = Variable<DateTime>(dateAdded);
    map['public_key'] = Variable<String>(publicKey);
    {
      map['membership_type'] = Variable<int>(
          $GroupMembersTable.$convertermembershipType.toSql(membershipType));
    }
    if (!nullToAbsent || peerProfileHash != null) {
      map['peer_profile_hash'] = Variable<String>(peerProfileHash);
    }
    {
      map['status'] =
          Variable<int>($GroupMembersTable.$converterstatus.toSql(status));
    }
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['email'] = Variable<String>(email);
    map['mobile'] = Variable<String>(mobile);
    map['profile_pic'] = Variable<String>(profilePic);
    map['meetingplace_identity_card_color'] =
        Variable<String>(meetingplaceIdentityCardColor);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      groupId: Value(groupId),
      memberDid: Value(memberDid),
      groupOwnerDid: groupOwnerDid == null && nullToAbsent
          ? const Value.absent()
          : Value(groupOwnerDid),
      groupDid: groupDid == null && nullToAbsent
          ? const Value.absent()
          : Value(groupDid),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      acceptOfferAsDid: acceptOfferAsDid == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptOfferAsDid),
      dateAdded: Value(dateAdded),
      publicKey: Value(publicKey),
      membershipType: Value(membershipType),
      peerProfileHash: peerProfileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(peerProfileHash),
      status: Value(status),
      firstName: Value(firstName),
      lastName: Value(lastName),
      email: Value(email),
      mobile: Value(mobile),
      profilePic: Value(profilePic),
      meetingplaceIdentityCardColor: Value(meetingplaceIdentityCardColor),
    );
  }

  factory GroupMember.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMember(
      groupId: serializer.fromJson<String>(json['groupId']),
      memberDid: serializer.fromJson<String>(json['memberDid']),
      groupOwnerDid: serializer.fromJson<String?>(json['groupOwnerDid']),
      groupDid: serializer.fromJson<String?>(json['groupDid']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      acceptOfferAsDid: serializer.fromJson<String?>(json['acceptOfferAsDid']),
      dateAdded: serializer.fromJson<DateTime>(json['dateAdded']),
      publicKey: serializer.fromJson<String>(json['publicKey']),
      membershipType:
          serializer.fromJson<GroupMembershipType>(json['membershipType']),
      peerProfileHash: serializer.fromJson<String?>(json['peerProfileHash']),
      status: serializer.fromJson<GroupMemberStatus>(json['status']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      email: serializer.fromJson<String>(json['email']),
      mobile: serializer.fromJson<String>(json['mobile']),
      profilePic: serializer.fromJson<String>(json['profilePic']),
      meetingplaceIdentityCardColor:
          serializer.fromJson<String>(json['meetingplaceIdentityCardColor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'memberDid': serializer.toJson<String>(memberDid),
      'groupOwnerDid': serializer.toJson<String?>(groupOwnerDid),
      'groupDid': serializer.toJson<String?>(groupDid),
      'metadata': serializer.toJson<String?>(metadata),
      'acceptOfferAsDid': serializer.toJson<String?>(acceptOfferAsDid),
      'dateAdded': serializer.toJson<DateTime>(dateAdded),
      'publicKey': serializer.toJson<String>(publicKey),
      'membershipType': serializer.toJson<GroupMembershipType>(membershipType),
      'peerProfileHash': serializer.toJson<String?>(peerProfileHash),
      'status': serializer.toJson<GroupMemberStatus>(status),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'email': serializer.toJson<String>(email),
      'mobile': serializer.toJson<String>(mobile),
      'profilePic': serializer.toJson<String>(profilePic),
      'meetingplaceIdentityCardColor':
          serializer.toJson<String>(meetingplaceIdentityCardColor),
    };
  }

  GroupMember copyWith(
          {String? groupId,
          String? memberDid,
          Value<String?> groupOwnerDid = const Value.absent(),
          Value<String?> groupDid = const Value.absent(),
          Value<String?> metadata = const Value.absent(),
          Value<String?> acceptOfferAsDid = const Value.absent(),
          DateTime? dateAdded,
          String? publicKey,
          GroupMembershipType? membershipType,
          Value<String?> peerProfileHash = const Value.absent(),
          GroupMemberStatus? status,
          String? firstName,
          String? lastName,
          String? email,
          String? mobile,
          String? profilePic,
          String? meetingplaceIdentityCardColor}) =>
      GroupMember(
        groupId: groupId ?? this.groupId,
        memberDid: memberDid ?? this.memberDid,
        groupOwnerDid:
            groupOwnerDid.present ? groupOwnerDid.value : this.groupOwnerDid,
        groupDid: groupDid.present ? groupDid.value : this.groupDid,
        metadata: metadata.present ? metadata.value : this.metadata,
        acceptOfferAsDid: acceptOfferAsDid.present
            ? acceptOfferAsDid.value
            : this.acceptOfferAsDid,
        dateAdded: dateAdded ?? this.dateAdded,
        publicKey: publicKey ?? this.publicKey,
        membershipType: membershipType ?? this.membershipType,
        peerProfileHash: peerProfileHash.present
            ? peerProfileHash.value
            : this.peerProfileHash,
        status: status ?? this.status,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        mobile: mobile ?? this.mobile,
        profilePic: profilePic ?? this.profilePic,
        meetingplaceIdentityCardColor:
            meetingplaceIdentityCardColor ?? this.meetingplaceIdentityCardColor,
      );
  GroupMember copyWithCompanion(GroupMembersCompanion data) {
    return GroupMember(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      memberDid: data.memberDid.present ? data.memberDid.value : this.memberDid,
      groupOwnerDid: data.groupOwnerDid.present
          ? data.groupOwnerDid.value
          : this.groupOwnerDid,
      groupDid: data.groupDid.present ? data.groupDid.value : this.groupDid,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      acceptOfferAsDid: data.acceptOfferAsDid.present
          ? data.acceptOfferAsDid.value
          : this.acceptOfferAsDid,
      dateAdded: data.dateAdded.present ? data.dateAdded.value : this.dateAdded,
      publicKey: data.publicKey.present ? data.publicKey.value : this.publicKey,
      membershipType: data.membershipType.present
          ? data.membershipType.value
          : this.membershipType,
      peerProfileHash: data.peerProfileHash.present
          ? data.peerProfileHash.value
          : this.peerProfileHash,
      status: data.status.present ? data.status.value : this.status,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      email: data.email.present ? data.email.value : this.email,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      profilePic:
          data.profilePic.present ? data.profilePic.value : this.profilePic,
      meetingplaceIdentityCardColor: data.meetingplaceIdentityCardColor.present
          ? data.meetingplaceIdentityCardColor.value
          : this.meetingplaceIdentityCardColor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMember(')
          ..write('groupId: $groupId, ')
          ..write('memberDid: $memberDid, ')
          ..write('groupOwnerDid: $groupOwnerDid, ')
          ..write('groupDid: $groupDid, ')
          ..write('metadata: $metadata, ')
          ..write('acceptOfferAsDid: $acceptOfferAsDid, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('publicKey: $publicKey, ')
          ..write('membershipType: $membershipType, ')
          ..write('peerProfileHash: $peerProfileHash, ')
          ..write('status: $status, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('email: $email, ')
          ..write('mobile: $mobile, ')
          ..write('profilePic: $profilePic, ')
          ..write(
              'meetingplaceIdentityCardColor: $meetingplaceIdentityCardColor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      groupId,
      memberDid,
      groupOwnerDid,
      groupDid,
      metadata,
      acceptOfferAsDid,
      dateAdded,
      publicKey,
      membershipType,
      peerProfileHash,
      status,
      firstName,
      lastName,
      email,
      mobile,
      profilePic,
      meetingplaceIdentityCardColor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMember &&
          other.groupId == this.groupId &&
          other.memberDid == this.memberDid &&
          other.groupOwnerDid == this.groupOwnerDid &&
          other.groupDid == this.groupDid &&
          other.metadata == this.metadata &&
          other.acceptOfferAsDid == this.acceptOfferAsDid &&
          other.dateAdded == this.dateAdded &&
          other.publicKey == this.publicKey &&
          other.membershipType == this.membershipType &&
          other.peerProfileHash == this.peerProfileHash &&
          other.status == this.status &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.email == this.email &&
          other.mobile == this.mobile &&
          other.profilePic == this.profilePic &&
          other.meetingplaceIdentityCardColor ==
              this.meetingplaceIdentityCardColor);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMember> {
  final Value<String> groupId;
  final Value<String> memberDid;
  final Value<String?> groupOwnerDid;
  final Value<String?> groupDid;
  final Value<String?> metadata;
  final Value<String?> acceptOfferAsDid;
  final Value<DateTime> dateAdded;
  final Value<String> publicKey;
  final Value<GroupMembershipType> membershipType;
  final Value<String?> peerProfileHash;
  final Value<GroupMemberStatus> status;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> email;
  final Value<String> mobile;
  final Value<String> profilePic;
  final Value<String> meetingplaceIdentityCardColor;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.groupId = const Value.absent(),
    this.memberDid = const Value.absent(),
    this.groupOwnerDid = const Value.absent(),
    this.groupDid = const Value.absent(),
    this.metadata = const Value.absent(),
    this.acceptOfferAsDid = const Value.absent(),
    this.dateAdded = const Value.absent(),
    this.publicKey = const Value.absent(),
    this.membershipType = const Value.absent(),
    this.peerProfileHash = const Value.absent(),
    this.status = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.email = const Value.absent(),
    this.mobile = const Value.absent(),
    this.profilePic = const Value.absent(),
    this.meetingplaceIdentityCardColor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required String groupId,
    required String memberDid,
    this.groupOwnerDid = const Value.absent(),
    this.groupDid = const Value.absent(),
    this.metadata = const Value.absent(),
    this.acceptOfferAsDid = const Value.absent(),
    this.dateAdded = const Value.absent(),
    required String publicKey,
    required GroupMembershipType membershipType,
    this.peerProfileHash = const Value.absent(),
    required GroupMemberStatus status,
    required String identityDid,
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String profilePic,
    required String meetingplaceIdentityCardColor,
    this.rowid = const Value.absent(),
  })  : groupId = Value(groupId),
        memberDid = Value(memberDid),
        publicKey = Value(publicKey),
        membershipType = Value(membershipType),
        status = Value(status),
        identityDid = Value(identityDid),
        firstName = Value(firstName),
        lastName = Value(lastName),
        email = Value(email),
        mobile = Value(mobile),
        profilePic = Value(profilePic),
        meetingplaceIdentityCardColor = Value(meetingplaceIdentityCardColor);
  static Insertable<GroupMember> custom({
    Expression<String>? groupId,
    Expression<String>? memberDid,
    Expression<String>? groupOwnerDid,
    Expression<String>? groupDid,
    Expression<String>? metadata,
    Expression<String>? acceptOfferAsDid,
    Expression<DateTime>? dateAdded,
    Expression<String>? publicKey,
    Expression<int>? membershipType,
    Expression<String>? peerProfileHash,
    Expression<int>? status,
    Expression<String>? identityDid,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? email,
    Expression<String>? mobile,
    Expression<String>? profilePic,
    Expression<String>? meetingplaceIdentityCardColor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (memberDid != null) 'member_did': memberDid,
      if (groupOwnerDid != null) 'group_owner_did': groupOwnerDid,
      if (groupDid != null) 'group_did': groupDid,
      if (metadata != null) 'metadata': metadata,
      if (acceptOfferAsDid != null) 'accept_offer_as_did': acceptOfferAsDid,
      if (dateAdded != null) 'date_added': dateAdded,
      if (publicKey != null) 'public_key': publicKey,
      if (membershipType != null) 'membership_type': membershipType,
      if (peerProfileHash != null) 'peer_profile_hash': peerProfileHash,
      if (status != null) 'status': status,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (mobile != null) 'mobile': mobile,
      if (profilePic != null) 'profile_pic': profilePic,
      if (meetingplaceIdentityCardColor != null)
        'meetingplace_identity_card_color': meetingplaceIdentityCardColor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith(
      {Value<String>? groupId,
      Value<String>? memberDid,
      Value<String?>? groupOwnerDid,
      Value<String?>? groupDid,
      Value<String?>? metadata,
      Value<String?>? acceptOfferAsDid,
      Value<DateTime>? dateAdded,
      Value<String>? publicKey,
      Value<GroupMembershipType>? membershipType,
      Value<String?>? peerProfileHash,
      Value<GroupMemberStatus>? status,
      Value<String>? firstName,
      Value<String>? lastName,
      Value<String>? email,
      Value<String>? mobile,
      Value<String>? profilePic,
      Value<String>? meetingplaceIdentityCardColor,
      Value<int>? rowid}) {
    return GroupMembersCompanion(
      groupId: groupId ?? this.groupId,
      memberDid: memberDid ?? this.memberDid,
      groupOwnerDid: groupOwnerDid ?? this.groupOwnerDid,
      groupDid: groupDid ?? this.groupDid,
      metadata: metadata ?? this.metadata,
      acceptOfferAsDid: acceptOfferAsDid ?? this.acceptOfferAsDid,
      dateAdded: dateAdded ?? this.dateAdded,
      publicKey: publicKey ?? this.publicKey,
      membershipType: membershipType ?? this.membershipType,
      peerProfileHash: peerProfileHash ?? this.peerProfileHash,
      status: status ?? this.status,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      profilePic: profilePic ?? this.profilePic,
      meetingplaceIdentityCardColor:
          meetingplaceIdentityCardColor ?? this.meetingplaceIdentityCardColor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (memberDid.present) {
      map['member_did'] = Variable<String>(memberDid.value);
    }
    if (groupOwnerDid.present) {
      map['group_owner_did'] = Variable<String>(groupOwnerDid.value);
    }
    if (groupDid.present) {
      map['group_did'] = Variable<String>(groupDid.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (acceptOfferAsDid.present) {
      map['accept_offer_as_did'] = Variable<String>(acceptOfferAsDid.value);
    }
    if (dateAdded.present) {
      map['date_added'] = Variable<DateTime>(dateAdded.value);
    }
    if (publicKey.present) {
      map['public_key'] = Variable<String>(publicKey.value);
    }
    if (membershipType.present) {
      map['membership_type'] = Variable<int>($GroupMembersTable
          .$convertermembershipType
          .toSql(membershipType.value));
    }
    if (peerProfileHash.present) {
      map['peer_profile_hash'] = Variable<String>(peerProfileHash.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(
          $GroupMembersTable.$converterstatus.toSql(status.value));
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (profilePic.present) {
      map['profile_pic'] = Variable<String>(profilePic.value);
    }
    if (meetingplaceIdentityCardColor.present) {
      map['meetingplace_identity_card_color'] =
          Variable<String>(meetingplaceIdentityCardColor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('groupId: $groupId, ')
          ..write('memberDid: $memberDid, ')
          ..write('groupOwnerDid: $groupOwnerDid, ')
          ..write('groupDid: $groupDid, ')
          ..write('metadata: $metadata, ')
          ..write('acceptOfferAsDid: $acceptOfferAsDid, ')
          ..write('dateAdded: $dateAdded, ')
          ..write('publicKey: $publicKey, ')
          ..write('membershipType: $membershipType, ')
          ..write('peerProfileHash: $peerProfileHash, ')
          ..write('status: $status, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('email: $email, ')
          ..write('mobile: $mobile, ')
          ..write('profilePic: $profilePic, ')
          ..write(
              'meetingplaceIdentityCardColor: $meetingplaceIdentityCardColor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$GroupsDatabase extends GeneratedDatabase {
  _$GroupsDatabase(QueryExecutor e) : super(e);
  $GroupsDatabaseManager get managers => $GroupsDatabaseManager(this);
  late final $MeetingPlaceGroupsTable meetingPlaceGroups =
      $MeetingPlaceGroupsTable(this);
  late final $GroupMembersTable groupMembers = $GroupMembersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [meetingPlaceGroups, groupMembers];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('meeting_place_groups',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('group_members', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$MeetingPlaceGroupsTableCreateCompanionBuilder
    = MeetingPlaceGroupsCompanion Function({
  required String id,
  required String did,
  required String offerLink,
  required GroupStatus status,
  required DateTime created,
  Value<String?> groupKeyPair,
  Value<String?> publicKey,
  Value<String?> ownerDid,
  Value<int> rowid,
});
typedef $$MeetingPlaceGroupsTableUpdateCompanionBuilder
    = MeetingPlaceGroupsCompanion Function({
  Value<String> id,
  Value<String> did,
  Value<String> offerLink,
  Value<GroupStatus> status,
  Value<DateTime> created,
  Value<String?> groupKeyPair,
  Value<String?> publicKey,
  Value<String?> ownerDid,
  Value<int> rowid,
});

final class $$MeetingPlaceGroupsTableReferences extends BaseReferences<
    _$GroupsDatabase, $MeetingPlaceGroupsTable, MeetingPlaceGroup> {
  $$MeetingPlaceGroupsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GroupMembersTable, List<GroupMember>>
      _groupMembersRefsTable(_$GroupsDatabase db) =>
          MultiTypedResultKey.fromTable(db.groupMembers,
              aliasName: $_aliasNameGenerator(
                  db.meetingPlaceGroups.id, db.groupMembers.groupId));

  $$GroupMembersTableProcessedTableManager get groupMembersRefs {
    final manager = $$GroupMembersTableTableManager($_db, $_db.groupMembers)
        .filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupMembersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$MeetingPlaceGroupsTableFilterComposer
    extends Composer<_$GroupsDatabase, $MeetingPlaceGroupsTable> {
  $$MeetingPlaceGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get did => $composableBuilder(
      column: $table.did, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get offerLink => $composableBuilder(
      column: $table.offerLink, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<GroupStatus, GroupStatus, int> get status =>
      $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<DateTime> get created => $composableBuilder(
      column: $table.created, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupKeyPair => $composableBuilder(
      column: $table.groupKeyPair, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publicKey => $composableBuilder(
      column: $table.publicKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerDid => $composableBuilder(
      column: $table.ownerDid, builder: (column) => ColumnFilters(column));

  Expression<bool> groupMembersRefs(
      Expression<bool> Function($$GroupMembersTableFilterComposer f) f) {
    final $$GroupMembersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.groupMembers,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupMembersTableFilterComposer(
              $db: $db,
              $table: $db.groupMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MeetingPlaceGroupsTableOrderingComposer
    extends Composer<_$GroupsDatabase, $MeetingPlaceGroupsTable> {
  $$MeetingPlaceGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get did => $composableBuilder(
      column: $table.did, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get offerLink => $composableBuilder(
      column: $table.offerLink, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get created => $composableBuilder(
      column: $table.created, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupKeyPair => $composableBuilder(
      column: $table.groupKeyPair,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publicKey => $composableBuilder(
      column: $table.publicKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerDid => $composableBuilder(
      column: $table.ownerDid, builder: (column) => ColumnOrderings(column));
}

class $$MeetingPlaceGroupsTableAnnotationComposer
    extends Composer<_$GroupsDatabase, $MeetingPlaceGroupsTable> {
  $$MeetingPlaceGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get did =>
      $composableBuilder(column: $table.did, builder: (column) => column);

  GeneratedColumn<String> get offerLink =>
      $composableBuilder(column: $table.offerLink, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GroupStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<String> get groupKeyPair => $composableBuilder(
      column: $table.groupKeyPair, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumn<String> get ownerDid =>
      $composableBuilder(column: $table.ownerDid, builder: (column) => column);

  Expression<T> groupMembersRefs<T extends Object>(
      Expression<T> Function($$GroupMembersTableAnnotationComposer a) f) {
    final $$GroupMembersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.groupMembers,
        getReferencedColumn: (t) => t.groupId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$GroupMembersTableAnnotationComposer(
              $db: $db,
              $table: $db.groupMembers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$MeetingPlaceGroupsTableTableManager extends RootTableManager<
    _$GroupsDatabase,
    $MeetingPlaceGroupsTable,
    MeetingPlaceGroup,
    $$MeetingPlaceGroupsTableFilterComposer,
    $$MeetingPlaceGroupsTableOrderingComposer,
    $$MeetingPlaceGroupsTableAnnotationComposer,
    $$MeetingPlaceGroupsTableCreateCompanionBuilder,
    $$MeetingPlaceGroupsTableUpdateCompanionBuilder,
    (MeetingPlaceGroup, $$MeetingPlaceGroupsTableReferences),
    MeetingPlaceGroup,
    PrefetchHooks Function({bool groupMembersRefs})> {
  $$MeetingPlaceGroupsTableTableManager(
      _$GroupsDatabase db, $MeetingPlaceGroupsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MeetingPlaceGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MeetingPlaceGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MeetingPlaceGroupsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> did = const Value.absent(),
            Value<String> offerLink = const Value.absent(),
            Value<GroupStatus> status = const Value.absent(),
            Value<DateTime> created = const Value.absent(),
            Value<String?> groupKeyPair = const Value.absent(),
            Value<String?> publicKey = const Value.absent(),
            Value<String?> ownerDid = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeetingPlaceGroupsCompanion(
            id: id,
            did: did,
            offerLink: offerLink,
            status: status,
            created: created,
            groupKeyPair: groupKeyPair,
            publicKey: publicKey,
            ownerDid: ownerDid,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String did,
            required String offerLink,
            required GroupStatus status,
            required DateTime created,
            Value<String?> groupKeyPair = const Value.absent(),
            Value<String?> publicKey = const Value.absent(),
            Value<String?> ownerDid = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MeetingPlaceGroupsCompanion.insert(
            id: id,
            did: did,
            offerLink: offerLink,
            status: status,
            created: created,
            groupKeyPair: groupKeyPair,
            publicKey: publicKey,
            ownerDid: ownerDid,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$MeetingPlaceGroupsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({groupMembersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (groupMembersRefs) db.groupMembers],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (groupMembersRefs)
                    await $_getPrefetchedData<MeetingPlaceGroup,
                            $MeetingPlaceGroupsTable, GroupMember>(
                        currentTable: table,
                        referencedTable: $$MeetingPlaceGroupsTableReferences
                            ._groupMembersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$MeetingPlaceGroupsTableReferences(db, table, p0)
                                .groupMembersRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.groupId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$MeetingPlaceGroupsTableProcessedTableManager = ProcessedTableManager<
    _$GroupsDatabase,
    $MeetingPlaceGroupsTable,
    MeetingPlaceGroup,
    $$MeetingPlaceGroupsTableFilterComposer,
    $$MeetingPlaceGroupsTableOrderingComposer,
    $$MeetingPlaceGroupsTableAnnotationComposer,
    $$MeetingPlaceGroupsTableCreateCompanionBuilder,
    $$MeetingPlaceGroupsTableUpdateCompanionBuilder,
    (MeetingPlaceGroup, $$MeetingPlaceGroupsTableReferences),
    MeetingPlaceGroup,
    PrefetchHooks Function({bool groupMembersRefs})>;
typedef $$GroupMembersTableCreateCompanionBuilder = GroupMembersCompanion
    Function({
  required String groupId,
  required String memberDid,
  Value<String?> groupOwnerDid,
  Value<String?> groupDid,
  Value<String?> metadata,
  Value<String?> acceptOfferAsDid,
  Value<DateTime> dateAdded,
  required String publicKey,
  required GroupMembershipType membershipType,
  Value<String?> peerProfileHash,
  required GroupMemberStatus status,
  required String firstName,
  required String lastName,
  required String email,
  required String mobile,
  required String profilePic,
  required String meetingplaceIdentityCardColor,
  Value<int> rowid,
});
typedef $$GroupMembersTableUpdateCompanionBuilder = GroupMembersCompanion
    Function({
  Value<String> groupId,
  Value<String> memberDid,
  Value<String?> groupOwnerDid,
  Value<String?> groupDid,
  Value<String?> metadata,
  Value<String?> acceptOfferAsDid,
  Value<DateTime> dateAdded,
  Value<String> publicKey,
  Value<GroupMembershipType> membershipType,
  Value<String?> peerProfileHash,
  Value<GroupMemberStatus> status,
  Value<String> firstName,
  Value<String> lastName,
  Value<String> email,
  Value<String> mobile,
  Value<String> profilePic,
  Value<String> meetingplaceIdentityCardColor,
  Value<int> rowid,
});

final class $$GroupMembersTableReferences
    extends BaseReferences<_$GroupsDatabase, $GroupMembersTable, GroupMember> {
  $$GroupMembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MeetingPlaceGroupsTable _groupIdTable(_$GroupsDatabase db) =>
      db.meetingPlaceGroups.createAlias($_aliasNameGenerator(
          db.groupMembers.groupId, db.meetingPlaceGroups.id));

  $$MeetingPlaceGroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager =
        $$MeetingPlaceGroupsTableTableManager($_db, $_db.meetingPlaceGroups)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GroupMembersTableFilterComposer
    extends Composer<_$GroupsDatabase, $GroupMembersTable> {
  $$GroupMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get memberDid => $composableBuilder(
      column: $table.memberDid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupOwnerDid => $composableBuilder(
      column: $table.groupOwnerDid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupDid => $composableBuilder(
      column: $table.groupDid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get acceptOfferAsDid => $composableBuilder(
      column: $table.acceptOfferAsDid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateAdded => $composableBuilder(
      column: $table.dateAdded, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publicKey => $composableBuilder(
      column: $table.publicKey, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<GroupMembershipType, GroupMembershipType, int>
      get membershipType => $composableBuilder(
          column: $table.membershipType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get peerProfileHash => $composableBuilder(
      column: $table.peerProfileHash,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<GroupMemberStatus, GroupMemberStatus, int>
      get status => $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastName => $composableBuilder(
      column: $table.lastName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mobile => $composableBuilder(
      column: $table.mobile, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profilePic => $composableBuilder(
      column: $table.profilePic, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meetingplaceIdentityCardColor => $composableBuilder(
      column: $table.meetingplaceIdentityCardColor,
      builder: (column) => ColumnFilters(column));

  $$MeetingPlaceGroupsTableFilterComposer get groupId {
    final $$MeetingPlaceGroupsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.meetingPlaceGroups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingPlaceGroupsTableFilterComposer(
              $db: $db,
              $table: $db.meetingPlaceGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupMembersTableOrderingComposer
    extends Composer<_$GroupsDatabase, $GroupMembersTable> {
  $$GroupMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get memberDid => $composableBuilder(
      column: $table.memberDid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupOwnerDid => $composableBuilder(
      column: $table.groupOwnerDid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupDid => $composableBuilder(
      column: $table.groupDid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get acceptOfferAsDid => $composableBuilder(
      column: $table.acceptOfferAsDid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateAdded => $composableBuilder(
      column: $table.dateAdded, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publicKey => $composableBuilder(
      column: $table.publicKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get membershipType => $composableBuilder(
      column: $table.membershipType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get peerProfileHash => $composableBuilder(
      column: $table.peerProfileHash,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastName => $composableBuilder(
      column: $table.lastName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mobile => $composableBuilder(
      column: $table.mobile, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profilePic => $composableBuilder(
      column: $table.profilePic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meetingplaceIdentityCardColor =>
      $composableBuilder(
          column: $table.meetingplaceIdentityCardColor,
          builder: (column) => ColumnOrderings(column));

  $$MeetingPlaceGroupsTableOrderingComposer get groupId {
    final $$MeetingPlaceGroupsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.groupId,
        referencedTable: $db.meetingPlaceGroups,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$MeetingPlaceGroupsTableOrderingComposer(
              $db: $db,
              $table: $db.meetingPlaceGroups,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupMembersTableAnnotationComposer
    extends Composer<_$GroupsDatabase, $GroupMembersTable> {
  $$GroupMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get memberDid =>
      $composableBuilder(column: $table.memberDid, builder: (column) => column);

  GeneratedColumn<String> get groupOwnerDid => $composableBuilder(
      column: $table.groupOwnerDid, builder: (column) => column);

  GeneratedColumn<String> get groupDid =>
      $composableBuilder(column: $table.groupDid, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get acceptOfferAsDid => $composableBuilder(
      column: $table.acceptOfferAsDid, builder: (column) => column);

  GeneratedColumn<DateTime> get dateAdded =>
      $composableBuilder(column: $table.dateAdded, builder: (column) => column);

  GeneratedColumn<String> get publicKey =>
      $composableBuilder(column: $table.publicKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GroupMembershipType, int>
      get membershipType => $composableBuilder(
          column: $table.membershipType, builder: (column) => column);

  GeneratedColumn<String> get peerProfileHash => $composableBuilder(
      column: $table.peerProfileHash, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GroupMemberStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<String> get profilePic => $composableBuilder(
      column: $table.profilePic, builder: (column) => column);

  GeneratedColumn<String> get meetingplaceIdentityCardColor =>
      $composableBuilder(
          column: $table.meetingplaceIdentityCardColor,
          builder: (column) => column);

  $$MeetingPlaceGroupsTableAnnotationComposer get groupId {
    final $$MeetingPlaceGroupsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.groupId,
            referencedTable: $db.meetingPlaceGroups,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$MeetingPlaceGroupsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.meetingPlaceGroups,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$GroupMembersTableTableManager extends RootTableManager<
    _$GroupsDatabase,
    $GroupMembersTable,
    GroupMember,
    $$GroupMembersTableFilterComposer,
    $$GroupMembersTableOrderingComposer,
    $$GroupMembersTableAnnotationComposer,
    $$GroupMembersTableCreateCompanionBuilder,
    $$GroupMembersTableUpdateCompanionBuilder,
    (GroupMember, $$GroupMembersTableReferences),
    GroupMember,
    PrefetchHooks Function({bool groupId})> {
  $$GroupMembersTableTableManager(_$GroupsDatabase db, $GroupMembersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> groupId = const Value.absent(),
            Value<String> memberDid = const Value.absent(),
            Value<String?> groupOwnerDid = const Value.absent(),
            Value<String?> groupDid = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<String?> acceptOfferAsDid = const Value.absent(),
            Value<DateTime> dateAdded = const Value.absent(),
            Value<String> publicKey = const Value.absent(),
            Value<GroupMembershipType> membershipType = const Value.absent(),
            Value<String?> peerProfileHash = const Value.absent(),
            Value<GroupMemberStatus> status = const Value.absent(),
            Value<String> firstName = const Value.absent(),
            Value<String> lastName = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> mobile = const Value.absent(),
            Value<String> profilePic = const Value.absent(),
            Value<String> meetingplaceIdentityCardColor = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupMembersCompanion(
            groupId: groupId,
            memberDid: memberDid,
            groupOwnerDid: groupOwnerDid,
            groupDid: groupDid,
            metadata: metadata,
            acceptOfferAsDid: acceptOfferAsDid,
            dateAdded: dateAdded,
            publicKey: publicKey,
            membershipType: membershipType,
            peerProfileHash: peerProfileHash,
            status: status,
            firstName: firstName,
            lastName: lastName,
            email: email,
            mobile: mobile,
            profilePic: profilePic,
            meetingplaceIdentityCardColor: meetingplaceIdentityCardColor,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String groupId,
            required String memberDid,
            Value<String?> groupOwnerDid = const Value.absent(),
            Value<String?> groupDid = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<String?> acceptOfferAsDid = const Value.absent(),
            Value<DateTime> dateAdded = const Value.absent(),
            required String publicKey,
            required GroupMembershipType membershipType,
            Value<String?> peerProfileHash = const Value.absent(),
            required GroupMemberStatus status,
            required String firstName,
            required String lastName,
            required String email,
            required String mobile,
            required String profilePic,
            required String meetingplaceIdentityCardColor,
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupMembersCompanion.insert(
            groupId: groupId,
            memberDid: memberDid,
            groupOwnerDid: groupOwnerDid,
            groupDid: groupDid,
            metadata: metadata,
            acceptOfferAsDid: acceptOfferAsDid,
            dateAdded: dateAdded,
            publicKey: publicKey,
            membershipType: membershipType,
            peerProfileHash: peerProfileHash,
            status: status,
            firstName: firstName,
            lastName: lastName,
            email: email,
            mobile: mobile,
            profilePic: profilePic,
            meetingplaceIdentityCardColor: meetingplaceIdentityCardColor,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GroupMembersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (groupId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.groupId,
                    referencedTable:
                        $$GroupMembersTableReferences._groupIdTable(db),
                    referencedColumn:
                        $$GroupMembersTableReferences._groupIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GroupMembersTableProcessedTableManager = ProcessedTableManager<
    _$GroupsDatabase,
    $GroupMembersTable,
    GroupMember,
    $$GroupMembersTableFilterComposer,
    $$GroupMembersTableOrderingComposer,
    $$GroupMembersTableAnnotationComposer,
    $$GroupMembersTableCreateCompanionBuilder,
    $$GroupMembersTableUpdateCompanionBuilder,
    (GroupMember, $$GroupMembersTableReferences),
    GroupMember,
    PrefetchHooks Function({bool groupId})>;

class $GroupsDatabaseManager {
  final _$GroupsDatabase _db;
  $GroupsDatabaseManager(this._db);
  $$MeetingPlaceGroupsTableTableManager get meetingPlaceGroups =>
      $$MeetingPlaceGroupsTableTableManager(_db, _db.meetingPlaceGroups);
  $$GroupMembersTableTableManager get groupMembers =>
      $$GroupMembersTableTableManager(_db, _db.groupMembers);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_database.dart';

// ignore_for_file: type=lint
class $IdentitiesTable extends Identities
    with TableInfo<$IdentitiesTable, IdentityRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IdentitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: const Uuid().v4);
  static const VerificationMeta _didMeta = const VerificationMeta('did');
  @override
  late final GeneratedColumn<String> did = GeneratedColumn<String>(
      'did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _displayNameMeta =
      const VerificationMeta('displayName');
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
      'display_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
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
      'last_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
      'mobile', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _profilePicMeta =
      const VerificationMeta('profilePic');
  @override
  late final GeneratedColumn<String> profilePic = GeneratedColumn<String>(
      'profile_pic', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _cardColorMeta =
      const VerificationMeta('cardColor');
  @override
  late final GeneratedColumn<String> cardColor = GeneratedColumn<String>(
      'card_color', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPrimaryMeta =
      const VerificationMeta('isPrimary');
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
      'is_primary', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_primary" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        did,
        displayName,
        firstName,
        lastName,
        email,
        mobile,
        profilePic,
        cardColor,
        isPrimary
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'identities';
  @override
  VerificationContext validateIntegrity(Insertable<IdentityRecord> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('did')) {
      context.handle(
          _didMeta, did.isAcceptableOrUnknown(data['did']!, _didMeta));
    } else if (isInserting) {
      context.missing(_didMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
          _displayNameMeta,
          displayName.isAcceptableOrUnknown(
              data['display_name']!, _displayNameMeta));
    } else if (isInserting) {
      context.missing(_displayNameMeta);
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
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    }
    if (data.containsKey('mobile')) {
      context.handle(_mobileMeta,
          mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta));
    }
    if (data.containsKey('profile_pic')) {
      context.handle(
          _profilePicMeta,
          profilePic.isAcceptableOrUnknown(
              data['profile_pic']!, _profilePicMeta));
    }
    if (data.containsKey('card_color')) {
      context.handle(_cardColorMeta,
          cardColor.isAcceptableOrUnknown(data['card_color']!, _cardColorMeta));
    }
    if (data.containsKey('is_primary')) {
      context.handle(_isPrimaryMeta,
          isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {did},
      ];
  @override
  IdentityRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return IdentityRecord(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      did: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}did'])!,
      displayName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_name'])!,
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      lastName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name']),
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email']),
      mobile: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mobile']),
      profilePic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_pic']),
      cardColor: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_color']),
      isPrimary: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_primary'])!,
    );
  }

  @override
  $IdentitiesTable createAlias(String alias) {
    return $IdentitiesTable(attachedDatabase, alias);
  }
}

class IdentityRecord extends DataClass implements Insertable<IdentityRecord> {
  final String id;
  final String did;
  final String displayName;
  final String firstName;
  final String? lastName;
  final String? email;
  final String? mobile;
  final String? profilePic;
  final String? cardColor;
  final bool isPrimary;
  const IdentityRecord(
      {required this.id,
      required this.did,
      required this.displayName,
      required this.firstName,
      this.lastName,
      this.email,
      this.mobile,
      this.profilePic,
      this.cardColor,
      required this.isPrimary});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['did'] = Variable<String>(did);
    map['display_name'] = Variable<String>(displayName);
    map['first_name'] = Variable<String>(firstName);
    if (!nullToAbsent || lastName != null) {
      map['last_name'] = Variable<String>(lastName);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || mobile != null) {
      map['mobile'] = Variable<String>(mobile);
    }
    if (!nullToAbsent || profilePic != null) {
      map['profile_pic'] = Variable<String>(profilePic);
    }
    if (!nullToAbsent || cardColor != null) {
      map['card_color'] = Variable<String>(cardColor);
    }
    map['is_primary'] = Variable<bool>(isPrimary);
    return map;
  }

  IdentitiesCompanion toCompanion(bool nullToAbsent) {
    return IdentitiesCompanion(
      id: Value(id),
      did: Value(did),
      displayName: Value(displayName),
      firstName: Value(firstName),
      lastName: lastName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastName),
      email:
          email == null && nullToAbsent ? const Value.absent() : Value(email),
      mobile:
          mobile == null && nullToAbsent ? const Value.absent() : Value(mobile),
      profilePic: profilePic == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePic),
      cardColor: cardColor == null && nullToAbsent
          ? const Value.absent()
          : Value(cardColor),
      isPrimary: Value(isPrimary),
    );
  }

  factory IdentityRecord.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return IdentityRecord(
      id: serializer.fromJson<String>(json['id']),
      did: serializer.fromJson<String>(json['did']),
      displayName: serializer.fromJson<String>(json['displayName']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String?>(json['lastName']),
      email: serializer.fromJson<String?>(json['email']),
      mobile: serializer.fromJson<String?>(json['mobile']),
      profilePic: serializer.fromJson<String?>(json['profilePic']),
      cardColor: serializer.fromJson<String?>(json['cardColor']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'did': serializer.toJson<String>(did),
      'displayName': serializer.toJson<String>(displayName),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String?>(lastName),
      'email': serializer.toJson<String?>(email),
      'mobile': serializer.toJson<String?>(mobile),
      'profilePic': serializer.toJson<String?>(profilePic),
      'cardColor': serializer.toJson<String?>(cardColor),
      'isPrimary': serializer.toJson<bool>(isPrimary),
    };
  }

  IdentityRecord copyWith(
          {String? id,
          String? did,
          String? displayName,
          String? firstName,
          Value<String?> lastName = const Value.absent(),
          Value<String?> email = const Value.absent(),
          Value<String?> mobile = const Value.absent(),
          Value<String?> profilePic = const Value.absent(),
          Value<String?> cardColor = const Value.absent(),
          bool? isPrimary}) =>
      IdentityRecord(
        id: id ?? this.id,
        did: did ?? this.did,
        displayName: displayName ?? this.displayName,
        firstName: firstName ?? this.firstName,
        lastName: lastName.present ? lastName.value : this.lastName,
        email: email.present ? email.value : this.email,
        mobile: mobile.present ? mobile.value : this.mobile,
        profilePic: profilePic.present ? profilePic.value : this.profilePic,
        cardColor: cardColor.present ? cardColor.value : this.cardColor,
        isPrimary: isPrimary ?? this.isPrimary,
      );
  IdentityRecord copyWithCompanion(IdentitiesCompanion data) {
    return IdentityRecord(
      id: data.id.present ? data.id.value : this.id,
      did: data.did.present ? data.did.value : this.did,
      displayName:
          data.displayName.present ? data.displayName.value : this.displayName,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      email: data.email.present ? data.email.value : this.email,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      profilePic:
          data.profilePic.present ? data.profilePic.value : this.profilePic,
      cardColor: data.cardColor.present ? data.cardColor.value : this.cardColor,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
    );
  }

  @override
  String toString() {
    return (StringBuffer('IdentityRecord(')
          ..write('id: $id, ')
          ..write('did: $did, ')
          ..write('displayName: $displayName, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('email: $email, ')
          ..write('mobile: $mobile, ')
          ..write('profilePic: $profilePic, ')
          ..write('cardColor: $cardColor, ')
          ..write('isPrimary: $isPrimary')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, did, displayName, firstName, lastName,
      email, mobile, profilePic, cardColor, isPrimary);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is IdentityRecord &&
          other.id == this.id &&
          other.did == this.did &&
          other.displayName == this.displayName &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.email == this.email &&
          other.mobile == this.mobile &&
          other.profilePic == this.profilePic &&
          other.cardColor == this.cardColor &&
          other.isPrimary == this.isPrimary);
}

class IdentitiesCompanion extends UpdateCompanion<IdentityRecord> {
  final Value<String> id;
  final Value<String> did;
  final Value<String> displayName;
  final Value<String> firstName;
  final Value<String?> lastName;
  final Value<String?> email;
  final Value<String?> mobile;
  final Value<String?> profilePic;
  final Value<String?> cardColor;
  final Value<bool> isPrimary;
  final Value<int> rowid;
  const IdentitiesCompanion({
    this.id = const Value.absent(),
    this.did = const Value.absent(),
    this.displayName = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.email = const Value.absent(),
    this.mobile = const Value.absent(),
    this.profilePic = const Value.absent(),
    this.cardColor = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IdentitiesCompanion.insert({
    this.id = const Value.absent(),
    required String did,
    required String displayName,
    required String firstName,
    this.lastName = const Value.absent(),
    this.email = const Value.absent(),
    this.mobile = const Value.absent(),
    this.profilePic = const Value.absent(),
    this.cardColor = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : did = Value(did),
        displayName = Value(displayName),
        firstName = Value(firstName);
  static Insertable<IdentityRecord> custom({
    Expression<String>? id,
    Expression<String>? did,
    Expression<String>? displayName,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? email,
    Expression<String>? mobile,
    Expression<String>? profilePic,
    Expression<String>? cardColor,
    Expression<bool>? isPrimary,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (did != null) 'did': did,
      if (displayName != null) 'display_name': displayName,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (mobile != null) 'mobile': mobile,
      if (profilePic != null) 'profile_pic': profilePic,
      if (cardColor != null) 'card_color': cardColor,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IdentitiesCompanion copyWith(
      {Value<String>? id,
      Value<String>? did,
      Value<String>? displayName,
      Value<String>? firstName,
      Value<String?>? lastName,
      Value<String?>? email,
      Value<String?>? mobile,
      Value<String?>? profilePic,
      Value<String?>? cardColor,
      Value<bool>? isPrimary,
      Value<int>? rowid}) {
    return IdentitiesCompanion(
      id: id ?? this.id,
      did: did ?? this.did,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      profilePic: profilePic ?? this.profilePic,
      cardColor: cardColor ?? this.cardColor,
      isPrimary: isPrimary ?? this.isPrimary,
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
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
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
    if (cardColor.present) {
      map['card_color'] = Variable<String>(cardColor.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IdentitiesCompanion(')
          ..write('id: $id, ')
          ..write('did: $did, ')
          ..write('displayName: $displayName, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('email: $email, ')
          ..write('mobile: $mobile, ')
          ..write('profilePic: $profilePic, ')
          ..write('cardColor: $cardColor, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$IdentityDatabase extends GeneratedDatabase {
  _$IdentityDatabase(QueryExecutor e) : super(e);
  $IdentityDatabaseManager get managers => $IdentityDatabaseManager(this);
  late final $IdentitiesTable identities = $IdentitiesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [identities];
}

typedef $$IdentitiesTableCreateCompanionBuilder = IdentitiesCompanion Function({
  Value<String> id,
  required String did,
  required String displayName,
  required String firstName,
  Value<String?> lastName,
  Value<String?> email,
  Value<String?> mobile,
  Value<String?> profilePic,
  Value<String?> cardColor,
  Value<bool> isPrimary,
  Value<int> rowid,
});
typedef $$IdentitiesTableUpdateCompanionBuilder = IdentitiesCompanion Function({
  Value<String> id,
  Value<String> did,
  Value<String> displayName,
  Value<String> firstName,
  Value<String?> lastName,
  Value<String?> email,
  Value<String?> mobile,
  Value<String?> profilePic,
  Value<String?> cardColor,
  Value<bool> isPrimary,
  Value<int> rowid,
});

class $$IdentitiesTableFilterComposer
    extends Composer<_$IdentityDatabase, $IdentitiesTable> {
  $$IdentitiesTableFilterComposer({
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

  ColumnFilters<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnFilters(column));

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

  ColumnFilters<String> get cardColor => $composableBuilder(
      column: $table.cardColor, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPrimary => $composableBuilder(
      column: $table.isPrimary, builder: (column) => ColumnFilters(column));
}

class $$IdentitiesTableOrderingComposer
    extends Composer<_$IdentityDatabase, $IdentitiesTable> {
  $$IdentitiesTableOrderingComposer({
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

  ColumnOrderings<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => ColumnOrderings(column));

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

  ColumnOrderings<String> get cardColor => $composableBuilder(
      column: $table.cardColor, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
      column: $table.isPrimary, builder: (column) => ColumnOrderings(column));
}

class $$IdentitiesTableAnnotationComposer
    extends Composer<_$IdentityDatabase, $IdentitiesTable> {
  $$IdentitiesTableAnnotationComposer({
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

  GeneratedColumn<String> get displayName => $composableBuilder(
      column: $table.displayName, builder: (column) => column);

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

  GeneratedColumn<String> get cardColor =>
      $composableBuilder(column: $table.cardColor, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);
}

class $$IdentitiesTableTableManager extends RootTableManager<
    _$IdentityDatabase,
    $IdentitiesTable,
    IdentityRecord,
    $$IdentitiesTableFilterComposer,
    $$IdentitiesTableOrderingComposer,
    $$IdentitiesTableAnnotationComposer,
    $$IdentitiesTableCreateCompanionBuilder,
    $$IdentitiesTableUpdateCompanionBuilder,
    (
      IdentityRecord,
      BaseReferences<_$IdentityDatabase, $IdentitiesTable, IdentityRecord>
    ),
    IdentityRecord,
    PrefetchHooks Function()> {
  $$IdentitiesTableTableManager(_$IdentityDatabase db, $IdentitiesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IdentitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IdentitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IdentitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> did = const Value.absent(),
            Value<String> displayName = const Value.absent(),
            Value<String> firstName = const Value.absent(),
            Value<String?> lastName = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> mobile = const Value.absent(),
            Value<String?> profilePic = const Value.absent(),
            Value<String?> cardColor = const Value.absent(),
            Value<bool> isPrimary = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IdentitiesCompanion(
            id: id,
            did: did,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            email: email,
            mobile: mobile,
            profilePic: profilePic,
            cardColor: cardColor,
            isPrimary: isPrimary,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String did,
            required String displayName,
            required String firstName,
            Value<String?> lastName = const Value.absent(),
            Value<String?> email = const Value.absent(),
            Value<String?> mobile = const Value.absent(),
            Value<String?> profilePic = const Value.absent(),
            Value<String?> cardColor = const Value.absent(),
            Value<bool> isPrimary = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              IdentitiesCompanion.insert(
            id: id,
            did: did,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName,
            email: email,
            mobile: mobile,
            profilePic: profilePic,
            cardColor: cardColor,
            isPrimary: isPrimary,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$IdentitiesTableProcessedTableManager = ProcessedTableManager<
    _$IdentityDatabase,
    $IdentitiesTable,
    IdentityRecord,
    $$IdentitiesTableFilterComposer,
    $$IdentitiesTableOrderingComposer,
    $$IdentitiesTableAnnotationComposer,
    $$IdentitiesTableCreateCompanionBuilder,
    $$IdentitiesTableUpdateCompanionBuilder,
    (
      IdentityRecord,
      BaseReferences<_$IdentityDatabase, $IdentitiesTable, IdentityRecord>
    ),
    IdentityRecord,
    PrefetchHooks Function()>;

class $IdentityDatabaseManager {
  final _$IdentityDatabase _db;
  $IdentityDatabaseManager(this._db);
  $$IdentitiesTableTableManager get identities =>
      $$IdentitiesTableTableManager(_db, _db.identities);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'r_card_database.dart';

// ignore_for_file: type=lint
class $ReceivedRCardsTable extends ReceivedRCards
    with TableInfo<$ReceivedRCardsTable, RCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceivedRCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _subjectDidMeta =
      const VerificationMeta('subjectDid');
  @override
  late final GeneratedColumn<String> subjectDid = GeneratedColumn<String>(
      'subject_did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vcBlobMeta = const VerificationMeta('vcBlob');
  @override
  late final GeneratedColumn<String> vcBlob = GeneratedColumn<String>(
      'vc_blob', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _issuerDidMeta =
      const VerificationMeta('issuerDid');
  @override
  late final GeneratedColumn<String> issuerDid = GeneratedColumn<String>(
      'issuer_did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _versionMeta =
      const VerificationMeta('version');
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
      'version', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _issuanceDateMeta =
      const VerificationMeta('issuanceDate');
  @override
  late final GeneratedColumn<DateTime> issuanceDate = GeneratedColumn<DateTime>(
      'issuance_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _threadIdMeta =
      const VerificationMeta('threadId');
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
      'thread_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _contactChannelDidMeta =
      const VerificationMeta('contactChannelDid');
  @override
  late final GeneratedColumn<String> contactChannelDid =
      GeneratedColumn<String>('contact_channel_did', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _localChannelDidMeta =
      const VerificationMeta('localChannelDid');
  @override
  late final GeneratedColumn<String> localChannelDid = GeneratedColumn<String>(
      'local_channel_did', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _receivedAtMeta =
      const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
      'received_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        subjectDid,
        vcBlob,
        issuerDid,
        version,
        issuanceDate,
        notes,
        threadId,
        contactChannelDid,
        localChannelDid,
        receivedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'received_r_cards';
  @override
  VerificationContext validateIntegrity(Insertable<RCardRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('subject_did')) {
      context.handle(
          _subjectDidMeta,
          subjectDid.isAcceptableOrUnknown(
              data['subject_did']!, _subjectDidMeta));
    } else if (isInserting) {
      context.missing(_subjectDidMeta);
    }
    if (data.containsKey('vc_blob')) {
      context.handle(_vcBlobMeta,
          vcBlob.isAcceptableOrUnknown(data['vc_blob']!, _vcBlobMeta));
    } else if (isInserting) {
      context.missing(_vcBlobMeta);
    }
    if (data.containsKey('issuer_did')) {
      context.handle(_issuerDidMeta,
          issuerDid.isAcceptableOrUnknown(data['issuer_did']!, _issuerDidMeta));
    } else if (isInserting) {
      context.missing(_issuerDidMeta);
    }
    if (data.containsKey('version')) {
      context.handle(_versionMeta,
          version.isAcceptableOrUnknown(data['version']!, _versionMeta));
    }
    if (data.containsKey('issuance_date')) {
      context.handle(
          _issuanceDateMeta,
          issuanceDate.isAcceptableOrUnknown(
              data['issuance_date']!, _issuanceDateMeta));
    } else if (isInserting) {
      context.missing(_issuanceDateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('thread_id')) {
      context.handle(_threadIdMeta,
          threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta));
    }
    if (data.containsKey('contact_channel_did')) {
      context.handle(
          _contactChannelDidMeta,
          contactChannelDid.isAcceptableOrUnknown(
              data['contact_channel_did']!, _contactChannelDidMeta));
    }
    if (data.containsKey('local_channel_did')) {
      context.handle(
          _localChannelDidMeta,
          localChannelDid.isAcceptableOrUnknown(
              data['local_channel_did']!, _localChannelDidMeta));
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta,
          receivedAt.isAcceptableOrUnknown(
              data['received_at']!, _receivedAtMeta));
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {subjectDid};
  @override
  RCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RCardRow(
      subjectDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subject_did'])!,
      vcBlob: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vc_blob'])!,
      issuerDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}issuer_did'])!,
      version: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}version'])!,
      issuanceDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}issuance_date'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      threadId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thread_id']),
      contactChannelDid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}contact_channel_did']),
      localChannelDid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}local_channel_did']),
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}received_at'])!,
    );
  }

  @override
  $ReceivedRCardsTable createAlias(String alias) {
    return $ReceivedRCardsTable(attachedDatabase, alias);
  }
}

class RCardRow extends DataClass implements Insertable<RCardRow> {
  /// DID of the credential subject — serves as the primary key.
  final String subjectDid;

  /// Raw serialised VC JSON blob.
  final String vcBlob;

  /// DID of the credential issuer.
  final String issuerDid;

  /// Monotonically increasing version counter.  Starts at `1` and is
  /// incremented by the repository on every real (content-changing) upsert.
  final int version;

  /// UTC issuance date taken from the VC's `validFrom` field.
  final DateTime issuanceDate;

  /// Optional user-supplied notes about this contact.
  final String? notes;

  /// Optional DIDComm thread ID associated with the R-Card exchange.
  final String? threadId;

  /// Permanent channel DID of the contact who sent this R-Card.
  final String? contactChannelDid;

  /// Our own local permanent channel DID for the channel this R-Card arrived
  /// on.  Set only for the OOB / inauguration path; `null` for the VDIP path.
  final String? localChannelDid;

  /// UTC timestamp recording when the R-Card was first received locally.
  final DateTime receivedAt;
  const RCardRow(
      {required this.subjectDid,
      required this.vcBlob,
      required this.issuerDid,
      required this.version,
      required this.issuanceDate,
      this.notes,
      this.threadId,
      this.contactChannelDid,
      this.localChannelDid,
      required this.receivedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['subject_did'] = Variable<String>(subjectDid);
    map['vc_blob'] = Variable<String>(vcBlob);
    map['issuer_did'] = Variable<String>(issuerDid);
    map['version'] = Variable<int>(version);
    map['issuance_date'] = Variable<DateTime>(issuanceDate);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || threadId != null) {
      map['thread_id'] = Variable<String>(threadId);
    }
    if (!nullToAbsent || contactChannelDid != null) {
      map['contact_channel_did'] = Variable<String>(contactChannelDid);
    }
    if (!nullToAbsent || localChannelDid != null) {
      map['local_channel_did'] = Variable<String>(localChannelDid);
    }
    map['received_at'] = Variable<DateTime>(receivedAt);
    return map;
  }

  ReceivedRCardsCompanion toCompanion(bool nullToAbsent) {
    return ReceivedRCardsCompanion(
      subjectDid: Value(subjectDid),
      vcBlob: Value(vcBlob),
      issuerDid: Value(issuerDid),
      version: Value(version),
      issuanceDate: Value(issuanceDate),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      threadId: threadId == null && nullToAbsent
          ? const Value.absent()
          : Value(threadId),
      contactChannelDid: contactChannelDid == null && nullToAbsent
          ? const Value.absent()
          : Value(contactChannelDid),
      localChannelDid: localChannelDid == null && nullToAbsent
          ? const Value.absent()
          : Value(localChannelDid),
      receivedAt: Value(receivedAt),
    );
  }

  factory RCardRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RCardRow(
      subjectDid: serializer.fromJson<String>(json['subjectDid']),
      vcBlob: serializer.fromJson<String>(json['vcBlob']),
      issuerDid: serializer.fromJson<String>(json['issuerDid']),
      version: serializer.fromJson<int>(json['version']),
      issuanceDate: serializer.fromJson<DateTime>(json['issuanceDate']),
      notes: serializer.fromJson<String?>(json['notes']),
      threadId: serializer.fromJson<String?>(json['threadId']),
      contactChannelDid:
          serializer.fromJson<String?>(json['contactChannelDid']),
      localChannelDid: serializer.fromJson<String?>(json['localChannelDid']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'subjectDid': serializer.toJson<String>(subjectDid),
      'vcBlob': serializer.toJson<String>(vcBlob),
      'issuerDid': serializer.toJson<String>(issuerDid),
      'version': serializer.toJson<int>(version),
      'issuanceDate': serializer.toJson<DateTime>(issuanceDate),
      'notes': serializer.toJson<String?>(notes),
      'threadId': serializer.toJson<String?>(threadId),
      'contactChannelDid': serializer.toJson<String?>(contactChannelDid),
      'localChannelDid': serializer.toJson<String?>(localChannelDid),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
    };
  }

  RCardRow copyWith(
          {String? subjectDid,
          String? vcBlob,
          String? issuerDid,
          int? version,
          DateTime? issuanceDate,
          Value<String?> notes = const Value.absent(),
          Value<String?> threadId = const Value.absent(),
          Value<String?> contactChannelDid = const Value.absent(),
          Value<String?> localChannelDid = const Value.absent(),
          DateTime? receivedAt}) =>
      RCardRow(
        subjectDid: subjectDid ?? this.subjectDid,
        vcBlob: vcBlob ?? this.vcBlob,
        issuerDid: issuerDid ?? this.issuerDid,
        version: version ?? this.version,
        issuanceDate: issuanceDate ?? this.issuanceDate,
        notes: notes.present ? notes.value : this.notes,
        threadId: threadId.present ? threadId.value : this.threadId,
        contactChannelDid: contactChannelDid.present
            ? contactChannelDid.value
            : this.contactChannelDid,
        localChannelDid: localChannelDid.present
            ? localChannelDid.value
            : this.localChannelDid,
        receivedAt: receivedAt ?? this.receivedAt,
      );
  RCardRow copyWithCompanion(ReceivedRCardsCompanion data) {
    return RCardRow(
      subjectDid:
          data.subjectDid.present ? data.subjectDid.value : this.subjectDid,
      vcBlob: data.vcBlob.present ? data.vcBlob.value : this.vcBlob,
      issuerDid: data.issuerDid.present ? data.issuerDid.value : this.issuerDid,
      version: data.version.present ? data.version.value : this.version,
      issuanceDate: data.issuanceDate.present
          ? data.issuanceDate.value
          : this.issuanceDate,
      notes: data.notes.present ? data.notes.value : this.notes,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      contactChannelDid: data.contactChannelDid.present
          ? data.contactChannelDid.value
          : this.contactChannelDid,
      localChannelDid: data.localChannelDid.present
          ? data.localChannelDid.value
          : this.localChannelDid,
      receivedAt:
          data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RCardRow(')
          ..write('subjectDid: $subjectDid, ')
          ..write('vcBlob: $vcBlob, ')
          ..write('issuerDid: $issuerDid, ')
          ..write('version: $version, ')
          ..write('issuanceDate: $issuanceDate, ')
          ..write('notes: $notes, ')
          ..write('threadId: $threadId, ')
          ..write('contactChannelDid: $contactChannelDid, ')
          ..write('localChannelDid: $localChannelDid, ')
          ..write('receivedAt: $receivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      subjectDid,
      vcBlob,
      issuerDid,
      version,
      issuanceDate,
      notes,
      threadId,
      contactChannelDid,
      localChannelDid,
      receivedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RCardRow &&
          other.subjectDid == this.subjectDid &&
          other.vcBlob == this.vcBlob &&
          other.issuerDid == this.issuerDid &&
          other.version == this.version &&
          other.issuanceDate == this.issuanceDate &&
          other.notes == this.notes &&
          other.threadId == this.threadId &&
          other.contactChannelDid == this.contactChannelDid &&
          other.localChannelDid == this.localChannelDid &&
          other.receivedAt == this.receivedAt);
}

class ReceivedRCardsCompanion extends UpdateCompanion<RCardRow> {
  final Value<String> subjectDid;
  final Value<String> vcBlob;
  final Value<String> issuerDid;
  final Value<int> version;
  final Value<DateTime> issuanceDate;
  final Value<String?> notes;
  final Value<String?> threadId;
  final Value<String?> contactChannelDid;
  final Value<String?> localChannelDid;
  final Value<DateTime> receivedAt;
  final Value<int> rowid;
  const ReceivedRCardsCompanion({
    this.subjectDid = const Value.absent(),
    this.vcBlob = const Value.absent(),
    this.issuerDid = const Value.absent(),
    this.version = const Value.absent(),
    this.issuanceDate = const Value.absent(),
    this.notes = const Value.absent(),
    this.threadId = const Value.absent(),
    this.contactChannelDid = const Value.absent(),
    this.localChannelDid = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceivedRCardsCompanion.insert({
    required String subjectDid,
    required String vcBlob,
    required String issuerDid,
    this.version = const Value.absent(),
    required DateTime issuanceDate,
    this.notes = const Value.absent(),
    this.threadId = const Value.absent(),
    this.contactChannelDid = const Value.absent(),
    this.localChannelDid = const Value.absent(),
    required DateTime receivedAt,
    this.rowid = const Value.absent(),
  })  : subjectDid = Value(subjectDid),
        vcBlob = Value(vcBlob),
        issuerDid = Value(issuerDid),
        issuanceDate = Value(issuanceDate),
        receivedAt = Value(receivedAt);
  static Insertable<RCardRow> custom({
    Expression<String>? subjectDid,
    Expression<String>? vcBlob,
    Expression<String>? issuerDid,
    Expression<int>? version,
    Expression<DateTime>? issuanceDate,
    Expression<String>? notes,
    Expression<String>? threadId,
    Expression<String>? contactChannelDid,
    Expression<String>? localChannelDid,
    Expression<DateTime>? receivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (subjectDid != null) 'subject_did': subjectDid,
      if (vcBlob != null) 'vc_blob': vcBlob,
      if (issuerDid != null) 'issuer_did': issuerDid,
      if (version != null) 'version': version,
      if (issuanceDate != null) 'issuance_date': issuanceDate,
      if (notes != null) 'notes': notes,
      if (threadId != null) 'thread_id': threadId,
      if (contactChannelDid != null) 'contact_channel_did': contactChannelDid,
      if (localChannelDid != null) 'local_channel_did': localChannelDid,
      if (receivedAt != null) 'received_at': receivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceivedRCardsCompanion copyWith(
      {Value<String>? subjectDid,
      Value<String>? vcBlob,
      Value<String>? issuerDid,
      Value<int>? version,
      Value<DateTime>? issuanceDate,
      Value<String?>? notes,
      Value<String?>? threadId,
      Value<String?>? contactChannelDid,
      Value<String?>? localChannelDid,
      Value<DateTime>? receivedAt,
      Value<int>? rowid}) {
    return ReceivedRCardsCompanion(
      subjectDid: subjectDid ?? this.subjectDid,
      vcBlob: vcBlob ?? this.vcBlob,
      issuerDid: issuerDid ?? this.issuerDid,
      version: version ?? this.version,
      issuanceDate: issuanceDate ?? this.issuanceDate,
      notes: notes ?? this.notes,
      threadId: threadId ?? this.threadId,
      contactChannelDid: contactChannelDid ?? this.contactChannelDid,
      localChannelDid: localChannelDid ?? this.localChannelDid,
      receivedAt: receivedAt ?? this.receivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (subjectDid.present) {
      map['subject_did'] = Variable<String>(subjectDid.value);
    }
    if (vcBlob.present) {
      map['vc_blob'] = Variable<String>(vcBlob.value);
    }
    if (issuerDid.present) {
      map['issuer_did'] = Variable<String>(issuerDid.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (issuanceDate.present) {
      map['issuance_date'] = Variable<DateTime>(issuanceDate.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (contactChannelDid.present) {
      map['contact_channel_did'] = Variable<String>(contactChannelDid.value);
    }
    if (localChannelDid.present) {
      map['local_channel_did'] = Variable<String>(localChannelDid.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceivedRCardsCompanion(')
          ..write('subjectDid: $subjectDid, ')
          ..write('vcBlob: $vcBlob, ')
          ..write('issuerDid: $issuerDid, ')
          ..write('version: $version, ')
          ..write('issuanceDate: $issuanceDate, ')
          ..write('notes: $notes, ')
          ..write('threadId: $threadId, ')
          ..write('contactChannelDid: $contactChannelDid, ')
          ..write('localChannelDid: $localChannelDid, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$RCardDatabase extends GeneratedDatabase {
  _$RCardDatabase(QueryExecutor e) : super(e);
  $RCardDatabaseManager get managers => $RCardDatabaseManager(this);
  late final $ReceivedRCardsTable receivedRCards = $ReceivedRCardsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [receivedRCards];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ReceivedRCardsTableCreateCompanionBuilder = ReceivedRCardsCompanion
    Function({
  required String subjectDid,
  required String vcBlob,
  required String issuerDid,
  Value<int> version,
  required DateTime issuanceDate,
  Value<String?> notes,
  Value<String?> threadId,
  Value<String?> contactChannelDid,
  Value<String?> localChannelDid,
  required DateTime receivedAt,
  Value<int> rowid,
});
typedef $$ReceivedRCardsTableUpdateCompanionBuilder = ReceivedRCardsCompanion
    Function({
  Value<String> subjectDid,
  Value<String> vcBlob,
  Value<String> issuerDid,
  Value<int> version,
  Value<DateTime> issuanceDate,
  Value<String?> notes,
  Value<String?> threadId,
  Value<String?> contactChannelDid,
  Value<String?> localChannelDid,
  Value<DateTime> receivedAt,
  Value<int> rowid,
});

class $$ReceivedRCardsTableFilterComposer
    extends Composer<_$RCardDatabase, $ReceivedRCardsTable> {
  $$ReceivedRCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get subjectDid => $composableBuilder(
      column: $table.subjectDid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vcBlob => $composableBuilder(
      column: $table.vcBlob, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get issuerDid => $composableBuilder(
      column: $table.issuerDid, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get issuanceDate => $composableBuilder(
      column: $table.issuanceDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get threadId => $composableBuilder(
      column: $table.threadId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contactChannelDid => $composableBuilder(
      column: $table.contactChannelDid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localChannelDid => $composableBuilder(
      column: $table.localChannelDid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnFilters(column));
}

class $$ReceivedRCardsTableOrderingComposer
    extends Composer<_$RCardDatabase, $ReceivedRCardsTable> {
  $$ReceivedRCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get subjectDid => $composableBuilder(
      column: $table.subjectDid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vcBlob => $composableBuilder(
      column: $table.vcBlob, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get issuerDid => $composableBuilder(
      column: $table.issuerDid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get version => $composableBuilder(
      column: $table.version, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get issuanceDate => $composableBuilder(
      column: $table.issuanceDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get threadId => $composableBuilder(
      column: $table.threadId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contactChannelDid => $composableBuilder(
      column: $table.contactChannelDid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localChannelDid => $composableBuilder(
      column: $table.localChannelDid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnOrderings(column));
}

class $$ReceivedRCardsTableAnnotationComposer
    extends Composer<_$RCardDatabase, $ReceivedRCardsTable> {
  $$ReceivedRCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get subjectDid => $composableBuilder(
      column: $table.subjectDid, builder: (column) => column);

  GeneratedColumn<String> get vcBlob =>
      $composableBuilder(column: $table.vcBlob, builder: (column) => column);

  GeneratedColumn<String> get issuerDid =>
      $composableBuilder(column: $table.issuerDid, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get issuanceDate => $composableBuilder(
      column: $table.issuanceDate, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get contactChannelDid => $composableBuilder(
      column: $table.contactChannelDid, builder: (column) => column);

  GeneratedColumn<String> get localChannelDid => $composableBuilder(
      column: $table.localChannelDid, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => column);
}

class $$ReceivedRCardsTableTableManager extends RootTableManager<
    _$RCardDatabase,
    $ReceivedRCardsTable,
    RCardRow,
    $$ReceivedRCardsTableFilterComposer,
    $$ReceivedRCardsTableOrderingComposer,
    $$ReceivedRCardsTableAnnotationComposer,
    $$ReceivedRCardsTableCreateCompanionBuilder,
    $$ReceivedRCardsTableUpdateCompanionBuilder,
    (RCardRow, BaseReferences<_$RCardDatabase, $ReceivedRCardsTable, RCardRow>),
    RCardRow,
    PrefetchHooks Function()> {
  $$ReceivedRCardsTableTableManager(
      _$RCardDatabase db, $ReceivedRCardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceivedRCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceivedRCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceivedRCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> subjectDid = const Value.absent(),
            Value<String> vcBlob = const Value.absent(),
            Value<String> issuerDid = const Value.absent(),
            Value<int> version = const Value.absent(),
            Value<DateTime> issuanceDate = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> threadId = const Value.absent(),
            Value<String?> contactChannelDid = const Value.absent(),
            Value<String?> localChannelDid = const Value.absent(),
            Value<DateTime> receivedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceivedRCardsCompanion(
            subjectDid: subjectDid,
            vcBlob: vcBlob,
            issuerDid: issuerDid,
            version: version,
            issuanceDate: issuanceDate,
            notes: notes,
            threadId: threadId,
            contactChannelDid: contactChannelDid,
            localChannelDid: localChannelDid,
            receivedAt: receivedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String subjectDid,
            required String vcBlob,
            required String issuerDid,
            Value<int> version = const Value.absent(),
            required DateTime issuanceDate,
            Value<String?> notes = const Value.absent(),
            Value<String?> threadId = const Value.absent(),
            Value<String?> contactChannelDid = const Value.absent(),
            Value<String?> localChannelDid = const Value.absent(),
            required DateTime receivedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReceivedRCardsCompanion.insert(
            subjectDid: subjectDid,
            vcBlob: vcBlob,
            issuerDid: issuerDid,
            version: version,
            issuanceDate: issuanceDate,
            notes: notes,
            threadId: threadId,
            contactChannelDid: contactChannelDid,
            localChannelDid: localChannelDid,
            receivedAt: receivedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ReceivedRCardsTableProcessedTableManager = ProcessedTableManager<
    _$RCardDatabase,
    $ReceivedRCardsTable,
    RCardRow,
    $$ReceivedRCardsTableFilterComposer,
    $$ReceivedRCardsTableOrderingComposer,
    $$ReceivedRCardsTableAnnotationComposer,
    $$ReceivedRCardsTableCreateCompanionBuilder,
    $$ReceivedRCardsTableUpdateCompanionBuilder,
    (RCardRow, BaseReferences<_$RCardDatabase, $ReceivedRCardsTable, RCardRow>),
    RCardRow,
    PrefetchHooks Function()>;

class $RCardDatabaseManager {
  final _$RCardDatabase _db;
  $RCardDatabaseManager(this._db);
  $$ReceivedRCardsTableTableManager get receivedRCards =>
      $$ReceivedRCardsTableTableManager(_db, _db.receivedRCards);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stored_vrc_database.dart';

// ignore_for_file: type=lint
class $VrcsTable extends Vrcs with TableInfo<$VrcsTable, VrcRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VrcsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vcBlobMeta = const VerificationMeta('vcBlob');
  @override
  late final GeneratedColumn<String> vcBlob = GeneratedColumn<String>(
      'vc_blob', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _channelIdMeta =
      const VerificationMeta('channelId');
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
      'channel_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _holderDidMeta =
      const VerificationMeta('holderDid');
  @override
  late final GeneratedColumn<String> holderDid = GeneratedColumn<String>(
      'holder_did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _issuerDidMeta =
      const VerificationMeta('issuerDid');
  @override
  late final GeneratedColumn<String> issuerDid = GeneratedColumn<String>(
      'issuer_did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _issuedAtMeta =
      const VerificationMeta('issuedAt');
  @override
  late final GeneratedColumn<DateTime> issuedAt = GeneratedColumn<DateTime>(
      'issued_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _verifiedAtMeta =
      const VerificationMeta('verifiedAt');
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
      'verified_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _receivedAtMeta =
      const VerificationMeta('receivedAt');
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
      'received_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _credentialFormatMeta =
      const VerificationMeta('credentialFormat');
  @override
  late final GeneratedColumn<String> credentialFormat = GeneratedColumn<String>(
      'credential_format', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        vcBlob,
        channelId,
        holderDid,
        issuerDid,
        issuedAt,
        verifiedAt,
        receivedAt,
        credentialFormat
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vrcs';
  @override
  VerificationContext validateIntegrity(Insertable<VrcRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('vc_blob')) {
      context.handle(_vcBlobMeta,
          vcBlob.isAcceptableOrUnknown(data['vc_blob']!, _vcBlobMeta));
    } else if (isInserting) {
      context.missing(_vcBlobMeta);
    }
    if (data.containsKey('channel_id')) {
      context.handle(_channelIdMeta,
          channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta));
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    if (data.containsKey('holder_did')) {
      context.handle(_holderDidMeta,
          holderDid.isAcceptableOrUnknown(data['holder_did']!, _holderDidMeta));
    } else if (isInserting) {
      context.missing(_holderDidMeta);
    }
    if (data.containsKey('issuer_did')) {
      context.handle(_issuerDidMeta,
          issuerDid.isAcceptableOrUnknown(data['issuer_did']!, _issuerDidMeta));
    } else if (isInserting) {
      context.missing(_issuerDidMeta);
    }
    if (data.containsKey('issued_at')) {
      context.handle(_issuedAtMeta,
          issuedAt.isAcceptableOrUnknown(data['issued_at']!, _issuedAtMeta));
    } else if (isInserting) {
      context.missing(_issuedAtMeta);
    }
    if (data.containsKey('verified_at')) {
      context.handle(
          _verifiedAtMeta,
          verifiedAt.isAcceptableOrUnknown(
              data['verified_at']!, _verifiedAtMeta));
    }
    if (data.containsKey('received_at')) {
      context.handle(
          _receivedAtMeta,
          receivedAt.isAcceptableOrUnknown(
              data['received_at']!, _receivedAtMeta));
    }
    if (data.containsKey('credential_format')) {
      context.handle(
          _credentialFormatMeta,
          credentialFormat.isAcceptableOrUnknown(
              data['credential_format']!, _credentialFormatMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VrcRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VrcRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      vcBlob: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vc_blob'])!,
      channelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}channel_id'])!,
      holderDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}holder_did'])!,
      issuerDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}issuer_did'])!,
      issuedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}issued_at'])!,
      verifiedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}verified_at']),
      receivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}received_at']),
      credentialFormat: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}credential_format']),
    );
  }

  @override
  $VrcsTable createAlias(String alias) {
    return $VrcsTable(attachedDatabase, alias);
  }
}

class VrcRow extends DataClass implements Insertable<VrcRow> {
  /// Stable credential identifier used as the primary key.
  final String id;

  /// Raw serialized VC JSON blob.
  final String vcBlob;

  /// Channel identifier used by the consumer app.
  final String channelId;

  /// DID of the credential holder.
  final String holderDid;

  /// DID of the credential issuer.
  final String issuerDid;

  /// Credential issuance timestamp.
  final DateTime issuedAt;

  /// Optional verification timestamp.
  final DateTime? verifiedAt;

  /// Optional receipt timestamp.
  final DateTime? receivedAt;

  /// Optional credential format metadata.
  final String? credentialFormat;
  const VrcRow(
      {required this.id,
      required this.vcBlob,
      required this.channelId,
      required this.holderDid,
      required this.issuerDid,
      required this.issuedAt,
      this.verifiedAt,
      this.receivedAt,
      this.credentialFormat});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['vc_blob'] = Variable<String>(vcBlob);
    map['channel_id'] = Variable<String>(channelId);
    map['holder_did'] = Variable<String>(holderDid);
    map['issuer_did'] = Variable<String>(issuerDid);
    map['issued_at'] = Variable<DateTime>(issuedAt);
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
    }
    if (!nullToAbsent || receivedAt != null) {
      map['received_at'] = Variable<DateTime>(receivedAt);
    }
    if (!nullToAbsent || credentialFormat != null) {
      map['credential_format'] = Variable<String>(credentialFormat);
    }
    return map;
  }

  VrcsCompanion toCompanion(bool nullToAbsent) {
    return VrcsCompanion(
      id: Value(id),
      vcBlob: Value(vcBlob),
      channelId: Value(channelId),
      holderDid: Value(holderDid),
      issuerDid: Value(issuerDid),
      issuedAt: Value(issuedAt),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
      receivedAt: receivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(receivedAt),
      credentialFormat: credentialFormat == null && nullToAbsent
          ? const Value.absent()
          : Value(credentialFormat),
    );
  }

  factory VrcRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VrcRow(
      id: serializer.fromJson<String>(json['id']),
      vcBlob: serializer.fromJson<String>(json['vcBlob']),
      channelId: serializer.fromJson<String>(json['channelId']),
      holderDid: serializer.fromJson<String>(json['holderDid']),
      issuerDid: serializer.fromJson<String>(json['issuerDid']),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
      receivedAt: serializer.fromJson<DateTime?>(json['receivedAt']),
      credentialFormat: serializer.fromJson<String?>(json['credentialFormat']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'vcBlob': serializer.toJson<String>(vcBlob),
      'channelId': serializer.toJson<String>(channelId),
      'holderDid': serializer.toJson<String>(holderDid),
      'issuerDid': serializer.toJson<String>(issuerDid),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
      'receivedAt': serializer.toJson<DateTime?>(receivedAt),
      'credentialFormat': serializer.toJson<String?>(credentialFormat),
    };
  }

  VrcRow copyWith(
          {String? id,
          String? vcBlob,
          String? channelId,
          String? holderDid,
          String? issuerDid,
          DateTime? issuedAt,
          Value<DateTime?> verifiedAt = const Value.absent(),
          Value<DateTime?> receivedAt = const Value.absent(),
          Value<String?> credentialFormat = const Value.absent()}) =>
      VrcRow(
        id: id ?? this.id,
        vcBlob: vcBlob ?? this.vcBlob,
        channelId: channelId ?? this.channelId,
        holderDid: holderDid ?? this.holderDid,
        issuerDid: issuerDid ?? this.issuerDid,
        issuedAt: issuedAt ?? this.issuedAt,
        verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
        receivedAt: receivedAt.present ? receivedAt.value : this.receivedAt,
        credentialFormat: credentialFormat.present
            ? credentialFormat.value
            : this.credentialFormat,
      );
  VrcRow copyWithCompanion(VrcsCompanion data) {
    return VrcRow(
      id: data.id.present ? data.id.value : this.id,
      vcBlob: data.vcBlob.present ? data.vcBlob.value : this.vcBlob,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      holderDid: data.holderDid.present ? data.holderDid.value : this.holderDid,
      issuerDid: data.issuerDid.present ? data.issuerDid.value : this.issuerDid,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      verifiedAt:
          data.verifiedAt.present ? data.verifiedAt.value : this.verifiedAt,
      receivedAt:
          data.receivedAt.present ? data.receivedAt.value : this.receivedAt,
      credentialFormat: data.credentialFormat.present
          ? data.credentialFormat.value
          : this.credentialFormat,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VrcRow(')
          ..write('id: $id, ')
          ..write('vcBlob: $vcBlob, ')
          ..write('channelId: $channelId, ')
          ..write('holderDid: $holderDid, ')
          ..write('issuerDid: $issuerDid, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('credentialFormat: $credentialFormat')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, vcBlob, channelId, holderDid, issuerDid,
      issuedAt, verifiedAt, receivedAt, credentialFormat);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VrcRow &&
          other.id == this.id &&
          other.vcBlob == this.vcBlob &&
          other.channelId == this.channelId &&
          other.holderDid == this.holderDid &&
          other.issuerDid == this.issuerDid &&
          other.issuedAt == this.issuedAt &&
          other.verifiedAt == this.verifiedAt &&
          other.receivedAt == this.receivedAt &&
          other.credentialFormat == this.credentialFormat);
}

class VrcsCompanion extends UpdateCompanion<VrcRow> {
  final Value<String> id;
  final Value<String> vcBlob;
  final Value<String> channelId;
  final Value<String> holderDid;
  final Value<String> issuerDid;
  final Value<DateTime> issuedAt;
  final Value<DateTime?> verifiedAt;
  final Value<DateTime?> receivedAt;
  final Value<String?> credentialFormat;
  final Value<int> rowid;
  const VrcsCompanion({
    this.id = const Value.absent(),
    this.vcBlob = const Value.absent(),
    this.channelId = const Value.absent(),
    this.holderDid = const Value.absent(),
    this.issuerDid = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.credentialFormat = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VrcsCompanion.insert({
    required String id,
    required String vcBlob,
    required String channelId,
    required String holderDid,
    required String issuerDid,
    required DateTime issuedAt,
    this.verifiedAt = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.credentialFormat = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        vcBlob = Value(vcBlob),
        channelId = Value(channelId),
        holderDid = Value(holderDid),
        issuerDid = Value(issuerDid),
        issuedAt = Value(issuedAt);
  static Insertable<VrcRow> custom({
    Expression<String>? id,
    Expression<String>? vcBlob,
    Expression<String>? channelId,
    Expression<String>? holderDid,
    Expression<String>? issuerDid,
    Expression<DateTime>? issuedAt,
    Expression<DateTime>? verifiedAt,
    Expression<DateTime>? receivedAt,
    Expression<String>? credentialFormat,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vcBlob != null) 'vc_blob': vcBlob,
      if (channelId != null) 'channel_id': channelId,
      if (holderDid != null) 'holder_did': holderDid,
      if (issuerDid != null) 'issuer_did': issuerDid,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (receivedAt != null) 'received_at': receivedAt,
      if (credentialFormat != null) 'credential_format': credentialFormat,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VrcsCompanion copyWith(
      {Value<String>? id,
      Value<String>? vcBlob,
      Value<String>? channelId,
      Value<String>? holderDid,
      Value<String>? issuerDid,
      Value<DateTime>? issuedAt,
      Value<DateTime?>? verifiedAt,
      Value<DateTime?>? receivedAt,
      Value<String?>? credentialFormat,
      Value<int>? rowid}) {
    return VrcsCompanion(
      id: id ?? this.id,
      vcBlob: vcBlob ?? this.vcBlob,
      channelId: channelId ?? this.channelId,
      holderDid: holderDid ?? this.holderDid,
      issuerDid: issuerDid ?? this.issuerDid,
      issuedAt: issuedAt ?? this.issuedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      credentialFormat: credentialFormat ?? this.credentialFormat,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (vcBlob.present) {
      map['vc_blob'] = Variable<String>(vcBlob.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (holderDid.present) {
      map['holder_did'] = Variable<String>(holderDid.value);
    }
    if (issuerDid.present) {
      map['issuer_did'] = Variable<String>(issuerDid.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<DateTime>(issuedAt.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (credentialFormat.present) {
      map['credential_format'] = Variable<String>(credentialFormat.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VrcsCompanion(')
          ..write('id: $id, ')
          ..write('vcBlob: $vcBlob, ')
          ..write('channelId: $channelId, ')
          ..write('holderDid: $holderDid, ')
          ..write('issuerDid: $issuerDid, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('credentialFormat: $credentialFormat, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$VrcDatabase extends GeneratedDatabase {
  _$VrcDatabase(QueryExecutor e) : super(e);
  $VrcDatabaseManager get managers => $VrcDatabaseManager(this);
  late final $VrcsTable vrcs = $VrcsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [vrcs];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$VrcsTableCreateCompanionBuilder = VrcsCompanion Function({
  required String id,
  required String vcBlob,
  required String channelId,
  required String holderDid,
  required String issuerDid,
  required DateTime issuedAt,
  Value<DateTime?> verifiedAt,
  Value<DateTime?> receivedAt,
  Value<String?> credentialFormat,
  Value<int> rowid,
});
typedef $$VrcsTableUpdateCompanionBuilder = VrcsCompanion Function({
  Value<String> id,
  Value<String> vcBlob,
  Value<String> channelId,
  Value<String> holderDid,
  Value<String> issuerDid,
  Value<DateTime> issuedAt,
  Value<DateTime?> verifiedAt,
  Value<DateTime?> receivedAt,
  Value<String?> credentialFormat,
  Value<int> rowid,
});

class $$VrcsTableFilterComposer extends Composer<_$VrcDatabase, $VrcsTable> {
  $$VrcsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vcBlob => $composableBuilder(
      column: $table.vcBlob, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get channelId => $composableBuilder(
      column: $table.channelId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get holderDid => $composableBuilder(
      column: $table.holderDid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get issuerDid => $composableBuilder(
      column: $table.issuerDid, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get issuedAt => $composableBuilder(
      column: $table.issuedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get verifiedAt => $composableBuilder(
      column: $table.verifiedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get credentialFormat => $composableBuilder(
      column: $table.credentialFormat,
      builder: (column) => ColumnFilters(column));
}

class $$VrcsTableOrderingComposer extends Composer<_$VrcDatabase, $VrcsTable> {
  $$VrcsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vcBlob => $composableBuilder(
      column: $table.vcBlob, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get channelId => $composableBuilder(
      column: $table.channelId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get holderDid => $composableBuilder(
      column: $table.holderDid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get issuerDid => $composableBuilder(
      column: $table.issuerDid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get issuedAt => $composableBuilder(
      column: $table.issuedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get verifiedAt => $composableBuilder(
      column: $table.verifiedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get credentialFormat => $composableBuilder(
      column: $table.credentialFormat,
      builder: (column) => ColumnOrderings(column));
}

class $$VrcsTableAnnotationComposer
    extends Composer<_$VrcDatabase, $VrcsTable> {
  $$VrcsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vcBlob =>
      $composableBuilder(column: $table.vcBlob, builder: (column) => column);

  GeneratedColumn<String> get channelId =>
      $composableBuilder(column: $table.channelId, builder: (column) => column);

  GeneratedColumn<String> get holderDid =>
      $composableBuilder(column: $table.holderDid, builder: (column) => column);

  GeneratedColumn<String> get issuerDid =>
      $composableBuilder(column: $table.issuerDid, builder: (column) => column);

  GeneratedColumn<DateTime> get issuedAt =>
      $composableBuilder(column: $table.issuedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get verifiedAt => $composableBuilder(
      column: $table.verifiedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
      column: $table.receivedAt, builder: (column) => column);

  GeneratedColumn<String> get credentialFormat => $composableBuilder(
      column: $table.credentialFormat, builder: (column) => column);
}

class $$VrcsTableTableManager extends RootTableManager<
    _$VrcDatabase,
    $VrcsTable,
    VrcRow,
    $$VrcsTableFilterComposer,
    $$VrcsTableOrderingComposer,
    $$VrcsTableAnnotationComposer,
    $$VrcsTableCreateCompanionBuilder,
    $$VrcsTableUpdateCompanionBuilder,
    (VrcRow, BaseReferences<_$VrcDatabase, $VrcsTable, VrcRow>),
    VrcRow,
    PrefetchHooks Function()> {
  $$VrcsTableTableManager(_$VrcDatabase db, $VrcsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VrcsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VrcsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VrcsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> vcBlob = const Value.absent(),
            Value<String> channelId = const Value.absent(),
            Value<String> holderDid = const Value.absent(),
            Value<String> issuerDid = const Value.absent(),
            Value<DateTime> issuedAt = const Value.absent(),
            Value<DateTime?> verifiedAt = const Value.absent(),
            Value<DateTime?> receivedAt = const Value.absent(),
            Value<String?> credentialFormat = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VrcsCompanion(
            id: id,
            vcBlob: vcBlob,
            channelId: channelId,
            holderDid: holderDid,
            issuerDid: issuerDid,
            issuedAt: issuedAt,
            verifiedAt: verifiedAt,
            receivedAt: receivedAt,
            credentialFormat: credentialFormat,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String vcBlob,
            required String channelId,
            required String holderDid,
            required String issuerDid,
            required DateTime issuedAt,
            Value<DateTime?> verifiedAt = const Value.absent(),
            Value<DateTime?> receivedAt = const Value.absent(),
            Value<String?> credentialFormat = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VrcsCompanion.insert(
            id: id,
            vcBlob: vcBlob,
            channelId: channelId,
            holderDid: holderDid,
            issuerDid: issuerDid,
            issuedAt: issuedAt,
            verifiedAt: verifiedAt,
            receivedAt: receivedAt,
            credentialFormat: credentialFormat,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VrcsTableProcessedTableManager = ProcessedTableManager<
    _$VrcDatabase,
    $VrcsTable,
    VrcRow,
    $$VrcsTableFilterComposer,
    $$VrcsTableOrderingComposer,
    $$VrcsTableAnnotationComposer,
    $$VrcsTableCreateCompanionBuilder,
    $$VrcsTableUpdateCompanionBuilder,
    (VrcRow, BaseReferences<_$VrcDatabase, $VrcsTable, VrcRow>),
    VrcRow,
    PrefetchHooks Function()>;

class $VrcDatabaseManager {
  final _$VrcDatabase _db;
  $VrcDatabaseManager(this._db);
  $$VrcsTableTableManager get vrcs => $$VrcsTableTableManager(_db, _db.vrcs);
}

import 'package:drift/drift.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart'
    as model;

import 'vrc_database.dart' as db;

/// Drift-backed implementation of [model.VrcRepository].
class VrcRepositoryDrift implements model.VrcRepository {
  /// Creates a new repository with the given [database].
  VrcRepositoryDrift({required db.VrcDatabase database}) : _database = database;

  final db.VrcDatabase _database;

  /// Inserts or updates [vrc], keyed on [model.Vrc.id].
  ///
  /// When the stored [model.Vrc.vcBlob] is unchanged, only the remaining
  /// fields are refreshed; otherwise the full record is inserted or replaced.
  @override
  Future<void> upsert(model.Vrc vrc) async {
    await _database.transaction(() async {
      final existing = await (_database.select(
        _database.vrcs,
      )..where((t) => t.id.equals(vrc.id))).getSingleOrNull();

      if (existing != null && existing.vcBlob == vrc.vcBlob) {
        await (_database.update(
          _database.vrcs,
        )..where((t) => t.id.equals(vrc.id))).write(
          db.VrcsCompanion(
            referenceId: Value(vrc.referenceId),
            holderDid: Value(vrc.holderDid),
            issuerDid: Value(vrc.issuerDid),
            issuedAt: Value(vrc.issuedAt),
            verifiedAt: Value(vrc.verifiedAt),
            receivedAt: Value(vrc.receivedAt),
            credentialFormat: Value(vrc.credentialFormat),
          ),
        );
        return;
      }

      await _database
          .into(_database.vrcs)
          .insertOnConflictUpdate(
            db.VrcsCompanion(
              id: Value(vrc.id),
              vcBlob: Value(vrc.vcBlob),
              referenceId: Value(vrc.referenceId),
              holderDid: Value(vrc.holderDid),
              issuerDid: Value(vrc.issuerDid),
              issuedAt: Value(vrc.issuedAt),
              verifiedAt: Value(vrc.verifiedAt),
              receivedAt: Value(vrc.receivedAt),
              credentialFormat: Value(vrc.credentialFormat),
            ),
          );
    });
  }

  /// Returns a live stream of all stored VRCs ordered by
  /// [model.Vrc.issuedAt] descending.
  @override
  Stream<List<model.Vrc>> watchAll() {
    return (_database.select(_database.vrcs)
          ..orderBy([(t) => OrderingTerm.desc(t.issuedAt)]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  /// Returns a snapshot of all stored VRCs ordered by [model.Vrc.issuedAt]
  /// descending.
  @override
  Future<List<model.Vrc>> listAll() async {
    final rows = await (_database.select(
      _database.vrcs,
    )..orderBy([(t) => OrderingTerm.desc(t.issuedAt)])).get();
    return rows.map(_mapRow).toList();
  }

  /// Returns the VRC with the matching [id], or `null`.
  @override
  Future<model.Vrc?> getById(String id) async {
    final row = await (_database.select(
      _database.vrcs,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  /// Returns all VRCs held by [holderDid], ordered by [model.Vrc.issuedAt]
  /// descending.
  @override
  Future<List<model.Vrc>> listByHolderDid(String holderDid) async {
    final rows =
        await (_database.select(_database.vrcs)
              ..where((t) => t.holderDid.equals(holderDid))
              ..orderBy([(t) => OrderingTerm.desc(t.issuedAt)]))
            .get();
    return rows.map(_mapRow).toList();
  }

  /// Returns the number of VRCs held by [holderDid].
  @override
  Future<int> countByHolderDid(String holderDid) async {
    final countExp = _database.vrcs.id.count();
    final query = _database.selectOnly(_database.vrcs)
      ..addColumns([countExp])
      ..where(_database.vrcs.holderDid.equals(holderDid));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// Removes the VRC identified by [id].
  @override
  Future<void> deleteById(String id) async {
    await (_database.delete(
      _database.vrcs,
    )..where((t) => t.id.equals(id))).go();
  }

  model.Vrc _mapRow(db.VrcRow row) {
    return model.Vrc(
      id: row.id,
      vcBlob: row.vcBlob,
      referenceId: row.referenceId,
      holderDid: row.holderDid,
      issuerDid: row.issuerDid,
      issuedAt: row.issuedAt,
      verifiedAt: row.verifiedAt,
      receivedAt: row.receivedAt,
      credentialFormat: row.credentialFormat,
    );
  }
}

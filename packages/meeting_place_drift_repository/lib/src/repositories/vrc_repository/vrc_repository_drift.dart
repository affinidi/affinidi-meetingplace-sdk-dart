import 'package:drift/drift.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart'
    as model;

import 'vrc_database.dart' as db;

/// Drift-backed implementation of [model.VrcRepository].
class VrcRepositoryDrift implements model.VrcRepository {
  /// Creates a new repository with the given [database].
  VrcRepositoryDrift({required db.VrcDatabase database}) : _database = database;

  final db.VrcDatabase _database;

  @override
  Future<void> upsert(model.Vrc vrc) async {
    await _database.transaction(() async {
      final existing = await (_database.select(_database.vrcs)
            ..where((t) => t.id.equals(vrc.id)))
          .getSingleOrNull();

      if (existing != null && existing.referenceId == vrc.vcBlob) {
        await (_database.update(_database.vrcs)
              ..where((t) => t.id.equals(vrc.id)))
            .write(
          db.VrcsCompanion(
            channelId: Value(vrc.channelId),
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

      await _database.into(_database.vrcs).insertOnConflictUpdate(
            db.VrcsCompanion(
              id: Value(vrc.id),
              referenceId: Value(vrc.vcBlob),
              channelId: Value(vrc.channelId),
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

  @override
  Stream<List<model.Vrc>> watchAll() {
    return (_database.select(_database.vrcs)
          ..orderBy([(t) => OrderingTerm.desc(t.issuedAt)]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Future<List<model.Vrc>> listAll() async {
    final rows = await (_database.select(_database.vrcs)
          ..orderBy([(t) => OrderingTerm.desc(t.issuedAt)]))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<model.Vrc?> getById(String id) async {
    final row = await (_database.select(_database.vrcs)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<List<model.Vrc>> listByHolderDid(String holderDid) async {
    final rows = await (_database.select(_database.vrcs)
          ..where((t) => t.holderDid.equals(holderDid))
          ..orderBy([(t) => OrderingTerm.desc(t.issuedAt)]))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<int> countByHolderDid(String holderDid) async {
    final countExp = _database.vrcs.id.count();
    final query = _database.selectOnly(_database.vrcs)
      ..addColumns([countExp])
      ..where(_database.vrcs.holderDid.equals(holderDid));
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  @override
  Future<void> deleteById(String id) async {
    await (_database.delete(_database.vrcs)..where((t) => t.id.equals(id)))
        .go();
  }

  model.Vrc _mapRow(db.VrcRow row) {
    return model.Vrc(
      id: row.id,
      vcBlob: row.referenceId,
      channelId: row.channelId,
      holderDid: row.holderDid,
      issuerDid: row.issuerDid,
      issuedAt: row.issuedAt,
      verifiedAt: row.verifiedAt,
      receivedAt: row.receivedAt,
      credentialFormat: row.credentialFormat,
    );
  }
}

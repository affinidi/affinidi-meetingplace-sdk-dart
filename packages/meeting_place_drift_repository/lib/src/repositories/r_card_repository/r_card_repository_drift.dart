import 'package:drift/drift.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart'
    as model;

import 'r_card_database.dart' as db;

/// Repository implementation for managing [model.RCard] entities
/// using a Drift-backed [db.RCardDatabase].
///
/// Implements [model.RCardRepository] — inject this into
/// `MeetingPlaceRelationshipSDK` to enable automatic local persistence of
/// every incoming R-Card.
class RCardRepositoryDrift implements model.RCardRepository {
  /// Creates a new repository with the given [database].
  RCardRepositoryDrift({required db.RCardDatabase database})
    : _database = database;

  final db.RCardDatabase _database;

  /// Inserts or updates [rCard], keyed on [model.RCard.subjectDid].
  ///
  /// The [model.RCard.vcBlob] is compared directly; canonicalisation is
  /// applied upstream when the [model.RCard] is constructed, so a plain
  /// string comparison is sufficient to detect no-op updates.
  @override
  Future<void> upsert(model.RCard rCard) async {
    await _database.transaction(() async {
      final existing = await (_database.select(
        _database.receivedRCards,
      )..where((t) => t.subjectDid.equals(rCard.subjectDid))).getSingleOrNull();

      if (existing != null && existing.vcBlob == rCard.vcBlob) {
        // Content unchanged — skip write.
        return;
      }

      final nextVersion = existing == null ? 1 : existing.version + 1;

      await _database
          .into(_database.receivedRCards)
          .insertOnConflictUpdate(
            db.ReceivedRCardsCompanion(
              subjectDid: Value(rCard.subjectDid),
              vcBlob: Value(rCard.vcBlob),
              issuerDid: Value(rCard.issuerDid),
              version: Value(nextVersion),
              issuanceDate: Value(rCard.issuanceDate),
              notes: Value(rCard.notes),
              receivedAt: Value(rCard.receivedAt),
            ),
          );
    });
  }

  /// Returns a live stream of all stored R-Cards ordered by
  /// [model.RCard.receivedAt] descending.
  @override
  Stream<List<model.RCard>> watchAll() {
    return (_database.select(_database.receivedRCards)
          ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  /// Returns a snapshot of all stored R-Cards ordered by
  /// [model.RCard.receivedAt] descending.
  @override
  Future<List<model.RCard>> listAll() async {
    final rows = await (_database.select(
      _database.receivedRCards,
    )..orderBy([(t) => OrderingTerm.desc(t.receivedAt)])).get();
    return rows.map(_mapRow).toList();
  }

  /// Returns the R-Card with the matching [subjectDid], or `null`.
  @override
  Future<model.RCard?> getBySubjectDid(String subjectDid) async {
    final row = await (_database.select(
      _database.receivedRCards,
    )..where((t) => t.subjectDid.equals(subjectDid))).getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  /// Updates the notes for the R-Card identified by [subjectDid].
  @override
  Future<void> updateNotes(String subjectDid, String? notes) async {
    await (_database.update(_database.receivedRCards)
          ..where((t) => t.subjectDid.equals(subjectDid)))
        .write(db.ReceivedRCardsCompanion(notes: Value(notes)));
  }

  /// Removes the R-Card identified by [subjectDid].
  @override
  Future<void> deleteBySubjectDid(String subjectDid) async {
    await (_database.delete(
      _database.receivedRCards,
    )..where((t) => t.subjectDid.equals(subjectDid))).go();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  model.RCard _mapRow(db.RCardRow row) {
    return model.RCard(
      subjectDid: row.subjectDid,
      vcBlob: row.vcBlob,
      issuerDid: row.issuerDid,
      version: row.version,
      issuanceDate: row.issuanceDate,
      receivedAt: row.receivedAt,
      notes: row.notes,
    );
  }
}

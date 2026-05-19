import 'dart:convert';

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
  /// A canonical JSON comparison is used to detect no-op updates so that
  /// [model.RCard.version] is only incremented when the VC content
  /// actually changes.
  @override
  Future<void> upsert(model.RCard rCard) async {
    await _database.transaction(() async {
      final existing = await (_database.select(_database.receivedRCards)
            ..where((t) => t.subjectDid.equals(rCard.subjectDid)))
          .getSingleOrNull();

      final canonical = _canonical(rCard.vcBlob);

      if (existing != null && _canonical(existing.vcBlob) == canonical) {
        // Content unchanged — skip write.
        return;
      }

      final nextVersion = existing == null ? 1 : existing.version + 1;

      await _database.into(_database.receivedRCards).insertOnConflictUpdate(
            db.ReceivedRCardsCompanion(
              subjectDid: Value(rCard.subjectDid),
              vcBlob: Value(rCard.vcBlob),
              issuerDid: Value(rCard.issuerDid),
              version: Value(nextVersion),
              issuanceDate: Value(rCard.issuanceDate),
              notes: Value(rCard.notes),
              threadId: Value(rCard.threadId),
              contactChannelDid: Value(rCard.contactChannelDid),
              localChannelDid: Value(rCard.localChannelDid),
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
    final rows = await (_database.select(_database.receivedRCards)
          ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
        .get();
    return rows.map(_mapRow).toList();
  }

  /// Returns the R-Card with the matching [subjectDid], or `null`.
  @override
  Future<model.RCard?> getBySubjectDid(String subjectDid) async {
    final row = await (_database.select(_database.receivedRCards)
          ..where((t) => t.subjectDid.equals(subjectDid)))
        .getSingleOrNull();
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
    await (_database.delete(_database.receivedRCards)
          ..where((t) => t.subjectDid.equals(subjectDid)))
        .go();
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
      threadId: row.threadId,
      contactChannelDid: row.contactChannelDid,
      localChannelDid: row.localChannelDid,
    );
  }

  /// Produces canonical JSON for equality comparison.
  ///
  /// Re-encoding through [jsonDecode]/[jsonEncode] normalises whitespace so
  /// that two blobs with identical structure and key insertion order compare
  /// equal. Key-order differences between semantically equivalent VCs are not
  /// normalised; use deep-map equality if that matters.
  String _canonical(String vcBlob) {
    try {
      return jsonEncode(jsonDecode(vcBlob));
    } catch (_) {
      return vcBlob;
    }
  }
}

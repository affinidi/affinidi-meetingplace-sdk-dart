import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart'
    as model;

import 'received_r_card_database.dart' as db;

/// Repository implementation for managing [model.ReceivedRCard] entities
/// using a Drift-backed [db.ReceivedRCardDatabase].
///
/// Implements [model.ReceivedRCardRepository] — inject this into
/// `MeetingPlaceRelationshipSDK` to enable automatic local persistence of
/// every incoming R-Card.
class ReceivedRCardRepositoryDrift implements model.ReceivedRCardRepository {
  /// Creates a new repository with the given [database].
  ReceivedRCardRepositoryDrift({required db.ReceivedRCardDatabase database})
      : _database = database;

  final db.ReceivedRCardDatabase _database;

  /// Inserts or updates [rCard], keyed on [model.ReceivedRCard.subjectDid].
  ///
  /// A canonical JSON comparison is used to detect no-op updates so that
  /// [model.ReceivedRCard.version] is only incremented when the VC content
  /// actually changes.
  @override
  Future<void> upsert(model.ReceivedRCard rCard) async {
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
  /// [model.ReceivedRCard.receivedAt] descending.
  @override
  Stream<List<model.ReceivedRCard>> watchAll() {
    return (_database.select(_database.receivedRCards)
          ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  /// Returns a snapshot of all stored R-Cards ordered by
  /// [model.ReceivedRCard.receivedAt] descending.
  @override
  Future<List<model.ReceivedRCard>> listAll() async {
    final rows = await (_database.select(_database.receivedRCards)
          ..orderBy([(t) => OrderingTerm.desc(t.receivedAt)]))
        .get();
    return rows.map(_mapRow).toList();
  }

  /// Returns the R-Card with the matching [subjectDid], or `null`.
  @override
  Future<model.ReceivedRCard?> getBySubjectDid(String subjectDid) async {
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

  model.ReceivedRCard _mapRow(db.ReceivedRCardRow row) {
    return model.ReceivedRCard(
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
  /// Re-encoding through [jsonDecode]/[jsonEncode] normalises key order and
  /// whitespace so that two blobs representing identical VCs compare equal.
  String _canonical(String vcBlob) {
    try {
      return jsonEncode(jsonDecode(vcBlob));
    } catch (_) {
      return vcBlob;
    }
  }
}

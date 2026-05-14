import '../model/received_r_card.dart';

/// Repository interface for persisting and querying [ReceivedRCard] entities.
///
/// Implementations are provided by `meeting_place_drift_repository` via
/// `ReceivedRCardRepositoryDrift`, and injected into
/// `MeetingPlaceRelationshipSDK` at construction time.
abstract interface class ReceivedRCardRepository {
  /// Inserts or updates [rCard], keyed on [ReceivedRCard.subjectDid].
  ///
  /// If a record already exists with the same [ReceivedRCard.subjectDid],
  /// the call is a no-op when the VC content is unchanged.  When the VC
  /// content differs the record is replaced and
  /// [ReceivedRCard.version] is incremented.
  Future<void> upsert(ReceivedRCard rCard);

  /// Returns a live stream of all stored R-Cards, ordered by
  /// [ReceivedRCard.receivedAt] descending.
  ///
  /// Emits a new list whenever any record is added, updated, or removed.
  Stream<List<ReceivedRCard>> watchAll();

  /// Returns a snapshot of all stored R-Cards, ordered by
  /// [ReceivedRCard.receivedAt] descending.
  Future<List<ReceivedRCard>> listAll();

  /// Returns the R-Card whose [ReceivedRCard.subjectDid] matches [subjectDid],
  /// or `null` if no such record exists.
  Future<ReceivedRCard?> getBySubjectDid(String subjectDid);

  /// Updates the [ReceivedRCard.notes] field for the record identified by
  /// [subjectDid].  Pass `null` to clear the notes.
  ///
  /// Does nothing if no record with [subjectDid] exists.
  Future<void> updateNotes(String subjectDid, String? notes);

  /// Removes the R-Card identified by [subjectDid].
  ///
  /// Does nothing if no record with [subjectDid] exists.
  Future<void> deleteBySubjectDid(String subjectDid);
}

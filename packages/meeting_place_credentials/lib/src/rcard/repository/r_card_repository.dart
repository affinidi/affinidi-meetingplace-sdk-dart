import '../model/r_card.dart';

/// Repository interface for persisting and querying [RCard] entities.
///
/// Implementations are provided by `meeting_place_drift_repository` via
/// `RCardRepositoryDrift`, and injected into
/// `MeetingPlaceCredentialsSDK` at construction time.
abstract interface class RCardRepository {
  /// Inserts or updates [rCard], keyed on [RCard.subjectDid].
  ///
  /// If a record already exists with the same [RCard.subjectDid],
  /// the call is a no-op when the VC content is unchanged.  When the VC
  /// content differs the record is replaced and
  /// [RCard.version] is incremented.
  Future<void> upsert(RCard rCard);

  /// Returns a live stream of all stored R-Cards, ordered by
  /// [RCard.receivedAt] descending.
  ///
  /// Emits a new list whenever any record is added, updated, or removed.
  Stream<List<RCard>> watchAll();

  /// Returns a snapshot of all stored R-Cards, ordered by
  /// [RCard.receivedAt] descending.
  Future<List<RCard>> listAll();

  /// Returns the R-Card whose [RCard.subjectDid] matches [subjectDid],
  /// or `null` if no such record exists.
  Future<RCard?> getBySubjectDid(String subjectDid);

  /// Updates the [RCard.notes] field for the record identified by
  /// [subjectDid].  Pass `null` to clear the notes.
  ///
  /// Does nothing if no record with [subjectDid] exists.
  Future<void> updateNotes(String subjectDid, String? notes);

  /// Removes the R-Card identified by [subjectDid].
  ///
  /// Does nothing if no record with [subjectDid] exists.
  Future<void> deleteBySubjectDid(String subjectDid);
}

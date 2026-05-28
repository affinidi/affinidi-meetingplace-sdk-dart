import '../model/vrc.dart';

/// Repository contract for persisting and querying VRC records.
abstract interface class VrcRepository {
  /// Inserts or updates [vrc], keyed on [Vrc.id].
  Future<void> upsert(Vrc vrc);

  /// Returns a live stream of VRCs.
  Stream<List<Vrc>> watchAll();

  /// Returns a snapshot of all VRCs.
  Future<List<Vrc>> listAll();

  /// Returns a VRC by its identifier, or `null` if missing.
  Future<Vrc?> getById(String id);

  /// Returns VRCs where the holder DID matches [holderDid].
  Future<List<Vrc>> listByHolderDid(String holderDid);

  /// Returns the number of VRCs where the holder DID matches [holderDid].
  Future<int> countByHolderDid(String holderDid);

  /// Removes the VRC identified by [id].
  Future<void> deleteById(String id);
}

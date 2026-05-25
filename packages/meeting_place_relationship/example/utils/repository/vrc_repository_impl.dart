import 'dart:async';

import 'package:meeting_place_relationship/meeting_place_relationship.dart';

/// In-memory implementation of [VrcRepository] for use in examples.
///
/// Not suitable for production — use `VrcRepositoryDrift` from
/// `meeting_place_drift_repository` instead.
class VrcRepositoryImpl implements VrcRepository {
  final _records = <String, Vrc>{};
  final _controller = StreamController<List<Vrc>>.broadcast();

  void _emit() => _controller.add(_records.values.toList());

  @override
  Future<void> upsert(Vrc vrc) async {
    _records[vrc.id] = vrc;
    _emit();
  }

  @override
  Stream<List<Vrc>> watchAll() => _controller.stream;

  @override
  Future<List<Vrc>> listAll() async => _records.values.toList();

  @override
  Future<Vrc?> getById(String id) async => _records[id];

  @override
  Future<List<Vrc>> listByHolderDid(String holderDid) async =>
      _records.values.where((v) => v.holderDid == holderDid).toList();

  @override
  Future<int> countByHolderDid(String holderDid) async =>
      _records.values.where((v) => v.holderDid == holderDid).length;

  @override
  Future<void> deleteById(String id) async {
    _records.remove(id);
    _emit();
  }
}

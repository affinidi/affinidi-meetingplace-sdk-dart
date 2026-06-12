import 'dart:async';

import 'package:meeting_place_credentials/meeting_place_credentials.dart';

/// In-memory implementation of [RCardRepository] for use in examples.
///
/// Not suitable for production — use `RCardRepositoryDrift` from
/// `meeting_place_drift_repository` instead.
class RCardRepositoryImpl implements RCardRepository {
  final _records = <String, RCard>{};
  final _controller = StreamController<List<RCard>>.broadcast();

  List<RCard> _sorted() =>
      _records.values.toList()
        ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));

  void _emit() => _controller.add(_sorted());

  @override
  Future<void> upsert(RCard rCard) async {
    _records[rCard.subjectDid] = rCard;
    _emit();
  }

  @override
  Stream<List<RCard>> watchAll() => _controller.stream;

  @override
  Future<List<RCard>> listAll() async => _sorted();

  @override
  Future<RCard?> getBySubjectDid(String subjectDid) async =>
      _records[subjectDid];

  @override
  Future<void> updateNotes(String subjectDid, String? notes) async {
    final card = _records[subjectDid];
    if (card == null) return;
    _records[subjectDid] = RCard(
      subjectDid: card.subjectDid,
      vcBlob: card.vcBlob,
      issuerDid: card.issuerDid,
      version: card.version,
      issuanceDate: card.issuanceDate,
      receivedAt: card.receivedAt,
      notes: notes,
    );
    _emit();
  }

  @override
  Future<void> deleteBySubjectDid(String subjectDid) async {
    _records.remove(subjectDid);
    _emit();
  }
}

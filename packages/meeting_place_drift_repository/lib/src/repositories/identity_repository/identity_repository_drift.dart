import 'package:drift/drift.dart';
import 'package:meeting_place_core/meeting_place_core.dart' as model;
import 'identity_database.dart';

class IdentityRepositoryDrift implements model.IdentityRepository {
  IdentityRepositoryDrift({
    required IdentityDatabase database,
  }) : _db = database;
  final IdentityDatabase _db;
  @override
  Future<model.Identity?> getIdentityById(String id) async {
    final query = _db.select(_db.identities)..where((t) => t.id.equals(id));
    final record = await query.getSingleOrNull();
    if (record == null) return null;
    return _fromRecord(record);
  }

  @override
  Future<List<model.Identity>> listIdentities() async {
    final records = await _db.select(_db.identities).get();
    return records.map(_fromRecord).toList();
  }

  @override
  Future<model.Identity> addIdentity(model.Identity identity) async {
    await _db.into(_db.identities).insert(_toCompanion(identity));
    return identity;
  }

  @override
  Future<void> updateIdentity(model.Identity identity) async {
    await _db.update(_db.identities).replace(_toRecord(identity));
  }

  @override
  Future<void> deleteIdentity(String id) async {
    await (_db.delete(_db.identities)..where((t) => t.id.equals(id))).go();
  }

  model.Identity _fromRecord(IdentityRecord r) {
    final card = model.ContactCard(
      id: r.id,
      firstName: r.firstName,
      displayName: r.displayName,
      lastName: r.lastName,
      email: r.email,
      mobile: r.mobile,
      profilePic: r.profilePic,
      cardColor: r.cardColor,
    );
    return model.Identity(
      id: r.id,
      did: r.did,
      card: card,
      isPrimary: r.isPrimary,
    );
  }

  IdentityRecord _toRecord(model.Identity i) {
    return IdentityRecord(
      id: i.id,
      did: i.did,
      displayName: i.card.displayName,
      firstName: i.card.firstName,
      lastName: i.card.lastName,
      email: i.card.email,
      mobile: i.card.mobile,
      profilePic: i.card.profilePic,
      cardColor: i.card.cardColor,
      isPrimary: i.isPrimary,
    );
  }

  IdentitiesCompanion _toCompanion(model.Identity i) {
    return IdentitiesCompanion(
      id: Value(i.id),
      did: Value(i.did),
      displayName: Value(i.card.displayName),
      firstName: Value(i.card.firstName),
      lastName: Value(i.card.lastName),
      email: Value(i.card.email),
      mobile: Value(i.card.mobile),
      profilePic: Value(i.card.profilePic),
      cardColor: Value(i.card.cardColor),
      isPrimary: Value(i.isPrimary),
    );
  }
}

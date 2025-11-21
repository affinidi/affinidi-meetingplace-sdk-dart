import '../entity/identity.dart';

abstract interface class IdentityRepository {
  Future<Identity?> getIdentityById(String id);
  Future<List<Identity>> listIdentities();
  Future<Identity> addIdentity(Identity identity);
  Future<void> updateIdentity(Identity identity);
  Future<void> deleteIdentity(String id);
}

import 'package:uuid/uuid.dart';
import '../entity/contact_card.dart';
import '../entity/identity.dart';
import 'identity_repository.dart';

class InMemoryIdentityRepository implements IdentityRepository {
  final List<Identity> _items = [];
  @override
  Future<Identity?> getIdentityById(String id) async {
    return _items.where((e) => e.id == id).firstOrNull;
  }

  @override
  Future<List<Identity>> listIdentities() async {
    return List.unmodifiable(_items);
  }

  @override
  Future<Identity> addIdentity(Identity identity) async {
    _items.add(identity);
    return identity;
  }

  @override
  Future<void> updateIdentity(Identity identity) async {
    final index = _items.indexWhere((e) => e.id == identity.id);
    if (index != -1) {
      _items[index] = identity;
    }
  }

  @override
  Future<void> deleteIdentity(String id) async {
    _items.removeWhere((e) => e.id == id);
  }

  Identity create({
    required ContactCard card,
    bool isPrimary = false,
    required String did,
  }) {
    final id = const Uuid().v4();
    final c = ContactCard(
      id: id,
      firstName: card.firstName,
      displayName: card.displayName,
      lastName: card.lastName,
      email: card.email,
      mobile: card.mobile,
      profilePic: card.profilePic,
      cardColor: card.cardColor,
    );
    final identity = Identity(id: id, did: did, card: c, isPrimary: isPrimary);
    _items.add(identity);
    return identity;
  }
}

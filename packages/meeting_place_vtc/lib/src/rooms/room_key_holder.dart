import '../vta/vta_models.dart';

/// Trust Task types of data rooms.
abstract final class RoomTask {
  static const _spec = 'https://trusttasks.org/spec';

  /// A community's offers to the member, and renewals of rooms they are in.
  static const offersList = '$_spec/vtc/rooms/offers/list/0.4';

  /// Accepts a community's offer.
  static const offersAccept = '$_spec/vtc/rooms/offers/accept/0.1';

  /// The community's record of the member's admissions.
  static const membershipsList = '$_spec/vtc/rooms/memberships/list/0.2';

  /// Has the member's VTA complete a request as the member.
  static const act = '$_spec/rooms/keys/act/0.10';

  /// Has the member's VTA mint the KeyPackage a sealed room admits.
  static const keyPackage = '$_spec/rooms/keys/key-package/0.2';

  /// Hands the member's VTA the Welcome that joins it to a room's group.
  static const welcome = '$_spec/rooms/keys/welcome/0.1';

  /// The rooms the member's VTA holds group state for.
  static const keysList = '$_spec/rooms/keys/list/0.2';

  /// Has the member's VTA list a room's records from its host.
  static const browse = '$_spec/rooms/keys/browse/0.3';

  /// Has the member's VTA read and open one record from its host.
  static const read = '$_spec/rooms/keys/read/0.1';
}

/// A KeyPackage the member's VTA minted for one room's invitation.
class RoomKeyPackage {
  /// Creates a [RoomKeyPackage].
  const RoomKeyPackage({required this.keyPackage, required this.alreadyMinted});

  /// The KeyPackage, base64url. Public: it opens nothing.
  final String keyPackage;

  /// Whether the VTA had minted it already, for an acceptance begun
  /// elsewhere.
  final bool alreadyMinted;
}

/// A room whose group state the member's VTA holds.
class HeldRoom {
  /// Creates a [HeldRoom].
  const HeldRoom({required this.roomId, required this.member});

  /// The room.
  final String roomId;

  /// The member it is held for: the DID the room admitted.
  final String member;
}

/// The member's VTA as data rooms use it: it holds the member's room
/// credentials and keys, completes room requests as the member, and opens
/// sealed records. No room key ever reaches this client.
abstract interface class RoomKeyHolder {
  /// Has the VTA complete [unsigned], a room request or a community's room
  /// task with the member as `issuer`, signed as the member
  /// (`rooms/keys/act`). Returns the completed document, to send unaltered.
  Future<Map<String, dynamic>> actAsMember(Map<String, dynamic> unsigned);

  /// The KeyPackage for joining [roomId] against [invitation]: one the VTA
  /// holds already, or a new one (`rooms/keys/key-package`).
  Future<RoomKeyPackage> roomKeyPackage({
    required String roomId,
    required String invitation,
  });

  /// Hands the VTA [welcome] to join [roomId]'s group
  /// (`rooms/keys/welcome`). Returns the MLS epoch it joined at.
  Future<int> joinRoomGroup({
    required String roomId,
    required String invitation,
    required String welcome,
    String? ratchetTree,
  });

  /// The rooms the VTA holds group state for (`rooms/keys/list`).
  Future<List<HeldRoom>> heldRooms();

  /// The VTA's listing of [roomId]'s records at [host] (`rooms/keys/browse`).
  Future<Map<String, dynamic>> browseRoom({
    required String roomId,
    required String host,
  });

  /// The VTA's read of [key] from [roomId] at [host], opened on a sealed
  /// room (`rooms/keys/read`).
  Future<Map<String, dynamic>> readRoomRecord({
    required String roomId,
    required String host,
    required String key,
  });

  /// Stores [credential] in [contextId], in place of the stored credential
  /// [replacing] when given. Returns whether the VTA keeps it as usable.
  Future<bool> keepCredential(
    Map<String, dynamic> credential, {
    required String contextId,
    String? replacing,
  });

  /// The valid credentials the vault holds of [type] from [issuerDid] made
  /// out to [subjectDid].
  Future<List<HeldCredential>> findCredentials({
    String? type,
    String? issuerDid,
    String? subjectDid,
  });
}

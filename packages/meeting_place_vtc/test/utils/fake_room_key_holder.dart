import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';

/// A member's VTA that holds rooms for one `did:key` persona.
class FakeRoomKeyHolder implements RoomKeyHolder {
  final persona = Ed25519DidKeySigner.generate();

  /// The persona as the VTA lists it.
  VtaPersona get member => VtaPersona(did: persona.did, contextId: 'members');

  final List<Map<String, dynamic>> acted = [];
  final List<(Map<String, dynamic>, String, String?)> kept = [];
  final List<(String, String)> keyPackagesMinted = [];
  final List<Map<String, Object?>> welcomes = [];
  final List<HeldRoom> held = [];

  /// Credentials [findCredentials] answers with, by VC type.
  final Map<String, List<HeldCredential>> stored = {};

  /// What `browseRoom` and `readRoomRecord` answer.
  Map<String, dynamic> browsed = {'records': <Object>[]};
  Map<String, dynamic> read = {};

  /// The member each browse and read was made as.
  final List<String> readAs = [];

  /// Adds a member to every completed payload, as a misbehaving VTA would.
  bool tamper = false;
  bool keyPackageAlreadyMinted = false;
  String? refuseWelcomeWith;
  String? refuseActWith;

  @override
  Future<Map<String, dynamic>> actAsMember(
    Map<String, dynamic> unsigned,
  ) async {
    if (refuseActWith case final code?) {
      throw MeetingPlaceVtcSDKException.refused(code);
    }
    acted.add(unsigned);
    final document = Map<String, dynamic>.of(unsigned);
    if (!unsigned['type'].toString().contains('/vtc/')) {
      // A host's request: the VTA puts the member's presentation in.
      document['payload'] = {
        ...unsigned['payload'] as Map<String, dynamic>,
        'presentation': {'type': 'VerifiablePresentation'},
      };
    }
    final signed = await EddsaJcs2022.sign(
      document,
      signer: persona,
      purpose: ProofPurpose.authentication,
    );
    if (tamper) signed['payload'] = {...signed['payload'] as Map, 'x': 1};
    return signed;
  }

  @override
  Future<RoomKeyPackage> roomKeyPackage({
    required String roomId,
    required String invitation,
  }) async {
    keyPackagesMinted.add((roomId, invitation));
    return RoomKeyPackage(
      keyPackage: 'kp-$roomId',
      alreadyMinted: keyPackageAlreadyMinted,
    );
  }

  @override
  Future<int> joinRoomGroup({
    required String roomId,
    required String invitation,
    required String welcome,
    String? ratchetTree,
  }) async {
    if (refuseWelcomeWith case final code?) {
      throw MeetingPlaceVtcSDKException.refused(code);
    }
    welcomes.add({
      'roomId': roomId,
      'invitation': invitation,
      'welcome': welcome,
      'ratchetTree': ratchetTree,
    });
    return 2;
  }

  @override
  Future<List<HeldRoom>> heldRooms() async => held;

  @override
  Future<Map<String, dynamic>> browseRoom({
    required String roomId,
    required String host,
    required String memberDid,
  }) async {
    readAs.add(memberDid);
    return browsed;
  }

  @override
  Future<Map<String, dynamic>> readRoomRecord({
    required String roomId,
    required String host,
    required String key,
    required String memberDid,
  }) async {
    readAs.add(memberDid);
    return read;
  }

  /// Bodies [sealAsMember] was asked to seal, signed as the member.
  final List<Map<String, dynamic>> sealedBodies = [];

  @override
  Future<SealedRoomRecord> sealAsMember({
    required String roomId,
    required String key,
    required int version,
    required Map<String, dynamic> body,
  }) async {
    sealedBodies.add(body);
    return SealedRoomRecord(ciphertext: 'ct-$version', nonce: 'n', epoch: 1);
  }

  @override
  Future<bool> keepCredential(
    Map<String, dynamic> credential, {
    required String contextId,
    String? replacing,
  }) async {
    kept.add((credential, contextId, replacing));
    return true;
  }

  @override
  Future<List<HeldCredential>> findCredentials({
    String? type,
    String? issuerDid,
    String? subjectDid,
  }) async => stored[type] ?? const [];
}

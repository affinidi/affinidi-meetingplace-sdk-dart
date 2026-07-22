import 'package:meeting_place_core/meeting_place_core.dart';

/// Credentials resolved during call setup: DID manager, Matrix room id, SFU
/// URL, SFU token, and the participant-id-to-DID map.
class CallCredentials {
  const CallCredentials({
    required this.didManager,
    required this.matrixRoomId,
    required this.sfuUrl,
    required this.sfuToken,
    required this.participantIdToDid,
    required this.participantContactCardsByDid,
  });

  final DidManager didManager;
  final String matrixRoomId;
  final String sfuUrl;
  final String sfuToken;
  final Map<String, String> participantIdToDid;
  final Map<String, ContactCard> participantContactCardsByDid;
}

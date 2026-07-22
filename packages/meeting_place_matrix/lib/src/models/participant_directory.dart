import 'package:meeting_place_core/meeting_place_core.dart';

/// Participant identity and contact-card lookups resolved for a call.
class ParticipantDirectory {
  const ParticipantDirectory({
    required this.participantIdToDid,
    required this.participantContactCardsByDid,
  });

  final Map<String, String> participantIdToDid;
  final Map<String, ContactCard> participantContactCardsByDid;
}

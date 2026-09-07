import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../control_plane_protocol.dart';

/// A DIDComm plaintext message carrying an authentication challenge that
/// the recipient must sign to prove control of their DID.
class MeetingplaceAuthChallenge extends PlainTextMessage {
  /// Creates a new instance of [MeetingplaceAuthChallenge].
  MeetingplaceAuthChallenge({
    required super.id,
    required super.from,
    required super.to,
    required String challenge,
    required DateTime createdTime,
    required DateTime expiresTime,
  }) : super(
         type: Uri.parse(ControlPlaneProtocol.authChallenge.value),
         body: {'challenge': challenge},
         createdTime: createdTime,
         expiresTime: expiresTime,
       );

  /// Creates a [MeetingplaceAuthChallenge] with a freshly generated id and
  /// a creation time of now, expiring 60 seconds later.
  factory MeetingplaceAuthChallenge.create({
    required String from,
    required List<String> to,
    required String challenge,
  }) {
    final createdTime = DateTime.now().toUtc();
    return MeetingplaceAuthChallenge(
      id: const Uuid().v4(),
      from: from,
      to: to,
      challenge: challenge,
      createdTime: createdTime,
      expiresTime: createdTime.add(const Duration(seconds: 60)),
    );
  }
}

import 'package:didcomm/didcomm.dart';
import 'package:uuid/uuid.dart';

import '../control_plane_protocol.dart';

class MeetingplaceAuthChallenge extends PlainTextMessage {
  MeetingplaceAuthChallenge({
    required super.id,
    required super.from,
    required super.to,
    required String challenge,
    required DateTime createdTime,
    required DateTime expiresTime,
  }) : super(
          type: Uri.parse(ControlPlaneProtocol.meetingplaceAuthChallenge.value),
          body: {'challenge': challenge},
          createdTime: createdTime,
          expiresTime: expiresTime,
        );

  factory MeetingplaceAuthChallenge.create({
    required String from,
    required List<String> to,
    required String challenge,
  }) {
    final createdTime = DateTime.now().toUtc();
    return MeetingplaceAuthChallenge(
      id: Uuid().v4(),
      from: from,
      to: to,
      challenge: challenge,
      createdTime: createdTime,
      expiresTime: createdTime.add(const Duration(seconds: 60)),
    );
  }
}

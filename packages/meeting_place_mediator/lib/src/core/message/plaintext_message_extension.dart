import 'package:didcomm/didcomm.dart';

import '../mediator/didcomm_types.dart';

extension PlaintextMessageExtension on PlainTextMessage {
  bool get isEphermeral =>
      DidcommTypes.ephemeralTypes.contains(type.toString());

  bool get isTelemetry => DidcommTypes.telemetryTypes.contains(type.toString());
}

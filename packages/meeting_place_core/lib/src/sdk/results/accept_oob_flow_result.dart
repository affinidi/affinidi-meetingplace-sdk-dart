import '../../../meeting_place_core.dart';

class AcceptOobFlowResult {
  AcceptOobFlowResult({required this.stream, required this.channel});

  final OobStream stream;
  final Channel channel;
}

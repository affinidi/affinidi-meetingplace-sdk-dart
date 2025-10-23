import '../../../meeting_place_core.dart';

class AcceptOobFlowResult {
  AcceptOobFlowResult({
    required this.streamSubscription,
    required this.channel,
  });

  final OobStream streamSubscription;
  final Channel channel;
}

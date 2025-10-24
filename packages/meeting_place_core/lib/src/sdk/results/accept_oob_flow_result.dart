import '../../entity/channel.dart';
import '../../service/oob/oob_stream.dart';

class AcceptOobFlowResult {
  AcceptOobFlowResult({
    required this.streamSubscription,
    required this.channel,
  });

  final OobStream streamSubscription;
  final Channel channel;
}

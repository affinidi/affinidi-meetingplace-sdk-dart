import '../../../meeting_place_core.dart';
import '../../service/oob/oob_stream_data.dart';

class CreateOobFlowResult {
  CreateOobFlowResult({required this.streamSubscription, required this.oobUrl});

  final CoreSDKStreamSubscription<OobStreamData> streamSubscription;
  final Uri oobUrl;
}

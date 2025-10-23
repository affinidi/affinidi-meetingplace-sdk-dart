import '../../../meeting_place_core.dart';
import '../../service/oob/oob_stream_data.dart';

class CreateOobFlowResult {
  CreateOobFlowResult({required this.stream, required this.oobUrl});

  final MediatorStreamSubscription<OobStreamData> stream;
  final Uri oobUrl;
}

import '../../../meeting_place_core.dart';

class CreateOobFlowResult {
  CreateOobFlowResult({required this.streamSubscription, required this.oobUrl});

  final CoreSDKStreamSubscription<OobStreamData, void> streamSubscription;
  final Uri oobUrl;
}

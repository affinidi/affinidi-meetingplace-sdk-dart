import '../../service/oob/oob_stream.dart';

class CreateOobFlowResult {
  CreateOobFlowResult({required this.stream, required this.oobUrl});

  final OobStream stream;
  final Uri oobUrl;
}

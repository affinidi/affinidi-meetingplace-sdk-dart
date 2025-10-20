import 'package:ssi/ssi.dart';

import '../../core/command/command.dart';
import 'get_oob_output.dart';

class GetOobCommand implements MediatorCommand<GetOobOutput> {
  GetOobCommand({required this.oobUrl, required this.didManager});
  final Uri oobUrl;
  final DidManager didManager;
}

import '../../core/command/command.dart';
import 'get_oob_output.dart';

class GetOobCommand implements MediatorCommand<GetOobOutput> {
  GetOobCommand({required this.oobUrl});
  final Uri oobUrl;
}

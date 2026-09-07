import '../../core/command/command.dart';
import 'notify_outreach_output.dart';

class NotifyOutreachRequest
    extends DiscoveryCommand<NotifyOutreachCommandOutput> {
  NotifyOutreachRequest({required this.mnemonic, required this.senderInfo});
  final String mnemonic;
  final String senderInfo;
}

import '../../core/command/command.dart';
import 'notify_outreach_output.dart';

class NotifyOutreachCommand
    extends DiscoveryCommand<NotifyOutreachCommandOutput> {
  NotifyOutreachCommand({required this.mnemonic, required this.senderInfo});
  final String mnemonic;
  final String senderInfo;
}

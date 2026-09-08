import '../../core/command/command.dart';
import 'notify_outreach_result.dart';

class NotifyOutreachRequest extends DiscoveryCommand<NotifyOutreachResult> {
  NotifyOutreachRequest({required this.mnemonic, required this.senderInfo});
  final String mnemonic;
  final String senderInfo;
}

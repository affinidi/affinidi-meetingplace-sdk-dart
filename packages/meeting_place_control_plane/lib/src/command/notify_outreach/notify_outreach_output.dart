/// The result returned when an outreach notification is sent.
typedef NotifyOutreachResult = NotifyOutreachCommandOutput;

class NotifyOutreachCommandOutput {
  NotifyOutreachCommandOutput({required this.success});
  final bool success;
}

import 'package:didcomm/didcomm.dart';

extension AttachmentExtension on Attachment {
  String? get link => data?.links?.firstOrNull?.toString();
  bool get hasLink => link != null;
}

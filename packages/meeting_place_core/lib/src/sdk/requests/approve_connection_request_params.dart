import 'package:didcomm/didcomm.dart' show Attachment;

import '../../entity/channel.dart';

// Uses the `Params` suffix instead of `Request`: the method is named
// `approveConnectionRequest`, so a mechanical `*Request` rename would
// produce `ApproveConnectionRequestRequest`, doubling up the word
// "Request". `Params` sidesteps that.

/// Parameters for `MeetingPlaceCoreSDK.approveConnectionRequest`.
class ApproveConnectionRequestParams {
  const ApproveConnectionRequestParams({
    required this.channel,
    this.attachments,
  });

  /// DID of member requesting membership.
  final Channel channel;

  /// Optional list of attachments (e.g., R-Card credentials) to include in
  /// the connection approval message.
  final List<Attachment>? attachments;
}

import 'package:uuid/uuid.dart';

import '../entity/chat_attachment.dart';

/// A transport-agnostic message used as input to
/// `MeetingPlaceChatSDK.sendMessage`.
///
/// [CustomMessage] captures only the application-level fields that callers
/// need to supply. The SDK fills in the `from`/`to` DIDs and any
/// transport-specific envelope fields internally.
///
/// **Parameters:**
/// - [type]: The protocol message type URI
///   (e.g. `ChatProtocol.chatMessage.value`).
/// - [id]: Optional message identifier. Defaults to a generated UUID v4.
/// - [body]: Message body as a plain map.
/// - [attachments]: Optional list of [ChatAttachment]s.
class CustomMessage {
  CustomMessage({
    required this.type,
    required this.body,
    String? id,
    this.attachments,
  }) : id = id ?? const Uuid().v4();

  /// Protocol message type URI.
  final String type;

  /// Unique message identifier.
  final String id;

  /// Message body.
  final Map<String, dynamic> body;

  /// Optional attachments.
  final List<ChatAttachment>? attachments;
}

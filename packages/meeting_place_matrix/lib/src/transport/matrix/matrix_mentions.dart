import 'package:meeting_place_chat/meeting_place_chat.dart';

Map<String, dynamic> buildMatrixTextContent({
  required String text,
  List<ChatMention> mentions = const [],
}) {
  return {
    'body': text,
    'msgtype': 'm.text',
    ..._formattedBody(text, mentions),
    ..._mentionsContent(mentions),
  };
}

List<ChatMention> extractMatrixMentions(
  Map<String, dynamic> content, {
  String? text,
}) {
  final rawMentions = content['m.mentions'];
  if (rawMentions is! Map<String, dynamic>) return const [];

  final body = text ?? (content['body'] as String? ?? '');
  final mentions = <ChatMention>[];

  final mentionedUserIds = rawMentions['user_ids'];
  if (mentionedUserIds is List) {
    for (final rawUserId in mentionedUserIds) {
      if (rawUserId is! String) continue;
      final span = _findMentionSpan(body, rawUserId);
      mentions.add(
        ChatMention(
          target: rawUserId,
          start: span.$1,
          length: span.$2,
          display: _displayForTarget(rawUserId),
        ),
      );
    }
  }

  if (rawMentions['room'] == true) {
    final index = body.indexOf('@room');
    if (index < 0) return mentions;
    mentions.add(
      ChatMention(
        target: '@room',
        start: index,
        length: '@room'.length,
        display: '@room',
        isRoomMention: true,
      ),
    );
  }

  return mentions;
}

Map<String, dynamic> _formattedBody(String text, List<ChatMention> mentions) {
  if (mentions.isEmpty) return const {};
  return {
    'format': 'org.matrix.custom.html',
    'formatted_body': _buildFormattedBody(text, mentions),
  };
}

Map<String, dynamic> _mentionsContent(List<ChatMention> mentions) {
  if (mentions.isEmpty) return const {};

  final userIds = mentions
      .where((mention) => !mention.isRoomMention)
      .map((mention) => mention.target)
      .toSet()
      .toList();
  final hasRoomMention = mentions.any((mention) => mention.isRoomMention);

  return {
    'm.mentions': {
      if (userIds.isNotEmpty) 'user_ids': userIds,
      if (hasRoomMention) 'room': true,
    },
  };
}

String _buildFormattedBody(String text, List<ChatMention> mentions) {
  final sortedMentions = [...mentions]
    ..sort((a, b) => a.start.compareTo(b.start));
  final buffer = StringBuffer();
  var cursor = 0;

  for (final mention in sortedMentions) {
    final safeStart = mention.start.clamp(0, text.length);
    final safeEnd = (mention.start + mention.length).clamp(
      safeStart,
      text.length,
    );

    if (safeStart > cursor) {
      buffer.write(_escapeHtml(text.substring(cursor, safeStart)));
    }

    final fallbackLabel = safeEnd > safeStart
        ? text.substring(safeStart, safeEnd)
        : (mention.display ?? _displayForTarget(mention.target));
    final label = mention.isRoomMention ? '@room' : fallbackLabel;
    buffer.write(
      mention.isRoomMention
          ? '<a href="https://matrix.to/#/@room">${_escapeHtml(label)}</a>'
          : '<a href="https://matrix.to/#/${_escapeAttribute(mention.target)}">${_escapeHtml(label)}</a>',
    );
    cursor = safeEnd;
  }

  if (cursor < text.length) {
    buffer.write(_escapeHtml(text.substring(cursor)));
  }
  return buffer.toString();
}

(int, int) _findMentionSpan(String text, String target) {
  final directIndex = text.indexOf(target);
  if (directIndex >= 0) return (directIndex, target.length);

  final display = _displayForTarget(target);
  final displayIndex = text.indexOf(display);
  if (displayIndex >= 0) return (displayIndex, display.length);

  return (0, 0);
}

String _displayForTarget(String target) {
  if (!target.startsWith('@')) return target;
  return '@${target.substring(1).split(':').first}';
}

String _escapeHtml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');

String _escapeAttribute(String value) =>
    _escapeHtml(value).replaceAll('"', '&quot;');

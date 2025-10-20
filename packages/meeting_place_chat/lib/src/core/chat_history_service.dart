import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_chat.dart';
import '../loggers/default_chat_sdk_logger.dart';

class ChatHistoryService {
  ChatHistoryService({
    required ChatRepository chatRepository,
    ChatSDKLogger? logger,
  })  : _chatRepository = chatRepository,
        _logger = logger ??
            DefaultChatSdkLogger(className: _className, sdkName: sdkName);

  static const String _className = 'ChatHistoryService';

  final ChatRepository _chatRepository;
  final ChatSDKLogger _logger;

  Future<ChatItem> createGroupMemberJoinedGroupEventMessage({
    required String chatId,
    required String groupDid,
    required String memberDid,
    required VCard memberVCard,
  }) {
    final methodName = 'createGroupMemberJoinedGroupEventMessage';
    _logger.info(
      'Creating group member joined event message',
      name: methodName,
    );

    return _createGroupMemberEventMessage(
      type: EventMessageType.groupMemberJoinedGroup,
      chatId: chatId,
      groupDid: groupDid,
      memberDid: memberDid,
      memberVCard: memberVCard,
    );
  }

  Future<ChatItem> createAwaitingGroupMemberToJoinEventMessage({
    required String chatId,
    required String groupDid,
    required String memberDid,
    required VCard memberVCard,
  }) {
    final methodName = 'createAwaitingGroupMemberToJoinEventMessage';
    _logger.info(
      'Creating awaiting group member to join event message',
      name: methodName,
    );

    return _createGroupMemberEventMessage(
      type: EventMessageType.awaitingGroupMemberToJoin,
      chatId: chatId,
      groupDid: groupDid,
      memberDid: memberDid,
      memberVCard: memberVCard,
    );
  }

  Future<ChatItem> createGroupMemberLeftGroupEventMessage({
    required String chatId,
    required String groupDid,
    required String memberDid,
    required VCard memberVCard,
  }) {
    final methodName = 'createGroupMemberLeftGroupEventMessage';
    _logger.info('Creating group member left event message', name: methodName);

    return _createGroupMemberEventMessage(
      type: EventMessageType.groupMemberLeftGroup,
      chatId: chatId,
      groupDid: groupDid,
      memberDid: memberDid,
      memberVCard: memberVCard,
    );
  }

  Future<ChatItem> createGroupDeletedEventMessage({
    required String chatId,
    required String groupDid,
  }) async {
    final methodName = 'createGroupDeletedEventMessage';
    _logger.info('Creating group deleted event message', name: methodName);

    return _chatRepository.createMessage(
      EventMessage(
        chatId: chatId,
        messageId: const Uuid().v4(),
        senderDid: groupDid,
        eventType: EventMessageType.groupDeleted,
        isFromMe: false,
        dateCreated: DateTime.now().toUtc(),
        status: ChatItemStatus.received,
        data: {},
      ),
    );
  }

  Future<ChatItem> _createGroupMemberEventMessage({
    required EventMessageType type,
    required String chatId,
    required String groupDid,
    required String memberDid,
    required VCard memberVCard,
  }) async {
    return _chatRepository.createMessage(
      EventMessage(
        chatId: chatId,
        messageId: const Uuid().v4(),
        senderDid: groupDid,
        eventType: type,
        isFromMe: false,
        dateCreated: DateTime.now().toUtc(),
        status: ChatItemStatus.received,
        data: {'memberDid': memberDid, 'vCard': memberVCard.toJson()},
      ),
    );
  }
}

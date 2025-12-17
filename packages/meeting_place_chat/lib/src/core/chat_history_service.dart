import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../meeting_place_chat.dart';
import '../constants/sdk_constants.dart';
import '../loggers/default_meeting_place_chat_sdk_logger.dart';

class ChatHistoryService {
  ChatHistoryService({
    required ChatRepository chatRepository,
    MeetingPlaceChatSDKLogger? logger,
  })  : _chatRepository = chatRepository,
        _logger = logger ??
            DefaultMeetingPlaceChatSDKLogger(
                className: _className, sdkName: sdkName);

  static const String _className = 'ChatHistoryService';

  final ChatRepository _chatRepository;
  final MeetingPlaceChatSDKLogger _logger;

  Future<ChatItem> createGroupMemberJoinedGroupEventMessage({
    required String chatId,
    required String groupDid,
    required String memberDid,
    required ContactCard memberCard,
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
      memberCard: memberCard,
    );
  }

  Future<ChatItem> createAwaitingGroupMemberToJoinEventMessage({
    required String chatId,
    required String groupDid,
    required String memberDid,
    required ContactCard memberCard,
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
      memberCard: memberCard,
    );
  }

  Future<ChatItem> createGroupMemberLeftGroupEventMessage({
    required String chatId,
    required String groupDid,
    required String memberDid,
    required ContactCard memberCard,
  }) {
    final methodName = 'createGroupMemberLeftGroupEventMessage';
    _logger.info('Creating group member left event message', name: methodName);

    return _createGroupMemberEventMessage(
      type: EventMessageType.groupMemberLeftGroup,
      chatId: chatId,
      groupDid: groupDid,
      memberDid: memberDid,
      memberCard: memberCard,
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
    required ContactCard memberCard,
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
        data: {'memberDid': memberDid, 'contactCard': memberCard.toJson()},
      ),
    );
  }
}

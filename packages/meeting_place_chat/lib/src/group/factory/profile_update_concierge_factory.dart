import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:uuid/uuid.dart';

import '../../../meeting_place_chat.dart';

class ProfileUpdateConciergeFactory {
  ProfileUpdateConciergeFactory({
    required ChatRepository chatRepository,
    required MeetingPlaceChatSDKLogger logger,
  }) : _chatRepository = chatRepository,
       _logger = logger;

  static const _logkey = 'create';

  final ChatRepository _chatRepository;
  final MeetingPlaceChatSDKLogger _logger;

  Future<ConciergeMessage> create({
    required String chatId,
    required String senderDid,
    required ContactCard card,
  }) async {
    final conciergeMessage = _buildConciergeMessage(
      chatId: chatId,
      senderDid: senderDid,
      card: card,
    );

    await _chatRepository.createMessage(conciergeMessage);

    _logger.info(
      'Completed creating profile update concierge message',
      name: _logkey,
    );

    return conciergeMessage;
  }

  static ConciergeMessage _buildConciergeMessage({
    required String chatId,
    required String senderDid,
    required ContactCard card,
  }) => ConciergeMessage(
    chatId: chatId,
    messageId: const Uuid().v4(),
    senderDid: senderDid,
    isFromMe: false,
    dateCreated: DateTime.now().toUtc(),
    status: ChatItemStatus.userInput,
    conciergeType: ConciergeMessageType.permissionToUpdateProfile,
    data: {'profileDetails': card.toJson()},
  );
}

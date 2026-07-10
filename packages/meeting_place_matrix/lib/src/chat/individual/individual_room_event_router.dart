import 'package:meeting_place_chat/meeting_place_chat.dart';
import '../../transport/matrix/incoming/incoming_room_event_router.dart';
import '../../transport/matrix/incoming/profile_hash_handler.dart';
import '../../transport/matrix/incoming/profile_request_handler.dart';
import '../../transport/matrix/matrix_chat_event_type.dart';
import '../meeting_place_matrix_chat_sdk.dart';
import 'individual_contact_details_update_handler.dart';

class IndividualRoomEventRouter extends IncomingRoomEventRouter {
  IndividualRoomEventRouter({required MeetingPlaceMatrixChatSDK chatSDK})
    : super.withHandlers(
        matrixHandlers: {
          ...IncomingRoomEventRouter.buildBaseHandlers(chatSDK),
          MatrixChatEventType.profileHash: ProfileHashHandler(
            coreSDK: chatSDK.coreSDK,
            chatStream: chatSDK.chatStream,
            did: chatSDK.did,
            otherPartyDid: chatSDK.otherPartyDid,
          ).handle,
          MatrixChatEventType.profileRequest: ProfileRequestHandler(
            coreSDK: chatSDK.coreSDK,
            chatRepository: chatSDK.chatRepository,
            chatStream: chatSDK.chatStream,
            chatId: chatSDK.chatId,
            otherPartyDid: chatSDK.otherPartyDid,
          ).handle,
          ChatEventTypes.contactDetailsUpdate:
              IndividualContactDetailsUpdateHandler(
                coreSDK: chatSDK.coreSDK,
                chatStream: chatSDK.chatStream,
                otherPartyDid: chatSDK.otherPartyDid,
                getChannel: chatSDK.getChannel,
                logger: chatSDK.logger,
              ).handle,
        },
        chatHandlers: const {},
        chatStream: chatSDK.chatStream,
      );
}

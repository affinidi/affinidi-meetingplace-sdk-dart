import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import '../../meeting_place_core.dart';
import '../service/connection_service.dart';
import 'base_event_handler.dart';
import 'exceptions/empty_message_list_exception.dart';

class OutreachInvitationEventHandler extends BaseEventHandler {
  OutreachInvitationEventHandler({
    required super.wallet,
    required super.connectionOfferRepository,
    required super.channelRepository,
    required super.connectionManager,
    required super.mediatorService,
    required super.logger,
    required super.options,
    required ConnectionService connectionService,
  }) : _connectionService = connectionService;

  final ConnectionService _connectionService;

  Future<Channel?> process(InvitationOutreach event) async {
    final methodName = 'process';
    logger.info(
      'Started processing OutreachInvitation event with offerLink: ${event.offerLink}',
      name: methodName,
    );

    try {
      final connection = await findConnectionByOfferLink(event.offerLink);
      if (connection.type !=
          ConnectionOfferType.meetingPlaceOutreachInvitation) {
        logger.warning(
          'Connection offer is not of type ${ConnectionOfferType.meetingPlaceOutreachInvitation.name}',
          name: methodName,
        );
        return null;
      }

      final publishedOfferDidManager = await connectionManager
          .getDidManagerForDid(wallet, connection.publishOfferDid);

      final messages = await fetchMessagesFromMediatorWithRetry(
        didManager: publishedOfferDidManager,
        mediatorDid: connection.mediatorDid,
        messageType: MeetingPlaceProtocol.outreachInvitation,
      );

      for (final result in messages) {
        final message = result.plainTextMessage;

        logger.info(
          'Outreach invitation for mnemonic ${message.body!['mnemonic']}',
          name: methodName,
        );

        final findOfferResult = await _connectionService.findOffer(
          mnemonic: message.body!['mnemonic'],
        );

        final acceptance = await _connectionService.acceptOffer(
          wallet: wallet,
          connectionOffer: findOfferResult.$1!,
          card: connection.card,
        );

        logger.info(
          'Completed processing Outreach invitation event',
          name: methodName,
        );
        return acceptance.channel;
      }
      return null;
    } on EmptyMessageListException {
      logger.error(
        'No messages found to process for event of type ${ControlPlaneEventType.InvitationOutreach}',
        name: methodName,
      );
      return null;
    } catch (e, stackTrace) {
      logger.error(
        'Failed to process event of type ${ControlPlaneEventType.InvitationOutreach}',
        error: e,
        stackTrace: stackTrace,
        name: methodName,
      );
      rethrow;
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import '../utils/matrix.dart';
import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  final aliceSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  final notification = await aliceSDK.registerForDIDCommNotifications();
  final notificationDidDocument =
      await notification.recipientDid.getDidDocument();

  final publishOfferResult = await aliceSDK.publishOffer<GroupConnectionOffer>(
    offerName: 'Example group offer',
    offerDescription: 'Example group offer with Matrix provisioning.',
    contactCard: ContactCard(
      did: 'did:test:alice',
      type: 'individual',
      contactInfo: {},
    ),
    type: SDKConnectionOfferType.groupInvitation,
    validUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
  );

  final groupOwnerDidManager = publishOfferResult.groupOwnerDidManager;
  if (groupOwnerDidManager == null) {
    throw StateError('Missing group owner DID manager');
  }

  final groupOwnerDidDocument = await groupOwnerDidManager.getDidDocument();
  prettyPrintYellow('Group owner DID ${groupOwnerDidDocument.id}');

  final outputDirectory = Directory('.example-output')
    ..createSync(recursive: true);
  final file = File(
    '${outputDirectory.path}${Platform.pathSeparator}group_matrix.txt',
  );
  file.writeAsBytesSync(
    utf8.encode(publishOfferResult.connectionOffer.mnemonic),
  );

  prettyJsonPrintYellow(
    'Group connection offer',
    publishOfferResult.connectionOffer.toJson(),
  );

  final waitForInvitationAcceptGroup = Completer<ControlPlaneStreamEvent>();
  aliceSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.InvitationGroupAccept &&
        !waitForInvitationAcceptGroup.isCompleted) {
      waitForInvitationAcceptGroup.complete(event);
    }
  });

  final notificationStream = await aliceSDK.subscribeToMediator(
    notificationDidDocument.id,
  );
  notificationStream.stream.listen((data) async {
    prettyJsonPrintYellow('Received message', data.plainTextMessage.toJson());
    await aliceSDK.processControlPlaneEvents();
  });

  prettyPrintYellow('=== Waiting for Bob to accept the group offer...');
  final invitationAcceptedEvent = await waitForInvitationAcceptGroup.future;
  final waitingChannel = invitationAcceptedEvent.channel;
  final matrixRoomId = waitingChannel.matrixRoomId;
  if (matrixRoomId == null) {
    throw StateError('Missing Matrix room ID on group channel');
  }

  prettyJsonPrintYellow(
    'Group channel waiting for approval',
    waitingChannel.toJson(),
  );
  prettyPrintYellow('Owner Matrix user ID: ${waitingChannel.matrixUserId}');
  prettyPrintYellow(
    'Member Matrix user ID: ${waitingChannel.otherPartyMatrixUserId}',
  );
  prettyPrintYellow('Group Matrix room ID: $matrixRoomId');

  await aliceSDK.approveConnectionRequest(channel: waitingChannel);
  await sendMatrixTextMessage(
    didManager: groupOwnerDidManager,
    roomId: matrixRoomId,
    message: 'Hello from Alice via Matrix',
  );
  prettyPrintYellow('Sent Matrix text message from the group owner.');

  await notificationStream.dispose();
}

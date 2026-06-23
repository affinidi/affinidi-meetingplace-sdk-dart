import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  final vodozemacLibraryPath = getVodozemacLibraryPath();

  if (!vod.isInitialized()) {
    await vod.init(libraryPath: vodozemacLibraryPath);
  }

  final aliceSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  prettyPrintGreen('>>> Calling SDK.registerForDIDCommNotifications');
  final notification = await aliceSDK.registerForDIDCommNotifications();
  final notificationDidDocument =
      await notification.recipientDid.getDidDocument();

  prettyPrintGreen('>>> Calling SDK.publishOffer');
  final publishOfferResult = await aliceSDK.publishOffer(
    offerName: 'Media example offer',
    offerDescription: 'Example offer to demo sendMediaMessage.',
    contactCard: ContactCard(
      did: 'did:test:alice',
      type: 'individual',
      contactInfo: {},
    ),
    type: SDKConnectionOfferType.invitation,
    validUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
    transport: ChannelTransport.matrix,
  );

  final outputDirectory = Directory('.example-output')
    ..createSync(recursive: true);
  File(
    '${outputDirectory.path}${Platform.pathSeparator}storage.txt',
  ).writeAsBytesSync(utf8.encode(publishOfferResult.connectionOffer.mnemonic));

  // Listen for Bob's invitation acceptance + matrix-join readiness.
  final waitForInvitationAccept = Completer<ControlPlaneStreamEvent>();
  final waitForChannelActivity = Completer<ControlPlaneStreamEvent>();
  aliceSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.InvitationAccept) {
      waitForInvitationAccept.complete(event);
    }
    if (event.type == ControlPlaneEventType.ChannelActivity &&
        !waitForChannelActivity.isCompleted) {
      waitForChannelActivity.complete(event);
    }
  });

  final notificationStream = await aliceSDK.subscribe(
    DidCommSubscription(receiverDid: notificationDidDocument.id),
  );
  final notificationSubscription = notificationStream.stream.listen((
    IncomingMessage _,
  ) async {
    await aliceSDK.processControlPlaneEvents();
  });

  prettyPrintYellow('=== Waiting for Bob to accept connection offer...');
  final invitationEvent = await waitForInvitationAccept.future;

  prettyPrintGreen('>>> Calling SDK.approveConnectionRequest');
  await aliceSDK.approveConnectionRequest(channel: invitationEvent.channel);

  prettyPrintYellow('=== Waiting for Bob to inaugurate the channel...');
  final activityEvent = await waitForChannelActivity.future;
  final channel = activityEvent.channel;
  prettyJsonPrintYellow('Channel ready', channel.toJson());

  // For real callers, pass any file bytes here (e.g. from a file picker).
  // A small text payload keeps the example self-contained and avoids the
  // matrix SDK's image-thumbnail path, which requires valid image bytes.
  final fileBytes = Uint8List.fromList(
    utf8.encode('Hello from Alice — sent over an E2EE Matrix channel.'),
  );

  prettyPrintGreen('>>> Calling SDK.sendMediaMessage');
  final eventId = await aliceSDK.sendMediaMessage(
    channel,
    fileBytes,
    contentType: 'text/plain',
    filename: 'greeting.txt',
    caption: 'Hello from Alice!',
  );
  prettyPrintYellow('Sent media event id: $eventId');

  // Hand the event id to Bob so he can fetch and decrypt the bytes.
  File(
    '''${outputDirectory.path}${Platform.pathSeparator}media-${publishOfferResult.connectionOffer.mnemonic}.txt''',
  ).writeAsStringSync(eventId ?? '');

  await notificationSubscription.cancel();
}

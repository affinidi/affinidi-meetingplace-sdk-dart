import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_matrix/src/matrix_media_reference.dart';
import 'package:ssi/ssi.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  final vodozemacLibraryPath = getVodozemacLibraryPath();

  if (!vod.isInitialized()) {
    await vod.init(libraryPath: vodozemacLibraryPath);
  }

  final bobSDK =
      await initMatrixSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  prettyPrintGreen('>>> Calling SDK.registerForDIDCommNotifications');
  final notification = await bobSDK.registerForDIDCommNotifications();
  final notificationDidDocument =
      await notification.recipientDid.getDidDocument();

  final outputDirectory = Directory('.example-output');
  final mnemonicBytes = File(
    '${outputDirectory.path}${Platform.pathSeparator}storage.txt',
  ).readAsBytesSync();

  prettyPrintGreen('>>> Calling SDK.findOffer');
  final findOfferResult = await bobSDK.findOffer(
    mnemonic: utf8.decode(mnemonicBytes),
  );

  prettyPrintGreen('>>> Calling SDK.acceptOffer');
  final acceptOfferResult = await bobSDK.acceptOffer(
    connectionOffer: findOfferResult.connectionOffer!,
    contactCard: ContactCard(
      did: 'did:test:bob',
      type: 'individual',
      contactInfo: {},
    ),
    senderInfo: 'Bob',
  );
  prettyJsonPrintYellow(
    'Acceptance details',
    acceptOfferResult.connectionOffer.toJson(),
  );

  // OfferFinalised triggers OfferFinalisedEventHandler on Bob's side, which
  // joins the Matrix room. Until that fires, Bob is not a member of the room
  // and downloadMedia would fail with M_NOT_FOUND.
  final waitForOfferFinalised = Completer<ControlPlaneStreamEvent>();
  bobSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.OfferFinalised &&
        !waitForOfferFinalised.isCompleted) {
      waitForOfferFinalised.complete(event);
    }
  });

  final notificationStream = await bobSDK.subscribe(
    DidCommSubscription(receiverDid: notificationDidDocument.id),
  );
  final notificationSubscription =
      notificationStream.stream.listen((IncomingMessage _) async {
    await bobSDK.processControlPlaneEvents();
  });

  prettyPrintYellow('=== Waiting for Alice to approve the connection...');
  final finalisedEvent = await waitForOfferFinalised.future;
  final channel = finalisedEvent.channel;
  prettyJsonPrintYellow('Channel ready', channel.toJson());

  // Wait for Alice to publish the media event id.
  final eventIdFile = File(
    '''${outputDirectory.path}${Platform.pathSeparator}media-${utf8.decode(mnemonicBytes)}.txt''',
  );
  prettyPrintYellow('=== Waiting for Alice to send a media message...');
  while (!eventIdFile.existsSync() || eventIdFile.readAsStringSync().isEmpty) {
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  final eventId = eventIdFile.readAsStringSync();
  prettyPrintYellow('Received media event id: $eventId');

  prettyPrintGreen('>>> Calling SDK.downloadMedia');
  final bytes = await bobSDK.downloadMedia(
    channel,
    MatrixEventMediaReference(eventId),
  );

  prettyPrintYellow('Downloaded ${bytes.length} bytes');
  final outFile = File(
    '${outputDirectory.path}${Platform.pathSeparator}received.txt',
  )..writeAsBytesSync(bytes);
  prettyPrintYellow('Saved to ${outFile.path}');
  prettyPrintYellow('Contents: ${utf8.decode(bytes)}');

  await notificationSubscription.cancel();
}

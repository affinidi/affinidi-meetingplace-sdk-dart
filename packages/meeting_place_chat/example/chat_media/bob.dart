import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import '../utils/print.dart';
import '../utils/repository/chat_repository_impl.dart';
import '../utils/sdk.dart';
import '../utils/storage.dart';

// Smallest possible JPEG so the example is self-contained.
const _sampleJpegBase64 =
    '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgMCAgMDAwMEAwMEBQgFBQQEBQoHBwYIDAoMDAsK'
    'CwsNDhIQDQ4RDgsLEBYQERMUFRUVDA8XGBYUGBIUFRT/wAALCAABAAEBAREA/8QAFAABAAAAAAAA'
    'AAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==';

void main() async {
  final vodozemacLibraryPath = getVodozemacLibraryPath();

  if (!vod.isInitialized()) {
    await vod.init(libraryPath: vodozemacLibraryPath);
  }

  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  prettyPrintGreen('>>> Calling SDK.registerForDIDCommNotifications');
  final notification = await bobSDK.registerForDIDCommNotifications();
  final notificationDidDocument =
      await notification.recipientDid.getDidDocument();
  prettyPrintYellow('Notification DID ${notificationDidDocument.id}');

  final outputDirectory = Directory('.example-output');
  final mnemonicFile = File(
    '${outputDirectory.path}${Platform.pathSeparator}storage.txt',
  );
  final mnemonicBytes = mnemonicFile.readAsBytesSync();

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

  prettyPrint('Listen on new events...');
  final waitForOfferFinalised = Completer<ControlPlaneStreamEvent>();

  prettyPrintGreen('>>> Calling SDK.controlPlaneEventsStream.listen');
  bobSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.OfferFinalised) {
      waitForOfferFinalised.complete(event);
    }
  });

  prettyPrintGreen('>>> Calling SDK.subscribe');
  final notificationStream = await bobSDK.subscribe(
    DidCommSubscription(receiverDid: notificationDidDocument.id),
  );

  prettyPrintYellow('>>> Listen on notification stream');
  final notificationSubscription =
      notificationStream.stream.listen((IncomingMessage message) async {
    final didcommMessage = message as DidCommIncomingMessage;
    prettyJsonPrintYellow('Received message', didcommMessage.payload.toJson());
    await bobSDK.processControlPlaneEvents();
  });

  prettyPrintYellow('=== Waiting for Alice to approve connection request...');
  final offerFinalisedEvent = await waitForOfferFinalised.future;

  await notificationSubscription.cancel();

  prettyPrintYellow('Initializing chat...');
  final bobChatSDK = await MeetingPlaceChatSDK.initialiseFromChannel(
    offerFinalisedEvent.channel,
    coreSDK: bobSDK,
    chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
    options: MeetingPlaceChatSDKOptions(
      chatPresenceSendInterval: const Duration(seconds: 60),
    ),
  );

  await Future<void>.delayed(const Duration(seconds: 2));
  await bobChatSDK.startChatSession();

  // Build a hosted-media attachment from inline base64 bytes. The SDK
  // uploads + encrypts the bytes via the matrix transport; the mxc URI
  // and encryption keys never cross the SDK boundary.
  final attachment = ChatAttachment(
    id: const Uuid().v4(),
    description: 'Sample image from Bob',
    filename: 'hello.jpg',
    mediaType: AttachmentMediaType.imageJpeg.value,
    lastModifiedTime: DateTime.now().toUtc(),
    data: ChatAttachmentData(base64: _sampleJpegBase64),
  );

  prettyPrintGreen(
    '>>> Calling MeetingPlaceChatSDK.sendTextMessage with media attachment',
  );
  final sentMessage = await bobChatSDK.sendTextMessage(
    'Look at this picture!',
    attachments: [attachment],
  );

  prettyJsonPrintYellow('Sent message', {
    'messageId': sentMessage.messageId,
    'transportId': sentMessage.transportId,
    'status': sentMessage.status.name,
    // The persisted attachment carries display metadata only; the raw
    // bytes are gone from local state once the upload completes.
    'attachmentHasData': sentMessage.attachments.single.data != null,
  });
}

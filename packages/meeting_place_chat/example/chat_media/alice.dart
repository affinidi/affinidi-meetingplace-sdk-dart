import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_chat/meeting_place_chat.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import '../utils/print.dart';
import '../utils/repository/chat_repository_impl.dart';
import '../utils/sdk.dart';
import '../utils/storage.dart';

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
  prettyPrintYellow('Notification DID ${notificationDidDocument.id}');

  prettyPrintGreen('>>> Calling SDK.publishOffer');
  final publishOfferResult = await aliceSDK.publishOffer(
    offerName: 'Example media offer',
    offerDescription: 'Example offer for media exchange.',
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
  final mnemonicFile = File(
    '${outputDirectory.path}${Platform.pathSeparator}storage.txt',
  );
  mnemonicFile.writeAsBytesSync(
    utf8.encode(publishOfferResult.connectionOffer.mnemonic),
  );

  prettyJsonPrintYellow(
    'Connection offer',
    publishOfferResult.connectionOffer.toJson(),
  );

  prettyPrintYellow('Listen on new events...');
  final waitForInvitationAccept = Completer<ControlPlaneStreamEvent>();
  final waitForChannelActivity = Completer<ControlPlaneStreamEvent>();

  prettyPrintGreen('>>> Calling SDK.controlPlaneEventsStream.listen');
  aliceSDK.controlPlaneEventsStream.listen((event) {
    if (event.type == ControlPlaneEventType.InvitationAccept) {
      waitForInvitationAccept.complete(event);
    }

    if (event.type == ControlPlaneEventType.ChannelActivity) {
      if (!waitForChannelActivity.isCompleted) {
        waitForChannelActivity.complete(event);
      }
    }
  });

  prettyPrintGreen('>>> Calling SDK.subscribe');
  final notificationStream = await aliceSDK.subscribe(
    DidCommSubscription(receiverDid: notificationDidDocument.id),
  );

  prettyPrintYellow('>>> Listen on notification stream');
  final notificationSubscription =
      notificationStream.stream.listen((IncomingMessage message) async {
    final didcommMessage = message as DidCommIncomingMessage;
    prettyJsonPrintYellow('Received message', didcommMessage.payload.toJson());
    await aliceSDK.processControlPlaneEvents();
  });

  prettyPrintYellow('=== Waiting for Bob to accept connection offer...');
  final receivedEvent = await waitForInvitationAccept.future;

  prettyPrintGreen('>>> Calling SDK.approveConnectionRequest');
  final channel = await aliceSDK.approveConnectionRequest(
    channel: receivedEvent.channel,
  );

  prettyPrintYellow(
    '=== Waiting for Bob to send channel inauguration message...',
  );
  await waitForChannelActivity.future;
  await notificationSubscription.cancel();

  prettyPrintYellow('Initializing chat...');
  final aliceChatSDK = await MeetingPlaceChatSDK.initialiseFromChannel(
    channel,
    coreSDK: aliceSDK,
    chatRepository: ChatRepositoryImpl(storage: InMemoryStorage()),
    options: MeetingPlaceChatSDKOptions(
      chatPresenceSendInterval: const Duration(seconds: 60),
    ),
  );

  await aliceChatSDK.startChatSession();

  // Listen for media messages from Bob and download the bytes via the
  // matrix transport. The mxc URI / encryption metadata stays inside the
  // SDK; we only need the parent Message.
  final stream = await aliceChatSDK.chatStreamSubscription;
  stream?.listen((data) async {
    final item = data.chatItem;
    if (item is! Message) return;
    if (item.attachments.isEmpty) return;
    if (item.attachments.first.format != AttachmentFormat.hostedMedia.value) {
      return;
    }

    final attachment = item.attachments.single;
    prettyJsonPrintYellow(
      'Received media message',
      {
        'transportId': item.transportId,
        'caption': item.value,
        'filename': attachment.filename,
        'mediaType': attachment.mediaType,
        'byteCount': attachment.byteCount,
      },
    );

    prettyPrintGreen(
      '>>> Calling MeetingPlaceChatSDK.downloadMedia(attachment)',
    );
    final bytes = await aliceChatSDK.downloadMedia(attachment);

    final downloadedFile = File(
      '${outputDirectory.path}${Platform.pathSeparator}'
      '${attachment.filename ?? 'download.bin'}',
    );
    downloadedFile.writeAsBytesSync(bytes);
    prettyPrintYellow(
      'Wrote ${bytes.length} bytes to ${downloadedFile.path}',
    );
  });
}

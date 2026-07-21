import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:vodozemac/vodozemac.dart' as vod;

import 'utils/print.dart';
import 'utils/sdk.dart';

Future<void> main() async {
  try {
    final vodozemacLibraryPath = getVodozemacLibraryPath();
    if (!vod.isInitialized()) {
      await vod.init(libraryPath: vodozemacLibraryPath);
    }

    prettyPrintGreen('>>> Initializing MeetingPlaceMatrixSDK');
    final sdk = await initMatrixSDK(
      wallet: PersistentWallet(InMemoryKeyStore()),
    );

    prettyPrintGreen('>>> Registering DIDComm notifications');
    final notification = await sdk.registerForDIDCommNotifications();
    final notificationDidDocument =
        await notification.recipientDid.getDidDocument();

    prettyPrintGreen('>>> Publishing an invitation offer');
    final publishOfferResult = await sdk.publishOffer(
      offerName: 'Meeting Place Matrix quickstart offer',
      offerDescription: 'Minimal example offer created from example/main.dart.',
      contactCard: ContactCard(
        did: 'did:test:quickstart',
        type: 'individual',
        contactInfo: const {},
      ),
      type: SDKConnectionOfferType.invitation,
      validUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      transport: ChannelTransport.matrix,
    );

    final outputDirectory = Directory('.example-output')
      ..createSync(recursive: true);
    final mnemonicFile = File(
      '${outputDirectory.path}${Platform.pathSeparator}quickstart-offer.txt',
    );
    mnemonicFile.writeAsBytesSync(
      utf8.encode(publishOfferResult.connectionOffer.mnemonic),
    );

    prettyJsonPrintYellow(
      'Notification DID',
      {'did': notificationDidDocument.id},
    );
    prettyJsonPrintYellow(
      'Connection offer summary',
      {
        'offerName': publishOfferResult.connectionOffer.offerName,
        'offerLink': publishOfferResult.connectionOffer.offerLink,
        'publishOfferDid': publishOfferResult.connectionOffer.publishOfferDid,
        'mediatorDid': publishOfferResult.connectionOffer.mediatorDid,
        'transport': publishOfferResult.connectionOffer.transport.name,
        'expiresAt':
            publishOfferResult.connectionOffer.expiresAt?.toIso8601String(),
      },
    );

    prettyPrintYellow(
      'Wrote offer mnemonic to ${mnemonicFile.path}',
    );
    prettyPrintYellow('Next steps:');
    prettyPrintYellow(
      '1. Open the generated mnemonic file and accept it '
      'from another example actor.',
    );
    prettyPrintYellow(
      '2. For calls, run example/calls/setup_calls.dart '
      'for LiveKit-specific config.',
    );
    prettyPrintYellow(
      '3. For chat/media/group flows, run the alice.dart / bob.dart examples in those folders.',
    );
  } catch (e) {
    prettyPrintRed('Failed to run meeting_place_matrix example: $e');
    prettyPrint('');
    prettyPrintRed('Expected setup:');
    prettyPrint(
        '- optional: a local .env file in packages/meeting_place_matrix');
    prettyPrint('- required: MEDIATOR_DID');
    prettyPrint('- required: CONTROL_PLANE_DID');
    prettyPrint('- required: MATRIX_HOMESERVER');
    prettyPrint('- optional on macOS/Linux: VODOZEMAC_LIBRARY_PATH');
    prettyPrint('');
    prettyPrint(
      'Other runnable examples remain under example/calls, example/chat_media, example/group, and example/media.',
    );
    rethrow;
  }
}

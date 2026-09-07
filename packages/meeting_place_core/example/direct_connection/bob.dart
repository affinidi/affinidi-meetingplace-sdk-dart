import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

void main() async {
  final outputDirectory = Directory('.example-output');
  final directConnectionUrlBytes = File(
    '${outputDirectory.path}${Platform.pathSeparator}'
    'direct-connection-url.txt',
  ).readAsBytesSync();

  final directConnectionUri = Uri.parse(
    utf8.decode(directConnectionUrlBytes),
  );
  prettyPrintYellow('Direct connection uri: ${directConnectionUri.toString()}');
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));
  final bobWaitFor = Completer<Channel>();

  // Bob accepts the direct connection
  final acceptance = await bobSDK.acceptDirectConnection(
    AcceptDirectConnectionRequest(
      directConnectionUrl: directConnectionUri,
      contactCard: ContactCard(
        did: 'did:test:bob',
        type: 'individual',
        contactInfo: {'firstName': 'Bob'},
      ),
    ),
  );

  // Bob listens for approval
  prettyPrintYellow('Listening on direct connection stream...');
  acceptance.stream.listen((data) {
    prettyPrintYellow('Received event type: ${data.eventType.name}');
    prettyJsonPrintYellow('Received message', data.message.toJson());
    prettyJsonPrintYellow('Received channel:', data.channel.toJson());
    bobWaitFor.complete(data.channel);
  });

  acceptance.stream.timeout(
    const Duration(seconds: 300),
    () => prettyPrint('Direct connection stream timeout'),
  );

  final channel = await bobWaitFor.future;
  prettyJsonPrintYellow('Received channel', channel.toJson());

  // Close stream
  prettyPrint('Disposing direct connection stream...');
  await acceptance.stream.dispose();

  await bobSDK.sendMessage(
    DidCommOutgoingMessage(
      senderDid: channel.permanentChannelDid!,
      recipientDid: channel.otherPartyPermanentChannelDid!,
      payload: PlainTextMessage(
        id: const Uuid().v4(),
        type: Uri.parse(
          'https://affinidi.com/didcomm/protocols/meeting-place-core/1.0/example',
        ),
        from: channel.permanentChannelDid,
        to: [channel.otherPartyPermanentChannelDid!],
        body: {'hello': 'world'},
      ),
    ),
  );

  prettyPrint('Message sent to Alice');
}

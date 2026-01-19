import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:affinidi_tdk_vdip/affinidi_tdk_vdip.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../utils/print.dart';
import '../utils/sdk.dart';

// This is app specific code. SDK doesn't know about the specifics.
Future<VerifiableCredential> buildCredential({
  required String holderDid,
  required DidManager issuerDidManager,
  required Map<String, dynamic> body,
}) async {
  final vdipRequestIssuanceMessageBody =
      VdipRequestIssuanceMessageBody.fromJson(body);

  final personaDid = vdipRequestIssuanceMessageBody
      .credentialMeta?.data?['persona_did'] as String;

  final issuerDidDoc = await issuerDidManager.getDidDocument();

  final unsignedCredential = VcDataModelV1(
    context: JsonLdContext.fromJson([
      dmV1ContextUrl,
      'https://d2oeuqaac90cm.cloudfront.net/TTestMusicSubscriptionV1R0.jsonld',
    ]),
    credentialSchema: [
      CredentialSchema(
        id: Uri.parse(
          'https://d2oeuqaac90cm.cloudfront.net/TTestMusicSubscriptionV1R0.json',
        ),
        type: 'JsonSchemaValidator2018',
      ),
    ],
    id: Uri.parse(const Uuid().v4()),
    issuer: Issuer.uri(issuerDidDoc.id),
    type: {'VerifiableCredential', 'TestMusicSubscription'},
    issuanceDate: DateTime.now().toUtc(),
    credentialSubject: [
      CredentialSubject.fromJson({
        'id': holderDid,
        'personaDid': personaDid,
        'subscriptionType': 'basic',
      }),
    ],
  );

  final suite = LdVcDm1Suite();
  final issuedCredential = await suite.issue(
    unsignedData: unsignedCredential,
    proofGenerator: DataIntegrityEcdsaJcsGenerator(
      signer: await issuerDidManager.getSigner(
        issuerDidManager.assertionMethod.first,
      ),
    ),
  );

  return issuedCredential;
}

void main() async {
  final oobUrlBytes = File('./oob-url.txt').readAsBytesSync();

  final oobUri = Uri.parse(utf8.decode(oobUrlBytes));
  prettyPrintYellow('OOB uri: ${oobUri.toString()}');
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  final bobWaitFor = Completer<Channel>();
  CoreSDKStreamSubscription<MediatorMessage>? mediatorSubscription;

  // Bob accepts OOB
  final acceptance = await bobSDK.acceptOobFlow(
    oobUri,
    contactCard: ContactCard(
      did: 'did:test:bob',
      type: 'individual',
      contactInfo: {'firstName': 'Bob'},
    ),
  );

  // Bob listens for approval
  prettyPrintYellow('Listening on OOB stream...');
  acceptance.streamSubscription.listen((data) async {
    prettyPrintYellow('Received event type: ${data.eventType.name}');
    prettyJsonPrintYellow('Received message', data.message.toJson());
    prettyJsonPrintYellow('Received channel:', data.channel.toJson());

    // Complete with channel data for use outside the stream
    bobWaitFor.complete(data.channel);
  });

  acceptance.streamSubscription.timeout(
    const Duration(seconds: 300),
    () => prettyPrint('OOB stream timeout'),
  );

  final channel = await bobWaitFor.future;
  prettyJsonPrintYellow('Received channel', channel.toJson());

  // Close OOB stream only - mediator subscription stays active
  prettyPrint('Disposing OOB stream...');
  await acceptance.streamSubscription.dispose();

  final issuerDidManager =
      await bobSDK.getDidManager(channel.permanentChannelDid!);

  prettyPrintYellow('Subscribe to mediator channel...');
  mediatorSubscription = await bobSDK.subscribeToMediator(
    channel.permanentChannelDid!,
    options: MediatorStreamSubscriptionOptions(
      expectedMessageWrappingTypes: [
        MessageWrappingType.authcryptSignPlaintext,
        // authcryptPlaintext is needed to receive VDIP messages as it
        // not automatically signing them
        MessageWrappingType.authcryptPlaintext,
      ],
    ),
  );
  prettyPrintYellow('Subsribed to ${channel.permanentChannelDid!}');

  mediatorSubscription.listen((message) async {
    prettyPrintYellow(message.plainTextMessage.type.toString());
    if (!message.plainTextMessage
        .isOfType(VdipRequestIssuanceMessage.messageType.toString())) {
      return;
    }

    prettyJsonPrintYellow(
        'Received request insuance message', message.plainTextMessage.toJson());

    await bobSDK.vdip.issueCredential(
      await buildCredential(
        holderDid: message.plainTextMessage.from!, // TODO: correct?
        issuerDidManager: issuerDidManager,
        body: message.plainTextMessage.body!,
      ),
      channel: channel,
    );

    await mediatorSubscription!.dispose();
  });

  prettyPrintYellow(
      'Mediator subscription active, waiting for VDIP messages...');
  // Keep the program running to receive VDIP messages
  // Dispose mediatorSubscription when done (e.g., after receiving credential)
}

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';

Future<void> main() async {
  // ── 1. Set up Alice's wallet and DID ──────────────────────────────────
  prettyPrintGreen('>>> Setting up Alice\'s wallet and DID');

  final aliceWallet = PersistentWallet(InMemoryKeyStore());
  final aliceDidManager = DidKeyManager(
    wallet: aliceWallet,
    store: InMemoryDidStore(),
  );

  final aliceKey = await aliceWallet.generateKey(keyId: 'alice-signing-key');
  await aliceDidManager.addVerificationMethod(aliceKey.id);
  final aliceDid = (await aliceDidManager.getDidDocument()).id;

  prettyPrintYellow('Alice DID: $aliceDid');

  // ── 2. Simulate Bob's DID (in a real app Bob's DID comes from the channel)
  // Bob's DID would be obtained from the channel object after establishing
  // a connection via the Meeting Place Core SDK.
  final bobWallet = PersistentWallet(InMemoryKeyStore());
  final bobDidManager = DidKeyManager(
    wallet: bobWallet,
    store: InMemoryDidStore(),
  );
  final bobKey = await bobWallet.generateKey(keyId: 'bob-signing-key');
  await bobDidManager.addVerificationMethod(bobKey.id);
  final bobDid = (await bobDidManager.getDidDocument()).id;

  prettyPrintYellow('Bob DID  : $bobDid');

  // ── 3. Alice builds her VRC for Bob ───────────────────────────────────
  // In production this happens after Alice receives Bob's VRC via VDIP.
  // Alice issues her VRC to Bob as the second step of the handshake.
  prettyPrintGreen('>>> Alice building VRC for Bob');

  final aliceVc = await CredentialBuilder.buildVrc(
    issuerDid: aliceDid,
    subject: VrcCredentialSubject(
      from: VrcParty(did: aliceDid, name: 'Alice'),
      to: VrcParty(did: bobDid, name: 'Bob'),
    ),
    issuerDidManager: aliceDidManager,
  );

  final aliceVcBlob = jsonEncode(aliceVc.toJson());
  prettyPrintYellow('Alice VRC blob: $aliceVcBlob');

  // Write for Bob to verify
  final outputDir = Directory('.example-output')..createSync(recursive: true);
  File('${outputDir.path}/vrc-alice-blob.txt').writeAsStringSync(aliceVcBlob);

  // Also write Bob's DID so bob.dart can reference it
  File('${outputDir.path}/vrc-alice-did.txt').writeAsStringSync(aliceDid);

  prettyPrint('Written to .example-output/vrc-alice-blob.txt');
  prettyPrint('Run vrc/bob.dart to see Bob\'s side of the exchange.');
}

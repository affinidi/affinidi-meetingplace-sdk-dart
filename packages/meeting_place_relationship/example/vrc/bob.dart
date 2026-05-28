// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';

Future<void> main() async {
  // ── 1. Set up Bob's wallet and DID ────────────────────────────────────
  prettyPrintGreen('>>> Setting up Bob\'s wallet and DID');

  final bobWallet = PersistentWallet(InMemoryKeyStore());
  final bobDidManager = DidKeyManager(
    wallet: bobWallet,
    store: InMemoryDidStore(),
  );

  final bobKey = await bobWallet.generateKey(keyId: 'bob-signing-key');
  await bobDidManager.addVerificationMethod(bobKey.id);
  final bobDid = (await bobDidManager.getDidDocument()).id;

  prettyPrintYellow('Bob DID: $bobDid');

  // ── 2. Read Alice's VRC blob ──────────────────────────────────────────
  prettyPrintGreen('>>> Reading Alice\'s VRC blob');

  final blobFile = File('.example-output/vrc-alice-blob.txt');
  if (!blobFile.existsSync()) {
    prettyPrint('ERROR: .example-output/vrc-alice-blob.txt not found.');
    prettyPrint('Run vrc/alice.dart first.');
    exit(1);
  }

  final aliceVcBlob = blobFile.readAsStringSync();
  final aliceDid = File('.example-output/vrc-alice-did.txt').readAsStringSync();

  prettyPrintYellow('Alice VRC blob read (${aliceVcBlob.length} chars)');

  // ── 3. Parse Alice's VRC and inspect the relationship subject ─────────
  prettyPrintGreen('>>> Parsing Alice\'s VRC credential subject');

  // VrcCredentialSubject.fromVcBlob parses the DM v2 envelope and extracts
  // the credentialSubject. It may throw a FormatException for malformed input,
  // but does not validate the VRC type or verify the proof/signature.
  final subject = VrcCredentialSubject.fromVcBlob(aliceVcBlob);
  prettyPrintYellow('VRC from : ${subject.from.did} (${subject.from.name})');
  prettyPrintYellow('VRC to   : ${subject.to.did} (${subject.to.name})');

  // ── 4. Bob builds his VRC for Alice (step 2 of the handshake) ─────────
  // In a real exchange Bob would issue this BEFORE Alice sends hers;
  // the protocol tie-breaker is determined by channel ownership.
  prettyPrintGreen('>>> Bob building VRC for Alice (reciprocating)');

  final bobVc = await CredentialBuilder.buildVrc(
    issuerDid: bobDid,
    subject: VrcCredentialSubject(
      from: VrcParty(did: bobDid, name: 'Bob'),
      to: VrcParty(did: aliceDid, name: 'Alice'),
    ),
    issuerDidManager: bobDidManager,
  );

  final bobVcBlob = jsonEncode(bobVc.toJson());
  prettyPrintYellow('Bob VRC blob: $bobVcBlob');

  File('.example-output/vrc-bob-blob.txt').writeAsStringSync(bobVcBlob);

  prettyPrint('\nExchange complete - each party holds a mutual VRC.');
  prettyPrintYellow(
    'VRC type constant: ${VrcConstants.typeRelationshipCredential}',
  );
  prettyPrintYellow('VRC context URL  : ${VrcConstants.contextVrc}');
}

// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:ssi/ssi.dart';

import '../utils/print.dart';

Future<void> main() async {
  // ── 1. Set up an in-memory wallet and DID ──────────────────────────────
  prettyPrintGreen('>>> Setting up Alice\'s wallet and DID');

  final wallet = PersistentWallet(InMemoryKeyStore());
  final didManager = DidKeyManager(wallet: wallet, store: InMemoryDidStore());

  final key = await wallet.generateKey(keyId: 'alice-signing-key');
  final vmResult = await didManager.addVerificationMethod(key.id);
  final aliceDid = (await didManager.getDidDocument()).id;

  prettyPrintYellow('Alice DID: $aliceDid');
  prettyPrintYellow('Verification method: ${vmResult.verificationMethodId}');

  // ── 2. Build the R-Card subject ────────────────────────────────────────
  prettyPrintGreen('>>> Building Alice\'s R-Card subject');

  const subject = RCardSubject(
    firstName: 'Alice',
    lastName: 'Smith',
    email: 'alice@example.com',
    phone: '+1-555-0100',
    company: 'Affinidi',
    position: 'Engineer',
    website: 'https://alice.example.com',
  );

  prettyPrintYellow(
    'Subject: ${subject.firstName} ${subject.lastName} <${subject.email}>',
  );

  // ── 3. Build and sign the R-Card VC ───────────────────────────────────
  prettyPrintGreen('>>> Building and signing R-Card VC');

  final vc = await CredentialBuilder.buildRCard(
    issuerDid: aliceDid,
    subjectDid: aliceDid, // self-issued; in real usage this is the peer's DID
    subject: subject,
    issuerDidManager: didManager,
  );

  final vcBlob = jsonEncode(vc.toJson());
  prettyPrintYellow('Signed VC blob: $vcBlob');

  // ── 4. Export as vCard 3.0 ────────────────────────────────────────────
  prettyPrintGreen('>>> Exporting to vCard 3.0 (RFC 6350)');

  final vcard = subject.toVCard(notes: 'Met at Affinidi conference');
  prettyPrintYellow(vcard);

  // ── 5. Write blob for Bob ─────────────────────────────────────────────
  final outputDir = Directory('.example-output')..createSync(recursive: true);
  File('${outputDir.path}/r-card-blob.txt').writeAsStringSync(vcBlob);

  prettyPrint('Written VC blob to .example-output/r-card-blob.txt');
  prettyPrint('Run r_card/bob.dart to verify and parse the R-Card.');
}

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:meeting_place_relationship/meeting_place_relationship.dart';

import '../utils/print.dart';

Future<void> main() async {
  // ── 1. Read the VC blob written by Alice ──────────────────────────────
  prettyPrintGreen('>>> Reading Alice\'s R-Card VC blob');

  final blobFile = File('.example-output/r-card-blob.txt');
  if (!blobFile.existsSync()) {
    prettyPrint('ERROR: .example-output/r-card-blob.txt not found.');
    prettyPrint('Run r_card/alice.dart first.');
    exit(1);
  }

  final vcBlob = blobFile.readAsStringSync();
  prettyPrintYellow('VC blob read (${vcBlob.length} chars)');

  // ── 2. Parse and verify the R-Card subject ────────────────────────────
  prettyPrintGreen('>>> Parsing R-Card subject from VC blob');

  // RCardSubject.fromVcBlob parses and signature-verifies the credential.
  // It throws a FormatException when the blob is not a valid DM v2 R-Card.
  final subject = RCardSubject.fromVcBlob(vcBlob);

  prettyPrintYellow('Name   : ${subject.firstName} ${subject.lastName}');
  prettyPrintYellow('Email  : ${subject.email}');
  prettyPrintYellow('Phone  : ${subject.phone}');
  prettyPrintYellow('Company: ${subject.company}');
  prettyPrintYellow('Role   : ${subject.position}');
  prettyPrintYellow('Website: ${subject.website}');

  // ── 3. Export to vCard 3.0 with local notes ───────────────────────────
  prettyPrintGreen('>>> Exporting to vCard 3.0 (RFC 6350) with local notes');

  // Notes are Bob's private annotation and are never included in the VC.
  const localNotes = 'Met Alice at the Affinidi developer summit.';
  final vcard = subject.toVCard(notes: localNotes);
  prettyPrintYellow(vcard);

  // ── 4. Show credential constants used for routing ─────────────────────
  prettyPrintGreen('>>> Credential type constants');
  prettyPrintYellow('R-Card type   : ${RCardConstants.typeRCard}');
  prettyPrintYellow('R-Card context: ${RCardConstants.contextRCard}');
}

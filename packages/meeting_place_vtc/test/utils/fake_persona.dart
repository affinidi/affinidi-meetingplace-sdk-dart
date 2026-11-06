import 'dart:typed_data';

import 'package:ssi/ssi.dart';
import 'package:x25519/x25519.dart' as x25519;

/// A persona as a VTA mints it: an Ed25519 key it signs with, for
/// authentication and assertions, and a separate X25519 key it agrees keys
/// with.
///
/// Its DID is a `did:peer:2`, which names both keys and resolves offline, as
/// DIDComm resolves a sender while it unpacks. With a `mediatorDid`, its
/// document also names that mediator, as a persona's does.
class FakePersona {
  FakePersona._(this.signingSeed, this.keyAgreementKey, this.document);

  factory FakePersona({String? mediatorDid}) {
    final signing = Ed25519KeyPair.generate().$1;
    final keyAgreement = x25519.generateKeyPair();
    final did = DidPeer.getDid(
      verificationMethods: [
        signing.publicKey,
        PublicKey(
          'key-agreement',
          Uint8List.fromList(keyAgreement.publicKey),
          KeyType.x25519,
        ),
      ],
      relationships: {
        VerificationRelationship.authentication: [0],
        VerificationRelationship.keyAgreement: [1],
      },
    );
    final json = DidPeer.resolve(did).toJson();
    // did:peer:2 gives a key one purpose; a VTA's persona signs assertions
    // with its authentication key too.
    json['assertionMethod'] = json['authentication'];
    if (mediatorDid != null) {
      json['service'] = [
        {
          'id': '$did#didcomm',
          'type': 'DIDCommMessaging',
          'serviceEndpoint': {
            'uri': mediatorDid,
            'accept': ['didcomm/v2'],
          },
        },
      ];
    }
    return FakePersona._(
      signing.getSeed(),
      Uint8List.fromList(keyAgreement.privateKey),
      DidDocument.fromJson(json),
    );
  }

  /// The Ed25519 key's seed.
  final Uint8List signingSeed;

  /// The X25519 private key.
  final Uint8List keyAgreementKey;

  /// The persona's DID document.
  final DidDocument document;

  String get did => document.id;

  /// The Ed25519 public key, as the document states it.
  Uint8List get signingPublicKey =>
      Ed25519KeyPair.fromSeed(signingSeed).publicKey.bytes;
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_credentials/meeting_place_credentials.dart';
import 'package:meeting_place_credentials/src/rcard/builder/r_card_builder.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

/// Holds Ed25519 keys and signs documents with them, as a VTA's
/// `keys/sign-document` does: as the issuer, by the method its document
/// lists for the key.
class _ExternalKeys implements ExternalConnectionKeys {
  final Map<String, Ed25519KeyPair> keyPairs = {};
  final Map<String, String> verificationMethods = {};
  final List<Map<String, dynamic>> signed = [];

  /// When set, the proof is made as this DID instead of the issuer.
  String? signAs;

  /// Creates an Ed25519 signing key.
  ExternalKey createSigningKey() {
    final (keyPair, _) = Ed25519KeyPair.generate();
    final keyId = 'vta-key-${keyPairs.length}';
    keyPairs[keyId] = keyPair;
    return ExternalKey(
      keyId: keyId,
      publicKey: Uint8List.fromList(keyPair.publicKey.bytes),
    );
  }

  @override
  Future<ExternalDidKeys?> createKeys(String did) =>
      throw UnimplementedError();

  @override
  Future<ExternalDidKeys?> findKeys(String did) async => null;

  @override
  Future<Uint8List> lendSecret(String keyId) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> signDocument(
    Map<String, dynamic> document, {
    required String keyId,
  }) async {
    signed.add(document);
    expect(document.containsKey('proof'), isFalse);
    final issuer = Issuer.fromJson(document['issuer']).id.toString();
    final method = verificationMethods[keyId]!;
    final did = signAs ?? issuer;
    final proof = await DataIntegrityEddsaJcsGenerator(
      signer: DidSigner(
        did: did,
        didKeyId: '$did#${method.split('#').last}',
        keyPair: keyPairs[keyId]!,
        signatureScheme: SignatureScheme.ed25519,
      ),
    ).generate(document);
    return {...document, 'proof': proof.toJson()};
  }
}

class _Resolver implements DidResolver {
  _Resolver(this.document);

  final DidDocument document;

  @override
  Future<DidDocument> resolveDid(String did) async => document;
}

void main() {
  late _ExternalKeys externalKeys;
  late DidManager didManager;
  late DidDocument document;

  setUp(() async {
    externalKeys = _ExternalKeys();
    final device = PersistentWallet(InMemoryKeyStore());
    final wallet = ExternalKeyWallet(device, externalKeys);
    didManager = DidWebManager(
      store: InMemoryDidStore(),
      wallet: wallet,
      domain: Uri.parse('https://mpx.example/user/alice'),
    );
    final deviceKey = await device.generateKey(keyId: 'device');
    await didManager.addVerificationMethod(
      deviceKey.id,
      relationships: {
        VerificationRelationship.authentication,
        VerificationRelationship.keyAgreement,
      },
    );
    final externalKey = externalKeys.createSigningKey();
    await didManager.addVerificationMethod(
      wallet.addSigningKey(externalKey),
      relationships: {VerificationRelationship.assertionMethod},
    );
    document = await didManager.getDidDocument();
    externalKeys.verificationMethods[externalKey.keyId] =
        document.assertionMethod.single.id;
  });

  group('CredentialSigner with an external key', () {
    test('signs an R-Card where the key is held, verifiably', () async {
      final card = await RCardBuilder.build(
        issuerDid: document.id,
        subjectDid: document.id,
        subject: const RCardSubject(firstName: 'Alice'),
        issuerDidManager: didManager,
      );

      expect(
        Issuer.fromJson(externalKeys.signed.single['issuer']).id.toString(),
        document.id,
      );
      final proof = card.toJson()['proof'] as Map<String, dynamic>;
      expect(proof['cryptosuite'], 'eddsa-jcs-2022');
      expect(proof['verificationMethod'], document.assertionMethod.single.id);

      final result = await DataIntegrityEddsaJcsVerifier(
        verifierDid: document.id,
        didResolver: _Resolver(document),
      ).verify(jsonDecode(jsonEncode(card.toJson())) as Map<String, dynamic>);
      expect(result.isValid, isTrue, reason: '${result.errors}');
    });

    test('refuses a proof made as another DID', () async {
      externalKeys.signAs = 'did:web:attacker.example';

      await expectLater(
        RCardBuilder.build(
          issuerDid: document.id,
          subjectDid: document.id,
          subject: const RCardSubject(firstName: 'Alice'),
          issuerDidManager: didManager,
        ),
        throwsA(
          isA<MeetingPlaceCredentialsSDKException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceCredentialsSDKErrorCode.externalSignatureInvalid,
          ),
        ),
      );
    });
  });
}

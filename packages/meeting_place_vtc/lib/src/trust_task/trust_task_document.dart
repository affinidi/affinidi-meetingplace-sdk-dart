import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/eddsa_jcs_2022.dart';
import '../proof/trust_task_signer.dart';
import 'trust_task_time.dart';

/// A Trust Task document: a typed, signed JSON message exchanged with a VTC
/// or a VTA.
///
/// The document keeps the JSON it was built or received from, unchanged, so
/// that digests and proofs over it are computed on exactly what was on the
/// wire, including members this SDK does not model.
class TrustTaskDocument {
  TrustTaskDocument._(this._json);

  /// Builds an unsigned document.
  ///
  /// [id] defaults to a random `urn:uuid` and [issuedAt] to now, in whole
  /// seconds.
  factory TrustTaskDocument.create({
    required String type,
    required String issuer,
    required String recipient,
    required Map<String, dynamic> payload,
    String? id,
    DateTime? issuedAt,
    String? threadId,
    String? parentThreadId,
    Map<String, dynamic>? ext,
  }) {
    return TrustTaskDocument._({
      'id': id ?? 'urn:uuid:${const Uuid().v4()}',
      'type': type,
      'issuer': issuer,
      'recipient': recipient,
      'issuedAt': formatTrustTaskTime(issuedAt ?? DateTime.now()),
      'threadId': ?threadId,
      'parentThreadId': ?parentThreadId,
      'payload': payload,
      'ext': ?ext,
    });
  }

  /// Parses a received document, checking only the members every Trust Task
  /// document carries.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when a required member is missing.
  factory TrustTaskDocument.fromJson(Map<String, dynamic> json) {
    for (final member in const ['id', 'type', 'issuer']) {
      if (json[member] is! String) {
        throw MeetingPlaceVtcSDKException.invalidDocument('missing $member');
      }
    }
    if (json['payload'] is! Map<String, dynamic>) {
      throw MeetingPlaceVtcSDKException.invalidDocument('missing payload');
    }
    return TrustTaskDocument._(Map<String, dynamic>.of(json));
  }

  final Map<String, dynamic> _json;

  /// Document id, a `urn:uuid`.
  String get id => _json['id'] as String;

  /// Trust Task type URI, e.g. `https://trusttasks.org/spec/auth/oob/claim/0.1`.
  String get type => _json['type'] as String;

  /// DID of the party that signed the document.
  String get issuer => _json['issuer'] as String;

  /// DID of the intended receiver, if any.
  String? get recipient => _json['recipient'] as String?;

  /// Id of the document this one answers, if any.
  String? get threadId => _json['threadId'] as String?;

  /// Id of the request this document belongs to, if any.
  String? get parentThreadId => _json['parentThreadId'] as String?;

  /// Task-specific content.
  Map<String, dynamic> get payload => _json['payload'] as Map<String, dynamic>;

  /// Namespaced extensions, if any.
  Map<String, dynamic>? get ext => _json['ext'] as Map<String, dynamic>?;

  /// Whether the document carries an embedded proof.
  bool get isSigned => _json.containsKey('proof');

  /// Returns a copy of the document JSON exactly as built or received.
  Map<String, dynamic> toJson() => Map<String, dynamic>.of(_json);

  /// Returns a copy of this document signed by [signer] for [purpose].
  Future<TrustTaskDocument> sign(
    TrustTaskSigner signer, {
    required ProofPurpose purpose,
    DateTime? created,
  }) async {
    if (issuer != signer.did) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'issuer does not match signer',
      );
    }
    final signed = await EddsaJcs2022.sign(
      _json,
      signer: signer,
      purpose: purpose,
      created: created,
    );
    return TrustTaskDocument._(signed);
  }

  /// Verifies that the document is signed by its [issuer] for [purpose].
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the proof does not verify.
  Future<void> verify({
    required ProofPurpose purpose,
    required DidResolver resolver,
  }) {
    return EddsaJcs2022.verify(
      _json,
      purpose: purpose,
      resolver: resolver,
      expectedSigner: issuer,
    );
  }
}

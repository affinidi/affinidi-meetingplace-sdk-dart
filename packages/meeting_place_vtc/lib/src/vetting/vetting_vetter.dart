import 'package:collection/collection.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../meeting_place_vtc_sdk_exception.dart';
import '../persona/persona_did_manager.dart';
import '../persona/persona_messenger.dart';
import '../proof/digest_multibase.dart';
import '../proof/eddsa_jcs_2022.dart';
import '../sign_in/sign_in_agent.dart';
import '../trust_task/trust_task_document.dart';
import '../trust_task/trust_task_time.dart';
import '../vta/vta_client.dart';
import '../vta/vta_models.dart';
import 'vetter_checks.dart';
import 'vetter_ticket.dart';
import 'vetting_applicant.dart';
import 'vetting_card.dart';
import 'vetting_random.dart';
import 'vetting_requirements.dart';
import 'vetting_statement.dart';

/// An applicant's request the vetter accepted.
class VetterRequest {
  /// Creates a [VetterRequest].
  const VetterRequest({
    required this.requestId,
    required this.requestDocumentId,
    required this.threadId,
    required this.applicantDid,
  });

  /// Reads a request [toJson] wrote.
  factory VetterRequest.fromJson(Map<String, dynamic> json) => VetterRequest(
    requestId: json['requestId'] as String,
    requestDocumentId: json['requestDocumentId'] as String,
    threadId: json['threadId'] as String,
    applicantDid: json['applicantDid'] as String,
  );

  /// The vetter's id of the request, which the session and a decline name.
  final String requestId;

  /// The id of the applicant's `vetting/request` document.
  final String requestDocumentId;

  /// The thread of the request, which the session belongs to.
  final String threadId;

  /// The applicant's join DID, the statement's subject.
  final String applicantDid;

  /// The request as [VetterRequest.fromJson] reads it.
  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'requestDocumentId': requestDocumentId,
    'threadId': threadId,
    'applicantDid': applicantDid,
  };
}

/// What became of an applicant's `vetting/request`.
class TakenRequest {
  const TakenRequest._({this.accepted, this.ticket, this.refusal});

  /// The request, when the vetter accepted it.
  final VetterRequest? accepted;

  /// The ticket the request was accepted for, with one use fewer: keep it
  /// in place of the one before.
  final VetterTicket? ticket;

  /// The `trust-task-error` code the applicant was sent, when refused.
  final String? refusal;
}

/// A session the vetter opened for an accepted request.
class VetterSession {
  /// Creates a [VetterSession].
  const VetterSession({
    required this.request,
    required this.document,
    required this.requiredClaims,
    required this.expiresAt,
  });

  /// Reads a session [toJson] wrote.
  factory VetterSession.fromJson(Map<String, dynamic> json) => VetterSession(
    request: VetterRequest.fromJson(json['request'] as Map<String, dynamic>),
    document: TrustTaskDocument.fromJson(
      json['document'] as Map<String, dynamic>,
    ),
    requiredClaims: (json['requiredClaims'] as List).cast<String>(),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
  );

  /// The request the session is for.
  final VetterRequest request;

  /// The signed `vetting/session` document the vetter sent: the statement
  /// names it.
  final TrustTaskDocument document;

  /// The details the applicant's card must carry.
  final List<String> requiredClaims;

  /// When the session lapses.
  final DateTime expiresAt;

  /// The code the vetter and the applicant compare.
  String get matchCode => vettingMatchCode(document.id);

  /// The session as [VetterSession.fromJson] reads it.
  Map<String, dynamic> toJson() => {
    'request': request.toJson(),
    'document': document.toJson(),
    'requiredClaims': requiredClaims,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };
}

/// An applicant's vetting card the vetter checked. It holds personal data:
/// keep it in memory for the session only, and never log it.
class ReceivedVettingCard {
  const ReceivedVettingCard._({
    required this.claims,
    required this.cardDigest,
    required this.identityCommitment,
  });

  /// The details the session asked for, as the applicant states them.
  final List<VettingCardClaim> claims;

  /// The digest of the card, without its proof.
  final String cardDigest;

  /// The card's commitment to [claims].
  final String identityCommitment;
}

/// The vetter's record of a statement they issued, kept on their VTA. It
/// names the statement, enough to withdraw it, and nothing about the
/// applicant.
class IssuedVettingStatement {
  /// Creates an [IssuedVettingStatement].
  const IssuedVettingStatement({
    required this.statementId,
    required this.statementDigestMultibase,
    required this.community,
    required this.issuer,
    required this.method,
    required this.issuedAt,
    required this.validUntil,
  });

  /// Reads a record [toJson] wrote, or returns null when it is none.
  static IssuedVettingStatement? fromJson(Object? json) {
    if (json case {
      'statementId': final String statementId,
      'statementDigestMultibase': final String digest,
      'community': final String community,
      'issuer': final String issuer,
      'method': final String method,
      'issuedAt': final String issuedAt,
      'validUntil': final String validUntil,
    }) {
      final readMethod = VettingMethod.values.asNameMap()[method];
      final issued = DateTime.tryParse(issuedAt);
      final until = DateTime.tryParse(validUntil);
      if (readMethod == null || issued == null || until == null) return null;
      return IssuedVettingStatement(
        statementId: statementId,
        statementDigestMultibase: digest,
        community: community,
        issuer: issuer,
        method: readMethod,
        issuedAt: issued,
        validUntil: until,
      );
    }
    return null;
  }

  /// The statement's id.
  final String statementId;

  /// The digest of the statement as issued, which withdrawing it names.
  final String statementDigestMultibase;

  /// The community the applicant was vetted for.
  final String community;

  /// The vetter's persona, the statement's issuer.
  final String issuer;

  /// How the vetter met the applicant.
  final VettingMethod method;

  /// When the statement was issued.
  final DateTime issuedAt;

  /// Until when it holds.
  final DateTime validUntil;

  /// The record as [IssuedVettingStatement.fromJson] reads it.
  Map<String, dynamic> toJson() => {
    'statementId': statementId,
    'statementDigestMultibase': statementDigestMultibase,
    'community': community,
    'issuer': issuer,
    'method': method.name,
    'issuedAt': formatTrustTaskTime(issuedAt),
    'validUntil': formatTrustTaskTime(validUntil),
  };
}

/// The vetter's side of in-person vetting for one community, as the
/// vetter's persona: takes an applicant's `vetting/request` against the
/// vetter's tickets, shows the role card, opens a `vetting/session`, checks
/// the applicant's card, and issues a vetting statement or declines.
///
/// Documents go as the persona, signed with the keys its VTA lent, through
/// a [PersonaMessenger]. The statement is signed by the VTA itself
/// (`keys/sign-document`), and a record of it kept there (`vta/app-state`),
/// so it outlives the phone. Keeping tickets and sessions is the caller's.
/// Nothing is logged: vetting data is personal.
class VettingVetter {
  /// Creates a [VettingVetter] for [communityDid] as [persona], whose keys
  /// [personaKeys] are, on the VTA [vta].
  VettingVetter({
    required String communityDid,
    required VtaPersona persona,
    required PersonaDidManager personaKeys,
    required PersonaMessenger messenger,
    required VtaClient vta,
    required DidResolver didResolver,
    DateTime Function()? now,
  }) : _communityDid = communityDid,
       _persona = persona,
       _keys = personaKeys,
       _messenger = messenger,
       _vta = vta,
       _didResolver = didResolver,
       _now = now ?? DateTime.now;

  final String _communityDid;
  final VtaPersona _persona;
  final PersonaDidManager _keys;
  final PersonaMessenger _messenger;
  final VtaClient _vta;
  final DidResolver _didResolver;
  final DateTime Function() _now;

  /// How long a session stays open.
  static const sessionValidity = Duration(minutes: 15);

  /// How long a statement holds.
  static const statementValidity = Duration(days: 120);

  /// The documentation a vetter may rely on.
  static const documentClasses = ['passport', 'nationalId', 'driverLicence'];

  /// The `vta/app-state` namespace the vetter's records are kept in.
  static const recordNamespace = 'meeting-place';

  /// The key prefix of the records of issued statements.
  static const issuedRecordPrefix = 'vetting/issued/';

  static const _errorType = 'https://trusttasks.org/spec/trust-task-error/0.5';
  static const _hiddenVetting = 'org.openvtc.hidden-vetting';

  /// The vetter's DID, its persona.
  String get vetterDid => _persona.did;

  /// Takes the applicant's [request] against [tickets], showing [roleCard]
  /// when it is accepted, and answers it. Returns null for a request left
  /// unanswered: not for this community or not the applicant's own, or a
  /// code no live ticket has, so that guessing codes learns nothing.
  ///
  /// Refuses, with `trust-task-error/0.5`: a scanned ticket the vetter does
  /// not hold live (`invalidTicket`), hidden vetting, which this vetter
  /// does not offer (`methodUnavailable`), and any request while
  /// [roleCard] is null (`notEligible`). A ticket is spent only on
  /// acceptance.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the applicant cannot be
  /// reached.
  Future<TakenRequest?> takeRequest(
    TrustTaskDocument request, {
    required List<VetterTicket> tickets,
    required Map<String, dynamic>? roleCard,
  }) async {
    final payload = request.payload;
    final ticketJson = payload['ticket'];
    if (request.type != VettingTask.request ||
        request.recipient != vetterDid ||
        payload['community'] != _communityDid ||
        payload['joinDid'] != request.issuer ||
        ticketJson is! Map<String, dynamic>) {
      return null;
    }

    final now = _now();
    final ticket = tickets.firstWhereOrNull(
      (ticket) =>
          ticket.community == _communityDid && ticket.admits(ticketJson, now),
    );
    if (ticket == null) {
      if (ticketJson.containsKey('code')) return null;
      return _refuse(request, 'vetting/request:invalidTicket');
    }
    if (request.ext?.containsKey(_hiddenVetting) ?? false) {
      return _refuse(request, 'vetting/request:methodUnavailable');
    }
    if (roleCard == null) {
      return _refuse(request, 'vetting/request:notEligible');
    }

    final accepted = VetterRequest(
      requestId: const Uuid().v4(),
      requestDocumentId: request.id,
      threadId: request.threadId ?? request.id,
      applicantDid: request.issuer,
    );
    await _send(
      VettingTask.requestResponse,
      to: accepted.applicantDid,
      threadId: accepted.threadId,
      payload: {
        'requestId': accepted.requestId,
        'eligibilityVp': await vetterEligibilityPresentation(
          roleCard: roleCard,
          nonce: request.id,
          domain: accepted.applicantDid,
          signer: _keys.signer,
        ),
        'acceptsDocumentation': documentClasses,
      },
    );
    return TakenRequest._(accepted: accepted, ticket: ticket.spent());
  }

  /// Opens an in-person session for [request], asking for the details
  /// [requiredClaims], and sends it to the applicant. Both sides then show
  /// [VetterSession.matchCode].
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the applicant cannot be
  /// reached.
  Future<VetterSession> openSession(
    VetterRequest request, {
    required List<String> requiredClaims,
  }) async {
    final expiresAt = _now().toUtc().add(sessionValidity);
    final document = await _send(
      VettingTask.session,
      to: request.applicantDid,
      parentThreadId: request.threadId,
      payload: {
        'requestId': request.requestId,
        'challenge': randomBase64Url(32),
        'domain': _communityDid,
        'method': VettingMethod.inPerson.name,
        'requiredClaims': requiredClaims,
        'expiresAt': formatTrustTaskTime(expiresAt),
      },
    );
    return VetterSession(
      request: request,
      document: document,
      requiredClaims: requiredClaims,
      // As sent: whole seconds.
      expiresAt: DateTime.parse(formatTrustTaskTime(expiresAt)),
    );
  }

  /// Whether [document] is the applicant of [request] ending it with a
  /// `vetting/decline`.
  bool isDeclinedBy(TrustTaskDocument document, VetterRequest request) =>
      document.type == VettingTask.decline &&
      document.issuer == request.applicantDid &&
      document.payload['requestId'] == request.requestId;

  /// Reads and checks the card the applicant sent in [answer] to [session].
  /// Returns null when [answer] is not that applicant's answer to it.
  ///
  /// Throws [VettingCardException] when the card is not bound to the
  /// session, not valid now, not the applicant's, lacks a required detail,
  /// or does not commit to its details.
  Future<ReceivedVettingCard?> receiveCard(
    TrustTaskDocument answer, {
    required VetterSession session,
  }) async {
    final card = answer.payload['card'];
    if (answer.type != VettingTask.sessionResponse ||
        answer.issuer != session.request.applicantDid ||
        answer.threadId != session.document.id) {
      return null;
    }
    if (card is! Map<String, dynamic>) {
      throw const VettingCardException(VettingCardRefusal.shape);
    }
    final claims = await verifyVettingCard(
      card,
      applicantDid: session.request.applicantDid,
      vetterDid: vetterDid,
      communityDid: _communityDid,
      challenge: '${session.document.payload['challenge']}',
      sessionExpiresAt: session.expiresAt,
      requiredClaims: session.requiredClaims,
      didResolver: _didResolver,
      now: _now(),
    );
    return ReceivedVettingCard._(
      claims: claims,
      cardDigest: vettingDigest(card),
      identityCommitment: card['identityCommitment'] as String,
    );
  }

  /// Issues the applicant of [session] a vetting statement over [card]: the
  /// vetter met them in person, checked the card's details against
  /// [documentClasses], and knows them as [relationship]. The VTA signs it
  /// as the persona. Sends it to the applicant, keeps a record of it on the
  /// VTA, and returns the record.
  ///
  /// Only once the vetter confirmed, with the applicant present, that both
  /// match codes match ([matchConfirmed]). Throws [StateError] before that,
  /// [ArgumentError] for documentation not in [VettingVetter.documentClasses],
  /// and [MeetingPlaceVtcSDKException] when the VTA will not sign or keep
  /// it, or the applicant cannot be reached.
  Future<IssuedVettingStatement> issue(
    VetterSession session, {
    required ReceivedVettingCard card,
    required bool matchConfirmed,
    required List<String> documentClasses,
    VettingRelationship relationship = VettingRelationship.none,
  }) async {
    if (!matchConfirmed) {
      throw StateError('the match code was not confirmed');
    }
    if (documentClasses.isEmpty ||
        documentClasses.any(
          (documentClass) =>
              !VettingVetter.documentClasses.contains(documentClass),
        )) {
      throw ArgumentError.value(documentClasses, 'documentClasses');
    }

    final validFrom = _now().toUtc();
    final validUntil = validFrom.add(statementValidity);
    final unsigned = {
      '@context': [
        'https://www.w3.org/ns/credentials/v2',
        'https://registry.trustoverip.org/dtg/context/v1',
      ],
      'type': ['VerifiableCredential', 'DTGCredential', VettingStatement.type],
      'id': 'urn:uuid:${const Uuid().v4()}',
      'issuer': vetterDid,
      'issuerScope': 'directed',
      'validFrom': formatTrustTaskTime(validFrom),
      'validUntil': formatTrustTaskTime(validUntil),
      'taskContext': session.document.id,
      'taskDigestMultibase': vettingDigest(session.document.toJson()),
      'credentialSubject': {
        'id': session.request.applicantDid,
        'predicate': VettingStatement.predicate,
        'object': {
          'value': {
            'community': _communityDid,
            'method': VettingMethod.inPerson.name,
            'documentClasses': documentClasses,
            'claimsVerified': [for (final claim in card.claims) claim.type],
            'livenessConfirmed': true,
            'identityCommitment': card.identityCommitment,
            'cardDigestMultibase': card.cardDigest,
            'declaredRelationship': relationship.name,
          },
        },
      },
    };
    final statement = await _signedByVta(unsigned);

    await _send(
      VettingTask.issue,
      to: session.request.applicantDid,
      threadId: session.document.id,
      payload: {
        'credential_response': {'credential': statement},
      },
    );

    final record = IssuedVettingStatement(
      statementId: unsigned['id'] as String,
      statementDigestMultibase: digestMultibase(statement),
      community: _communityDid,
      issuer: vetterDid,
      method: VettingMethod.inPerson,
      issuedAt: validFrom,
      validUntil: validUntil,
    );
    await _vta.putAppState(
      contextId: _persona.contextId,
      namespace: recordNamespace,
      key: '$issuedRecordPrefix${record.statementId}',
      value: record.toJson(),
      expectedVersion: 0,
    );
    return record;
  }

  /// Tells the applicant of [request] the vetter will not vouch for them,
  /// with a [code] such as `couldNotVerify` and the vetter's [message].
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the applicant cannot be
  /// reached.
  Future<void> decline(
    VetterRequest request, {
    String? code,
    String? message,
  }) => _send(
    VettingTask.decline,
    to: request.applicantDid,
    parentThreadId: request.threadId,
    payload: {
      'requestId': request.requestId,
      'code': ?code,
      'message': ?message,
    },
  );

  /// The records of the statements the vetter issued for the community, as
  /// the VTA keeps them, newest first.
  Future<List<IssuedVettingStatement>> issuedStatements() async {
    final records = await _vta.listAppState(
      contextId: _persona.contextId,
      namespace: recordNamespace,
      prefix: issuedRecordPrefix,
    );
    return [
      for (final record in records)
        if (IssuedVettingStatement.fromJson(record.value) case final issued?
            when issued.community == _communityDid)
          issued,
    ]..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
  }

  /// [unsigned] with the proof the VTA made as the persona, after checking
  /// it signed exactly that, as the persona, and that it reads as a
  /// statement.
  Future<Map<String, dynamic>> _signedByVta(
    Map<String, dynamic> unsigned,
  ) async {
    final PersonaSigningAgent signer = _vta;
    final signed = await signer.signDocument(
      keyId: _persona.signingKeyId,
      document: unsigned,
      purpose: ProofPurpose.assertionMethod.value,
    );
    final withoutProof = Map<String, dynamic>.of(signed)..remove('proof');
    if (!const DeepCollectionEquality().equals(withoutProof, unsigned) ||
        VettingStatement.read(signed) == null) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'the VTA changed the statement it signed',
      );
    }
    await EddsaJcs2022.verify(
      signed,
      purpose: ProofPurpose.assertionMethod,
      resolver: _didResolver,
      expectedSigner: vetterDid,
    );
    return signed;
  }

  Future<TakenRequest> _refuse(TrustTaskDocument request, String code) async {
    await _send(
      _errorType,
      to: request.issuer,
      threadId: request.threadId ?? request.id,
      payload: {
        'code': code,
        'retryable': false,
        'inResponseTo': {'typeUri': request.type, 'id': request.id},
      },
    );
    return TakenRequest._(refusal: code);
  }

  /// Sends a [type] document with [payload] to [to] as the persona, and
  /// returns it as sent.
  Future<TrustTaskDocument> _send(
    String type, {
    required String to,
    required Map<String, dynamic> payload,
    String? threadId,
    String? parentThreadId,
  }) async {
    final document = await TrustTaskDocument.create(
      type: type,
      issuer: vetterDid,
      recipient: to,
      threadId: threadId,
      parentThreadId: parentThreadId,
      payload: payload,
    ).sign(_keys.signer, purpose: ProofPurpose.authentication);
    await _messenger.send(document);
    return document;
  }
}

import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../credentials/credential_fields.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../persona/persona_did_manager.dart';
import '../persona/persona_inbox.dart';
import '../persona/persona_messenger.dart';
import '../proof/eddsa_jcs_2022.dart';
import '../status/status_list_client.dart';
import '../trust_task/trust_task_document.dart';
import 'vetter_role_card.dart';
import 'vetting_card.dart';
import 'vetting_requirements.dart';
import 'vetting_statement.dart';
import 'vetting_ticket.dart';

/// The `vetting` Trust Task types an applicant and a vetter exchange.
abstract final class VettingTask {
  static const _base = 'https://trusttasks.org/spec/vetting';

  /// Asks a vetter to vet the applicant.
  static const request = '$_base/request/0.1';

  /// The vetter's acceptance of a request.
  static const requestResponse = '$request#response';

  /// The vetter opens a session; the applicant answers with a card.
  static const session = '$_base/session/0.1';

  /// The applicant's card, in answer to a session.
  static const sessionResponse = '$session#response';

  /// The vetter declines to vouch.
  static const decline = '$_base/decline/0.1';

  /// The vetter's statement, issued to the applicant.
  static const issue = credentialIssueTask;

  /// A refusal, as vetters send it now and as Keyring vetters sent it
  /// before.
  static const errors = {
    'https://trusttasks.org/spec/trust-task-error/0.5',
    'https://trusttasks.org/spec/trust-task-error/0.3',
  };

  /// Everything a vetter sends an applicant.
  static const fromVetter = {
    requestResponse,
    session,
    decline,
    issue,
    ...errors,
  };

  /// Everything an applicant sends a vetter. An applicant ends a session
  /// with a decline too, as Keyring's do.
  static const toVetter = {request, sessionResponse, decline};
}

/// Why a vetting step could not go ahead, for a screen to word.
enum VettingFailure {
  /// The ticket is for another community.
  otherCommunity,

  /// The vetter does not accept the ticket, e.g. it expired or was used.
  invalidTicket,

  /// The vetter cannot vet now, e.g. they are at capacity.
  unavailable,

  /// The vetter cannot show they hold the community's vetter role.
  notVetter,

  /// The community has withdrawn the vetter's role.
  vetterRevoked,

  /// The vetter refused for another reason.
  refused,

  /// The session has lapsed.
  sessionExpired,

  /// A message from the vetter failed a check, so it was not believed.
  badAnswer,
}

/// A vetting step that could not complete.
class VettingException implements Exception {
  /// Creates a [VettingException].
  const VettingException(this.failure, {this.detail});

  /// Why the step failed.
  final VettingFailure failure;

  /// Which check failed, for diagnostics. Never a claim or a document.
  final String? detail;

  @override
  String toString() =>
      'VettingException(${failure.name}${detail == null ? '' : ': $detail'})';
}

/// A vetter who accepted the applicant's request and showed their role.
class AcceptedVetter {
  /// Creates an [AcceptedVetter].
  const AcceptedVetter({
    required this.vetterDid,
    required this.requestId,
    required this.roleValidUntil,
    this.sessionHint,
  });

  /// The vetter's DID.
  final String vetterDid;

  /// The vetter's id of the request, which their session names.
  final String requestId;

  /// Until when the community grants the vetter their role.
  final DateTime roleValidUntil;

  /// What the vetter says about the session to come, in their words.
  final String? sessionHint;
}

/// A session a vetter opened, checked against the request it answers.
class VettingSession {
  const VettingSession._({
    required this.document,
    required this.method,
    required this.requiredClaims,
    required this.optionalClaims,
    required this.expiresAt,
  });

  /// The vetter's signed session document, exactly as received: the
  /// statement names it by its digest.
  final TrustTaskDocument document;

  /// How the session is conducted.
  final VettingMethod method;

  /// The claims the card must carry.
  final List<String> requiredClaims;

  /// The claims the applicant may add.
  final List<String> optionalClaims;

  /// When the session lapses.
  final DateTime expiresAt;

  /// The code the applicant and the vetter compare.
  String get matchCode => vettingMatchCode(document.id);
}

/// What the applicant sent in a session, to check the statement against.
class SentCard {
  /// Creates a [SentCard].
  const SentCard({required this.cardDigest, required this.identityCommitment});

  /// The digest of the card, without its proof.
  final String cardDigest;

  /// The card's commitment to the applicant's identity claims.
  final String identityCommitment;
}

/// A vetter's refusal to vouch after a session (`vetting/decline`).
class VettingDecline {
  /// Creates a [VettingDecline].
  const VettingDecline({this.code, this.message});

  /// Why, e.g. `couldNotVerify` or `notComfortable`, if the vetter says.
  final String? code;

  /// The vetter's own words, if any.
  final String? message;
}

/// Runs the applicant's side of in-person vetting against one vetter
/// (`vetting/request|session|decline/0.1`): asks, checks the vetter's role,
/// checks the session, sends the card and checks the statement.
///
/// Documents go as the persona, signed with the keys its VTA lent, through
/// a [PersonaMessenger]; answers arrive in the persona's [PersonaInbox].
/// Keeping what was sent and received is the caller's. Nothing is logged:
/// vetting data is personal.
class VettingApplicant {
  /// Creates a [VettingApplicant].
  VettingApplicant({
    required PersonaDidManager persona,
    required PersonaMessenger messenger,
    required DidResolver didResolver,
    required StatusListClient statusList,
    DateTime Function()? now,
  }) : _persona = persona,
       _messenger = messenger,
       _didResolver = didResolver,
       _statusList = statusList,
       _now = now ?? DateTime.now;

  final PersonaDidManager _persona;
  final PersonaMessenger _messenger;
  final DidResolver _didResolver;
  final StatusListClient _statusList;
  final DateTime Function() _now;

  /// How far apart the applicant's and a vetter's clocks may be.
  static const clockSkew = Duration(seconds: 60);

  /// The persona's DID, the applicant's join DID.
  String get joinDid => _persona.did;

  /// Asks the vetter [ticket] names to vet the applicant for
  /// [communityDid], and returns the request sent: the vetter's answers
  /// name it.
  ///
  /// Throws [VettingException] with [VettingFailure.otherCommunity] for a
  /// ticket of another community, before anything is sent, and
  /// [MeetingPlaceVtcSDKException] when the vetter cannot be reached.
  Future<TrustTaskDocument> request({
    required String communityDid,
    required VettingTicket ticket,
    String? requirementsDigest,
  }) async {
    if (ticket.community != communityDid) {
      throw const VettingException(VettingFailure.otherCommunity);
    }
    final request = await TrustTaskDocument.create(
      type: VettingTask.request,
      issuer: joinDid,
      recipient: ticket.vetter,
      payload: {
        'community': communityDid,
        'joinDid': joinDid,
        'ticket': ticket.toJson(),
        'requirementsDigest': ?requirementsDigest,
      },
    ).sign(_persona.signer, purpose: ProofPurpose.authentication);
    await _messenger.send(request);
    return request;
  }

  /// Ends being vetted by [vetter] with a `vetting/decline`, e.g. because
  /// the match codes differ or the applicant will not share their details:
  /// the vetter's session for the request ends. [parentThreadId] is the
  /// request's id, as the session names it.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the vetter cannot be
  /// reached.
  Future<void> decline({
    required AcceptedVetter vetter,
    String? parentThreadId,
    String? code,
    String? message,
  }) async {
    final decline = await TrustTaskDocument.create(
      type: VettingTask.decline,
      issuer: joinDid,
      recipient: vetter.vetterDid,
      parentThreadId: parentThreadId,
      payload: {
        'requestId': vetter.requestId,
        'code': ?code,
        'message': ?message,
      },
    ).sign(_persona.signer, purpose: ProofPurpose.authentication);
    await _messenger.send(decline);
  }

  /// Reads the vetter's answer to [request]: an acceptance whose
  /// presentation shows the vetter holds [vetterRole] in [communityDid],
  /// granted by the community, valid now and not revoked.
  ///
  /// Throws [VettingException] when the vetter refused, cannot show the
  /// role, or the answer fails a check.
  Future<AcceptedVetter> accepted(
    TrustTaskDocument answer, {
    required TrustTaskDocument request,
    required String communityDid,
    required String vetterRole,
  }) async {
    final vetterDid = request.recipient!;
    _checkFrom(answer, vetterDid, thread: request.id);
    if (VettingTask.errors.contains(answer.type)) {
      throw VettingException(
        _refusal(answer.payload['code']),
        detail: '${answer.payload['code']}',
      );
    }
    final requestId = answer.payload['requestId'];
    if (answer.type != VettingTask.requestResponse || requestId is! String) {
      throw const VettingException(
        VettingFailure.badAnswer,
        detail: 'no acceptance',
      );
    }
    final roleCard = await _eligibility(
      answer.payload['eligibilityVp'],
      vetterDid: vetterDid,
      nonce: request.id,
      communityDid: communityDid,
      role: vetterRole,
    );
    final status = await _statusList.check(roleCard);
    if (status.state == CredentialStatusState.revoked) {
      throw const VettingException(VettingFailure.vetterRevoked);
    }
    final hint = answer.payload['sessionHint'];
    return AcceptedVetter(
      vetterDid: vetterDid,
      requestId: requestId,
      roleValidUntil: DateTime.parse('${roleCard['validUntil']}'),
      sessionHint: hint is String ? hint : null,
    );
  }

  /// Reads a session [vetter] opened for the request they accepted.
  ///
  /// Throws [VettingException] with [VettingFailure.sessionExpired] for a
  /// lapsed session and [VettingFailure.badAnswer] for one that fails a
  /// check.
  VettingSession openSession(
    TrustTaskDocument session, {
    required AcceptedVetter vetter,
    required String communityDid,
  }) {
    _checkFrom(session, vetter.vetterDid);
    final payload = session.payload;
    final expiresAt = DateTime.tryParse('${payload['expiresAt']}');
    final method = VettingMethod.values.asNameMap()[payload['method']];
    final required = payload['requiredClaims'];
    final challenge = payload['challenge'];
    if (session.type != VettingTask.session ||
        payload['requestId'] != vetter.requestId ||
        payload['domain'] != communityDid ||
        challenge is! String ||
        !_challenge.hasMatch(challenge) ||
        method == null ||
        required is! List ||
        expiresAt == null) {
      throw const VettingException(VettingFailure.badAnswer, detail: 'session');
    }
    if (!expiresAt.isAfter(_now())) {
      throw const VettingException(VettingFailure.sessionExpired);
    }
    final optional = payload['optionalClaims'];
    return VettingSession._(
      document: session,
      method: method,
      requiredClaims: required.whereType<String>().toList(),
      optionalClaims: optional is List
          ? optional.whereType<String>().toList()
          : const [],
      expiresAt: expiresAt,
    );
  }

  /// Sends the vetter a card with [claims], the details the applicant
  /// approved, signed as the persona, and returns what the statement must
  /// name. [salt] is the application's, the same for every card.
  ///
  /// Only send it once the applicant has confirmed the match code. Throws
  /// [VettingException] with [VettingFailure.sessionExpired] when the
  /// session has lapsed, and [ArgumentError] when a required claim is
  /// missing.
  Future<SentCard> sendCard(
    VettingSession session, {
    required List<VettingCardClaim> claims,
    required String salt,
    required String parentThreadId,
  }) async {
    final now = _now().toUtc();
    final left = session.expiresAt.difference(now);
    if (left <= Duration.zero) {
      throw const VettingException(VettingFailure.sessionExpired);
    }
    final document = session.document;
    final card = await EddsaJcs2022.sign(
      unsignedVettingCard(
        id: 'urn:uuid:${const Uuid().v4()}',
        publisher: joinDid,
        audience: document.issuer,
        community: '${document.payload['domain']}',
        challenge: '${document.payload['challenge']}',
        domain: '${document.payload['domain']}',
        issuedAt: now,
        validity: left < maxVettingCardValidity ? left : maxVettingCardValidity,
        claims: claims,
        identityTypes: session.requiredClaims,
        salt: salt,
      ),
      signer: _persona.signer,
      purpose: ProofPurpose.assertionMethod,
    );
    final answer = await TrustTaskDocument.create(
      type: VettingTask.sessionResponse,
      issuer: joinDid,
      recipient: document.issuer,
      threadId: document.id,
      parentThreadId: parentThreadId,
      payload: {'card': card},
    ).sign(_persona.signer, purpose: ProofPurpose.authentication);
    await _messenger.send(answer);
    return SentCard(
      cardDigest: vettingDigest(card),
      identityCommitment: card['identityCommitment'] as String,
    );
  }

  /// Reads the statement [issue] carries: issued by the vetter of
  /// [session], about the applicant, for [communityDid], made in that
  /// session over the card [sent], valid now and signed by the vetter.
  ///
  /// Throws [VettingException] with [VettingFailure.badAnswer] when it is
  /// not.
  Future<VettingStatement> receiveStatement(
    TrustTaskDocument issue, {
    required VettingSession session,
    required SentCard sent,
    required String communityDid,
  }) async {
    final vetterDid = session.document.issuer;
    _checkFrom(issue, vetterDid, thread: session.document.id);
    final credential = switch (issue.payload['credential_response']) {
      {'credential': final Map<String, dynamic> credential} => credential,
      _ => null,
    };
    final statement = credential == null
        ? null
        : VettingStatement.read(credential);
    final now = _now();
    if (issue.type != VettingTask.issue ||
        statement == null ||
        statement.vetterDid != vetterDid ||
        statement.applicantDid != joinDid ||
        statement.community != communityDid ||
        statement.taskContext != session.document.id ||
        statement.taskDigestMultibase !=
            vettingDigest(session.document.toJson()) ||
        statement.cardDigestMultibase != sent.cardDigest ||
        statement.identityCommitment != sent.identityCommitment ||
        statement.validFrom.isAfter(now.add(clockSkew)) ||
        now.isAfter(statement.validUntil)) {
      throw const VettingException(
        VettingFailure.badAnswer,
        detail: 'statement',
      );
    }
    await _verify(
      statement.credential,
      purpose: ProofPurpose.assertionMethod,
      signer: vetterDid,
    );
    return statement;
  }

  /// Reads the vetter's refusal to vouch for the request [vetter] accepted.
  VettingDecline declined(
    TrustTaskDocument decline, {
    required AcceptedVetter vetter,
  }) {
    _checkFrom(decline, vetter.vetterDid);
    if (decline.type != VettingTask.decline ||
        decline.payload['requestId'] != vetter.requestId) {
      throw const VettingException(VettingFailure.badAnswer, detail: 'decline');
    }
    final code = decline.payload['code'];
    final message = decline.payload['message'];
    return VettingDecline(
      code: code is String ? code : null,
      message: message is String ? message : null,
    );
  }

  /// The role card in [vp] that shows [vetterDid] holds [role] in
  /// [communityDid], after checking the presentation is the vetter's, made
  /// for this request and this applicant, and the card is the community's.
  Future<Map<String, dynamic>> _eligibility(
    Object? vp, {
    required String vetterDid,
    required String nonce,
    required String communityDid,
    required String role,
  }) async {
    if (vp is! Map<String, dynamic>) {
      throw const VettingException(
        VettingFailure.notVetter,
        detail: 'no presentation',
      );
    }
    if (!credentialTypes(vp).contains('VerifiablePresentation') ||
        vp['holder'] != vetterDid ||
        vp['nonce'] != nonce ||
        vp['domain'] != joinDid) {
      throw const VettingException(
        VettingFailure.notVetter,
        detail: 'presentation',
      );
    }
    await _verify(vp, purpose: ProofPurpose.authentication, signer: vetterDid);

    final credentials = vp['verifiableCredential'];
    for (final card in credentials is List ? credentials : [credentials]) {
      if (card is! Map<String, dynamic> ||
          !grantsCommunityRole(
            card,
            communityDid: communityDid,
            holderDid: vetterDid,
            role: role,
          )) {
        continue;
      }
      _checkValidity(card);
      await _verify(
        card,
        purpose: ProofPurpose.assertionMethod,
        signer: communityDid,
      );
      return card;
    }
    throw const VettingException(VettingFailure.notVetter, detail: 'role');
  }

  void _checkValidity(Map<String, dynamic> card) {
    if (!roleCardInDate(card, _now(), skew: clockSkew)) {
      throw const VettingException(
        VettingFailure.notVetter,
        detail: 'role expired',
      );
    }
  }

  /// Refuses [document] unless [vetterDid] sent it to the persona, in the
  /// thread [thread] when given. Its proof was checked when it was picked
  /// up ([PersonaInbox.peerDocuments]).
  void _checkFrom(
    TrustTaskDocument document,
    String vetterDid, {
    String? thread,
  }) {
    if (document.issuer != vetterDid ||
        document.recipient != joinDid ||
        (thread != null && document.threadId != thread)) {
      throw const VettingException(
        VettingFailure.badAnswer,
        detail: 'not from the vetter',
      );
    }
  }

  Future<void> _verify(
    Map<String, dynamic> document, {
    required ProofPurpose purpose,
    required String signer,
  }) async {
    try {
      await EddsaJcs2022.verify(
        document,
        purpose: purpose,
        resolver: _didResolver,
        expectedSigner: signer,
      );
    } on MeetingPlaceVtcSDKException catch (error) {
      throw VettingException(
        VettingFailure.badAnswer,
        detail: error.code.value,
      );
    }
  }

  static VettingFailure _refusal(Object? code) => switch (code) {
    'vetting/request:invalidTicket' => VettingFailure.invalidTicket,
    'vetting/request:capacity' ||
    'vetting/request:methodUnavailable' => VettingFailure.unavailable,
    'vetting/request:notEligible' => VettingFailure.notVetter,
    _ => VettingFailure.refused,
  };

  static final _challenge = RegExp(r'^[A-Za-z0-9_-]{43}$');
}

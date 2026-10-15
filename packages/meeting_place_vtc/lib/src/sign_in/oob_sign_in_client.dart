import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

import '../meeting_place_vtc_sdk_error_code.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/digest_multibase.dart';
import '../proof/eddsa_jcs_2022.dart';
import '../proof/trust_task_signer.dart';
import '../transport/trust_task_http_transport.dart';
import '../trigger_link/trigger_link_config.dart';
import '../trigger_link/trigger_link_result.dart';
import '../trust_task/trust_task_document.dart';
import '../trust_task/trust_task_time.dart';
import '../vtc/resolved_document.dart';
import '../vtc/vtc_resolver.dart';
import 'sign_in_agent.dart';
import 'sign_in_failure.dart';
import 'sign_in_session.dart';

/// The `auth/oob` Trust Task types of the Key Grant sign-in.
abstract final class OobTask {
  static const _base = 'https://trusttasks.org/spec/auth/oob';

  /// Locks a request to this phone's throwaway key.
  static const claim = '$_base/claim/0.1';

  /// Ends a claimed request.
  static const cancel = '$_base/cancel/0.1';

  /// The persona's statement of who signs in, signed by the VTA.
  static const identify = '$_base/identify/0.1';

  /// Carries the `identify` document.
  static const prove = '$_base/prove/0.1';

  /// The persona's approval of one browser session, signed by the VTA.
  static const grant = '$_base/grant/0.1';

  /// Carries the `grant` document.
  static const respond = '$_base/respond/0.1';
}

/// Type of the person's approval decision, signed with the UV key.
const consentDecisionTask =
    'https://trusttasks.org/spec/task-consent/decision/0.2';

/// Extension carrying the approval decision to the VTA.
const uvConsentExtension = 'org.openvtc.uv-consent';

/// Extension carrying the sign-in audience in the community's answers.
const sessionExtension = 'org.openvtc.session';

/// Longest session a grant opens.
const grantLifetime = Duration(hours: 12);

/// The wallet side of the Key Grant sign-in (`auth/oob/*`).
///
/// The steps are [claim], [prove], [approve], with [cancel] to decline. Each
/// answer from the community is checked before anything of it is shown or
/// used. Nothing is logged.
class OobSignInClient {
  /// Creates an [OobSignInClient].
  ///
  /// [isKnownCommunity] says whether this phone holds a membership of a
  /// community; it is asked before any network call. [now] returns seconds
  /// since the epoch.
  OobSignInClient({
    required Future<bool> Function(String vtcDid) isKnownCommunity,
    VtcResolver? vtcResolver,
    TrustTaskHttpTransport? transport,
    DidResolver? didResolver,
    int Function()? now,
    Ed25519DidKeySigner Function()? newApproverKey,
  }) : _isKnownCommunity = isKnownCommunity,
       _didResolver = didResolver ?? UniversalDIDResolver.defaultResolver,
       _transport = transport ?? TrustTaskHttpTransport(),
       _now = now ?? _systemNow,
       _newApproverKey = newApproverKey ?? Ed25519DidKeySigner.generate {
    _vtcResolver = vtcResolver ?? VtcResolver(didResolver: _didResolver);
  }

  static final _twoDigits = RegExp(r'^\d{2}$');
  static final _ed25519DidKey = RegExp(r'^did:key:z6Mk[1-9A-HJ-NP-Za-km-z]+$');
  static const _repeatedStep1Members = [
    'requestId',
    'service',
    'origin',
    'purpose',
    'decisionDeadline',
  ];

  final Future<bool> Function(String vtcDid) _isKnownCommunity;
  final DidResolver _didResolver;
  final TrustTaskHttpTransport _transport;
  final int Function() _now;
  final Ed25519DidKeySigner Function() _newApproverKey;
  late final VtcResolver _vtcResolver;

  static int _systemNow() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  /// Claims the sign-in request of [trigger] for this phone.
  ///
  /// On success the browser shows its two-digit number. Throws
  /// [SignInException] otherwise, before any network call when the link is
  /// not a sign-in code or names a community this phone has not joined.
  Future<ClaimedSignIn> claim(TriggerLinkAccepted trigger) async {
    if (trigger.flow != signInFlow) {
      throw const SignInException(SignInFailure.update);
    }
    final vtcDid = trigger.from;
    final requestId = trigger.id;

    if (!await _isKnownCommunity(vtcDid)) {
      throw const SignInException(SignInFailure.notAMember);
    }

    final VtcEndpoints vtc;
    try {
      vtc = await _vtcResolver.resolve(vtcDid);
    } on MeetingPlaceVtcSDKException catch (error) {
      throw SignInException(
        error.code == MeetingPlaceVtcSDKErrorCode.signInNotOffered
            ? SignInFailure.noSignIn
            : SignInFailure.unreachable,
        detail: error.code.value,
      );
    }

    final approverKey = _newApproverKey();
    final claim = await _envelope(
      OobTask.claim,
      {'requestId': requestId},
      approverKey: approverKey,
      vtcDid: vtcDid,
      requestId: requestId,
    );
    final answer = await _sendToCommunity(vtc, claim);
    await _verifyCommunity(answer, vtc, ProofPurpose.assertionMethod);

    final payload = _payload(answer);
    final problem = _step1Problem(
      answer,
      payload,
      claimId: claim.id,
      approverDid: approverKey.did,
      requestId: requestId,
      vtc: vtc,
    );
    if (problem != null) {
      throw SignInException(SignInFailure.badAnswer, detail: problem);
    }

    return ClaimedSignIn(
      requestId: requestId,
      vtc: vtc,
      decisionDeadline: payload['decisionDeadline'] as int,
      audience: _audience(answer),
      approverKey: approverKey,
      step1: answer.toJson(),
    );
  }

  /// Tells the community who signs in, with the number the person typed.
  ///
  /// The VTA signs `identify` as [persona]; the phone sends it in `prove`;
  /// the community's answer is checked before anything of it is returned.
  /// Throws [SignInException] with [SignInFailure.badNumber] before anything
  /// is sent when [enteredNumber] is not two digits, and with
  /// [SignInFailure.wrongNumber] when the community says it is wrong (one
  /// try).
  Future<ProvedSignIn> prove(
    ClaimedSignIn claimed, {
    required String enteredNumber,
    required SignInPersona persona,
    required SignInAgent agent,
  }) async {
    final number = enteredNumber.trim();
    if (!_twoDigits.hasMatch(number)) {
      throw const SignInException(SignInFailure.badNumber);
    }
    _checkDeadline(claimed);

    final identify = await _signedByAgent(
      agent,
      persona,
      _personaDocument(
        OobTask.identify,
        {
          'requestId': claimed.requestId,
          'approverKey': claimed.approverKey.did,
          'enteredNumber': number,
        },
        persona: persona.did,
        vtcDid: claimed.vtc.did,
      ),
      ProofPurpose.authentication,
    );

    final prove = await _envelope(
      OobTask.prove,
      {'identify': identify},
      approverKey: claimed.approverKey,
      vtcDid: claimed.vtc.did,
      requestId: claimed.requestId,
    );
    final step2 = await _sendToCommunity(claimed.vtc, prove);
    await _verifyCommunity(step2, claimed.vtc, ProofPurpose.assertionMethod);

    final payload = _payload(step2);
    final problem = _step2Problem(
      step2,
      payload,
      claimed: claimed,
      proveId: prove.id,
      persona: persona.did,
    );
    if (problem != null) {
      throw SignInException(SignInFailure.badAnswer, detail: problem);
    }

    final requester = payload['requester'] as Map<String, dynamic>;
    return ProvedSignIn(
      claimed: claimed,
      persona: persona,
      step2: step2.toJson(),
      sessionKey: payload['sessionKey'] as String,
      requester: SignInRequester(
        browser: _text(requester['browser']),
        os: _text(requester['os']),
        location: _text(requester['location']),
        sameNetwork: requester['sameNetwork'] == true,
        createdAt: _text(requester['createdAt'], fallback: ''),
      ),
    );
  }

  /// Approves a proved sign-in.
  ///
  /// Builds the grant, has the person approve exactly that grant with
  /// [userVerification] (a biometric prompt), has the VTA sign it as the
  /// persona, and hands it to the community. [userVerification] throws
  /// [UserVerificationException] when it cannot sign; nothing is sent then.
  /// Every failure from the moment
  /// the grant is sent has [SignInException.responded] set.
  Future<void> approve(
    ProvedSignIn proved, {
    required SignInAgent agent,
    required TrustTaskSigner userVerification,
  }) async {
    final claimed = proved.claimed;
    _checkDeadline(claimed);
    final now = _now();

    final unsignedGrant = _personaDocument(
      OobTask.grant,
      {
        'requestId': claimed.requestId,
        'decision': 'approve',
        'sessionKey': proved.sessionKey,
        'approverKey': claimed.approverKey.did,
        'origin': claimed.origin,
        // Over the whole signed step 2 as received, proof included.
        'contextDigest': digestMultibase(proved.step2),
        'notAfter': now + grantLifetime.inSeconds,
      },
      persona: proved.persona.did,
      vtcDid: claimed.vtc.did,
    );

    final digest = digestMultibase(unsignedGrant);
    final Map<String, dynamic> decision;
    try {
      decision = await EddsaJcs2022.sign(
        {
          'id': 'urn:uuid:${const Uuid().v4()}',
          'type': consentDecisionTask,
          'issuer': userVerification.did,
          'recipient': agent.vtaDid,
          'issuedAt': formatTrustTaskTime(DateTime.now()),
          'payload': {
            'challenge': digest,
            'payloadDigest': digest,
            'decision': 'approve',
          },
        },
        signer: userVerification,
        purpose: ProofPurpose.assertionMethod,
      );
    } on UserVerificationException catch (error) {
      throw SignInException(switch (error.error) {
        UserVerificationError.cancelled => SignInFailure.uvCancelled,
        UserVerificationError.lost => SignInFailure.uvKeyLost,
        UserVerificationError.unavailable => SignInFailure.uvUnavailable,
      });
    }

    final grant = await _signedByAgent(
      agent,
      proved.persona,
      unsignedGrant,
      ProofPurpose.assertionMethod,
      ext: {
        uvConsentExtension: {'decision': decision},
      },
    );

    final respond = await _envelope(
      OobTask.respond,
      {'grant': grant},
      approverKey: claimed.approverKey,
      vtcDid: claimed.vtc.did,
      requestId: claimed.requestId,
    );
    claimed.responded = true;
    final answer = await _sendToCommunity(
      claimed.vtc,
      respond,
      responded: true,
    );

    // Communities before VTI b345ebd1 sign this answer for authentication;
    // both are the community's own key.
    try {
      await _verifyCommunity(answer, claimed.vtc, ProofPurpose.assertionMethod);
    } on SignInException {
      await _verifyCommunity(
        answer,
        claimed.vtc,
        ProofPurpose.authentication,
        responded: true,
      );
    }
    final status = _payload(answer)['status'];
    if (status != 'approved') {
      throw SignInException(
        SignInFailure.refused,
        detail: 'status $status',
        responded: true,
      );
    }
  }

  /// Gives up a claimed sign-in; also how the person declines.
  ///
  /// Returns whether the community confirmed the cancellation. Throws
  /// [StateError] for a sign-in whose grant may have been sent.
  Future<bool> cancel(ClaimedSignIn claimed) async {
    if (claimed.responded) {
      throw StateError('A responded sign-in must not be cancelled.');
    }
    final cancel = await _envelope(
      OobTask.cancel,
      {'requestId': claimed.requestId},
      approverKey: claimed.approverKey,
      vtcDid: claimed.vtc.did,
      requestId: claimed.requestId,
    );
    final answer = await _sendToCommunity(claimed.vtc, cancel);
    return _payload(answer)['status'] == 'cancelled';
  }

  Future<TrustTaskDocument> _envelope(
    String type,
    Map<String, dynamic> payload, {
    required Ed25519DidKeySigner approverKey,
    required String vtcDid,
    required String requestId,
  }) {
    return TrustTaskDocument.create(
      type: type,
      issuer: approverKey.did,
      recipient: vtcDid,
      parentThreadId: requestId,
      payload: payload,
    ).sign(approverKey, purpose: ProofPurpose.authentication);
  }

  /// An `identify` or `grant` as the VTA signs it: the framework members and
  /// nothing else.
  Map<String, dynamic> _personaDocument(
    String type,
    Map<String, dynamic> payload, {
    required String persona,
    required String vtcDid,
  }) {
    return TrustTaskDocument.create(
      type: type,
      issuer: persona,
      recipient: vtcDid,
      payload: payload,
    ).toJson();
  }

  Future<TrustTaskDocument> _sendToCommunity(
    VtcEndpoints vtc,
    TrustTaskDocument document, {
    bool responded = false,
  }) async {
    try {
      return await _transport.send(vtc.trustTaskBase, document);
    } on MeetingPlaceVtcSDKException catch (error) {
      throw SignInException(
        switch (error.code) {
          MeetingPlaceVtcSDKErrorCode.refused => _communityRefusal(
            error.refusalCode,
          ),
          MeetingPlaceVtcSDKErrorCode.transportFailed =>
            SignInFailure.unreachable,
          _ => SignInFailure.badAnswer,
        },
        detail: error.refusalCode ?? error.code.value,
        responded: responded,
      );
    }
  }

  static SignInFailure _communityRefusal(String? code) {
    return switch (code) {
      'auth/oob/claim:alreadyClaimed' => SignInFailure.alreadyClaimed,
      'auth/oob/prove:numberMismatch' => SignInFailure.wrongNumber,
      'auth/oob:requestExpired' => SignInFailure.expired,
      'auth/oob:requestNotFound' => SignInFailure.notFound,
      final String code when code.contains('notAnAdmin') =>
        SignInFailure.notAnAdmin,
      _ => SignInFailure.refused,
    };
  }

  /// Verifies a community answer against the already-resolved document, so
  /// that no second resolution can answer differently.
  Future<void> _verifyCommunity(
    TrustTaskDocument answer,
    VtcEndpoints vtc,
    ProofPurpose purpose, {
    bool responded = false,
  }) async {
    try {
      await EddsaJcs2022.verify(
        answer.toJson(),
        purpose: purpose,
        resolver: ResolvedDocument(vtc.didDocument),
        expectedSigner: vtc.did,
      );
    } on MeetingPlaceVtcSDKException {
      throw SignInException(
        SignInFailure.badAnswer,
        detail: "answer not signed by the community's ${purpose.value} key",
        responded: responded,
      );
    }
  }

  /// Has the VTA sign [unsigned] as [persona] and checks what comes back:
  /// the same document plus the persona's proof for [purpose].
  Future<Map<String, dynamic>> _signedByAgent(
    SignInAgent agent,
    SignInPersona persona,
    Map<String, dynamic> unsigned,
    ProofPurpose purpose, {
    Map<String, dynamic>? ext,
  }) async {
    final Map<String, dynamic> signed;
    try {
      signed = await signAsPersona(agent, persona, unsigned, ext: ext);
    } on MeetingPlaceVtcSDKException catch (error) {
      if (error.code == MeetingPlaceVtcSDKErrorCode.invalidDocument) {
        throw SignInException(SignInFailure.badAnswer, detail: error.message);
      }
      throw SignInException.fromAgent(error);
    }

    if (!await _verifies(signed, purpose, persona.did)) {
      // Agents before sign-in signing (VTI #1997) sign every document for
      // authentication: that agent needs an update, not a bad answer.
      final signedForAuthentication =
          purpose == ProofPurpose.assertionMethod &&
          await _verifies(signed, ProofPurpose.authentication, persona.did);
      throw SignInException(
        signedForAuthentication
            ? SignInFailure.agentNeedsUpdate
            : SignInFailure.badAnswer,
        detail: "the agent's proof is not the persona's for ${purpose.value}",
      );
    }
    return signed;
  }

  Future<bool> _verifies(
    Map<String, dynamic> document,
    ProofPurpose purpose,
    String signer,
  ) async {
    try {
      await EddsaJcs2022.verify(
        document,
        purpose: purpose,
        resolver: _didResolver,
        expectedSigner: signer,
      );
      return true;
    } on MeetingPlaceVtcSDKException {
      return false;
    }
  }

  void _checkDeadline(ClaimedSignIn claimed) {
    if (claimed.decisionDeadline <= _now()) {
      throw const SignInException(
        SignInFailure.expired,
        detail: 'the decision deadline has passed',
      );
    }
  }

  String? _step1Problem(
    TrustTaskDocument answer,
    Map<String, dynamic> payload, {
    required String claimId,
    required String approverDid,
    required String requestId,
    required VtcEndpoints vtc,
  }) {
    if (answer.threadId != claimId) return 'the answer does not thread';
    if (answer.recipient != approverDid) return 'the answer is not for us';
    if (payload['requestId'] != requestId) return 'another request';
    final service = payload['service'];
    if (service is! Map || service['did'] != vtc.did) {
      return 'another community';
    }
    if (payload['purpose'] != 'login') return 'not a sign-in';
    if (payload['origin'] != vtc.signInOrigin) {
      return 'origin is not the portal';
    }
    final deadline = payload['decisionDeadline'];
    if (deadline is! int) return 'no decision deadline';
    if (deadline <= _now()) return 'the decision deadline has passed';
    return null;
  }

  String? _step2Problem(
    TrustTaskDocument step2,
    Map<String, dynamic> payload, {
    required ClaimedSignIn claimed,
    required String proveId,
    required String persona,
  }) {
    if (step2.threadId != proveId) return 'step 2 does not thread';
    if (step2.recipient != claimed.approverKey.did) return 'not for us';
    final step1Payload = _payload(TrustTaskDocument.fromJson(claimed.step1));
    for (final member in _repeatedStep1Members) {
      if (JcsUtil.canonicalize(payload[member]) !=
          JcsUtil.canonicalize(step1Payload[member])) {
        return "step 2 does not repeat step 1's $member";
      }
    }
    if (_audience(step2) != claimed.audience) return 'the audience changed';
    final deadline = payload['decisionDeadline'];
    if (deadline is! int || deadline <= _now()) {
      return 'the decision deadline has passed';
    }
    final sessionKey = payload['sessionKey'];
    if (sessionKey is! String || !_ed25519DidKey.hasMatch(sessionKey)) {
      return 'the session key is not an Ed25519 did:key';
    }
    if (payload['identifiedAs'] != persona) return 'identified someone else';
    if (payload['requester'] is! Map<String, dynamic>) return 'no requester';
    return null;
  }

  /// The audience the community echoes in its signed answers: under the
  /// payload's `ext`, or the document's, as `org.openvtc.session`.
  static SignInAudience _audience(TrustTaskDocument answer) {
    final ext = _payload(answer)['ext'] ?? answer.ext;
    final session = ext is Map ? ext[sessionExtension] : null;
    final audience = session is Map ? session['audience'] : null;
    return audience == 'admin' ? SignInAudience.admin : SignInAudience.member;
  }

  static Map<String, dynamic> _payload(TrustTaskDocument document) =>
      document.payload;

  static String _text(Object? value, {String fallback = 'unknown'}) =>
      value is String ? value : fallback;
}

/// Serves one already-resolved DID document.

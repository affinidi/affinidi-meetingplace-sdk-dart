import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:ssi/ssi.dart';

import '../credentials/credential_fields.dart';
import '../meeting_place_vtc_sdk_error_code.dart';
import '../meeting_place_vtc_sdk_exception.dart';
import '../proof/eddsa_jcs_2022.dart';

/// Whether a credential still holds, as its issuer's status list says.
enum CredentialStatusState {
  /// The issuer has not revoked it.
  valid,

  /// The issuer has revoked it.
  revoked,

  /// The credential names no status list: its issuer cannot revoke it.
  noStatus,
}

/// What a credential's issuer says of it in its status list, and the
/// signed list that says so.
class CredentialStatusCheck {
  /// Creates a [CredentialStatusCheck].
  const CredentialStatusCheck({
    required this.state,
    required this.checkedAt,
    this.statusList,
    this.index,
    this.statusListCredential,
  });

  /// Whether the credential still holds.
  final CredentialStatusState state;

  /// When the list was read.
  final DateTime checkedAt;

  /// Where the issuer publishes the list; null for
  /// [CredentialStatusState.noStatus].
  final Uri? statusList;

  /// The credential's place in the list.
  final int? index;

  /// The list as the issuer signed it, verified: what shows the state.
  final Map<String, dynamic>? statusListCredential;
}

/// Reads a credential's revocation from its issuer's W3C Bitstring Status
/// List.
///
/// The list must be served over HTTPS, issued and signed (`eddsa-jcs-2022`,
/// `assertionMethod`) by the credential's own issuer, for the entry's
/// purpose, and currently valid. Anything else fails closed: an unreadable
/// list never reads as valid.
class StatusListClient {
  /// Creates a [StatusListClient] that fetches with [dio] and resolves the
  /// issuer's keys with [didResolver].
  StatusListClient({
    DidResolver? didResolver,
    Dio? dio,
    DateTime Function()? now,
  }) : _didResolver = didResolver ?? UniversalDIDResolver.defaultResolver,
       _dio = dio ?? Dio(),
       _now = now ?? DateTime.now;

  /// How long fetching a list may take.
  static const timeout = Duration(seconds: 20);

  static const _entryType = 'BitstringStatusListEntry';
  static const _listType = 'BitstringStatusListCredential';
  static const _purpose = 'revocation';
  static const _cryptosuite = 'eddsa-jcs-2022';
  static const _base64UrlMultibase = 'u';

  /// How far the phone's clock may be off the issuer's: a list is signed,
  /// and so valid from, the moment it is served.
  static const clockSkew = Duration(minutes: 5);
  static const _bitsPerByte = 8;

  final DidResolver _didResolver;
  final Dio _dio;
  final DateTime Function() _now;

  /// Reads whether [credential]'s issuer revoked it.
  ///
  /// Throws [MeetingPlaceVtcSDKException]: with
  /// [MeetingPlaceVtcSDKErrorCode.transportFailed] when the list cannot be
  /// fetched, [MeetingPlaceVtcSDKErrorCode.invalidProof] when the issuer's
  /// signature on it does not verify, and
  /// [MeetingPlaceVtcSDKErrorCode.invalidDocument] when the credential's
  /// entry or the list cannot be read or do not match.
  Future<CredentialStatusCheck> check(Map<String, dynamic> credential) async {
    final checkedAt = _now();
    final status = credential['credentialStatus'];
    if (status == null) {
      return CredentialStatusCheck(
        state: CredentialStatusState.noStatus,
        checkedAt: checkedAt,
      );
    }
    final entries = status is List ? status : [status];
    final entry = entries.whereType<Map<String, dynamic>>().where(
      (entry) =>
          entry['type'] == _entryType && entry['statusPurpose'] == _purpose,
    );
    if (entry.isEmpty) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'no revocation status list entry',
      );
    }
    final index = int.tryParse('${entry.first['statusListIndex']}');
    final listUri = Uri.tryParse('${entry.first['statusListCredential']}');
    final issuer = credentialIssuer(credential);
    if (index == null || index < 0 || listUri == null || issuer == null) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'unreadable status list entry',
      );
    }
    if (listUri.scheme != 'https') {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'status list not served over HTTPS',
      );
    }

    final list = await _fetch(listUri);
    _checkList(list, listUri: listUri, issuer: issuer, now: checkedAt);
    await _verify(list, issuer: issuer);
    final revoked = _bitAt(list, index);

    return CredentialStatusCheck(
      state: revoked
          ? CredentialStatusState.revoked
          : CredentialStatusState.valid,
      checkedAt: checkedAt,
      statusList: listUri,
      index: index,
      statusListCredential: list,
    );
  }

  Future<Map<String, dynamic>> _fetch(Uri uri) async {
    final Response<String> response;
    try {
      response = await _dio.getUri<String>(
        uri,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: timeout,
          sendTimeout: timeout,
          validateStatus: (_) => true,
        ),
      );
    } on DioException catch (error) {
      throw MeetingPlaceVtcSDKException.transportFailed(
        error.type.name,
        innerException: error,
      );
    }
    if (response.statusCode != 200) {
      throw MeetingPlaceVtcSDKException.transportFailed(
        'HTTP ${response.statusCode} for the status list',
        httpStatus: response.statusCode,
      );
    }
    try {
      if (jsonDecode(response.data ?? '') case final Map<String, dynamic> map) {
        return map;
      }
    } on FormatException {
      // Not JSON: refused below.
    }
    throw MeetingPlaceVtcSDKException.invalidDocument('status list not JSON');
  }

  void _checkList(
    Map<String, dynamic> list, {
    required Uri listUri,
    required String issuer,
    required DateTime now,
  }) {
    if (!credentialTypes(list).contains(_listType)) {
      throw MeetingPlaceVtcSDKException.invalidDocument('not a status list');
    }
    if (list['id'] case final String id when id != listUri.toString()) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'status list published under another id',
      );
    }
    if (credentialIssuer(list) != issuer) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'status list of another issuer',
      );
    }
    if (_subject(list)['statusPurpose'] != _purpose) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'status list for another purpose',
      );
    }
    final validFrom = DateTime.tryParse('${list['validFrom']}');
    final validUntil = DateTime.tryParse('${list['validUntil']}');
    if ((validFrom != null && now.add(clockSkew).isBefore(validFrom)) ||
        (validUntil != null && now.subtract(clockSkew).isAfter(validUntil))) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'status list not valid now',
      );
    }
  }

  /// Verifies the issuer's `eddsa-jcs-2022` proof on [list]. A list may
  /// carry a set of proofs, each made over the list without the others, so
  /// each is verified alone and one that verifies is enough.
  Future<void> _verify(
    Map<String, dynamic> list, {
    required String issuer,
  }) async {
    final proof = list['proof'];
    final proofs = (proof is List ? proof : [proof])
        .whereType<Map<String, dynamic>>()
        .where((proof) => proof['cryptosuite'] == _cryptosuite);
    MeetingPlaceVtcSDKException? failure;
    for (final proof in proofs) {
      try {
        await EddsaJcs2022.verify(
          {...list, 'proof': proof},
          purpose: ProofPurpose.assertionMethod,
          resolver: _didResolver,
          expectedSigner: issuer,
        );
        return;
      } on MeetingPlaceVtcSDKException catch (error) {
        failure = error;
      }
    }
    throw failure ??
        MeetingPlaceVtcSDKException.invalidProof('no $_cryptosuite proof');
  }

  /// Whether the bit at [index] of [list]'s bitstring is set. Bit 0 is the
  /// most significant bit of the first byte.
  ///
  /// The bitstring is GZIP in base64url: multibase (`u…`) as the W3C
  /// specification writes it, or bare as `affinidi-status-list` and so the
  /// VTC write it. Bare GZIP always starts `H4sI`, so a leading `u` is
  /// never part of it.
  bool _bitAt(Map<String, dynamic> list, int index) {
    final encoded = _subject(list)['encodedList'];
    final List<int> bits;
    try {
      if (encoded is! String) {
        throw const FormatException('no bitstring');
      }
      final base64 = encoded.startsWith(_base64UrlMultibase)
          ? encoded.substring(_base64UrlMultibase.length)
          : encoded;
      final compressed = base64Url.decode(base64Url.normalize(base64));
      bits = const GZipDecoder().decodeBytes(compressed);
    } on Object {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'status list bitstring unreadable',
      );
    }
    final byte = index ~/ _bitsPerByte;
    if (byte >= bits.length) {
      throw MeetingPlaceVtcSDKException.invalidDocument(
        'status list index out of range',
      );
    }
    final shift = _bitsPerByte - 1 - index % _bitsPerByte;
    return (bits[byte] >> shift) & 1 == 1;
  }

  static Map<String, dynamic> _subject(Map<String, dynamic> list) =>
      switch (list['credentialSubject']) {
        final Map<String, dynamic> subject => subject,
        _ => const {},
      };
}

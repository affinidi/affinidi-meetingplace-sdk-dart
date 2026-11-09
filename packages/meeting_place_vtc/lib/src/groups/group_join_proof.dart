import 'dart:convert';

import 'package:didcomm/didcomm.dart' show Attachment, AttachmentData;

import '../meeting_place_vtc_sdk_exception.dart';
import '../vta/vta_client.dart';
import 'group_admission.dart';

/// What a member sends a community group chat's owner to be let in: the
/// group's membership credential, presented by the member's VTA as the
/// member and bound to the chat and the joining DID, and the community's
/// grant to the group to issue it.
///
/// Travels as two attachments of the request to join, after the contact
/// card. Both are personal data: never log them.
class GroupJoinProof {
  /// Creates a [GroupJoinProof].
  const GroupJoinProof({required this.presentation, required this.authority});

  /// The membership credential, in a presentation the member signed.
  final Map<String, dynamic> presentation;

  /// The community's authority credential to the group.
  final Map<String, dynamic> authority;

  /// Id of the attachment carrying [presentation].
  static const presentationAttachmentId = 'vtc-group-membership';

  /// Id of the attachment carrying [authority].
  static const authorityAttachmentId = 'vtc-group-authority';

  static const _mediaType = 'application/json';

  /// Has [vta] prove that [personaDid] belongs to the group [groupDid] of
  /// the community [communityDid], to the group's chat, which the member
  /// joins as [memberDid].
  ///
  /// The VTA presents the group's membership credential it keeps for the
  /// persona, as the persona, bound to the chat and [memberDid], so the
  /// proof cannot be replayed for another joiner. A credential that says
  /// nothing of its subject but who they are, as a group's does, is one the
  /// VTA's presentation task cannot present, as it asks for a claim to
  /// disclose: the VTA signs the same presentation with the persona's key
  /// [signingKeyId] instead. Returns null when the VTA keeps no valid
  /// membership credential of the group for the persona, or no grant from
  /// the community to the group, or when such a credential needs a key not
  /// given.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the VTA refuses or cannot be
  /// reached.
  static Future<GroupJoinProof?> prove(
    VtaClient vta, {
    required String groupDid,
    required String communityDid,
    required String personaDid,
    required String memberDid,
    String? signingKeyId,
  }) async {
    final membership = (await vta.findCredentials(
      type: GroupAdmissionVerifier.membershipType,
      issuerDid: groupDid,
      subjectDid: personaDid,
    )).firstOrNull;
    final grant = (await vta.findCredentials(
      type: GroupAdmissionVerifier.authorityType,
      issuerDid: communityDid,
      subjectDid: groupDid,
    )).firstOrNull;
    if (membership == null || grant == null) return null;

    final authority = await vta.credential(grant.id);
    final card = await vta.credential(membership.id);
    if (authority == null || card == null) return null;
    // A Data Integrity credential discloses all its claims or none.
    final claims = _subjectClaims(card);
    if (claims.isEmpty) {
      if (signingKeyId == null) return null;
      return GroupJoinProof(
        presentation: await vta.signDocument(
          keyId: signingKeyId,
          purpose: 'authentication',
          document: {
            '@context': ['https://www.w3.org/ns/credentials/v2'],
            'type': ['VerifiablePresentation'],
            'holder': personaDid,
            // The VTA signs a document as the DID it names as its issuer
            // or controller; a presentation's signer is its holder.
            'controller': personaDid,
            'verifiableCredential': [card],
            'domain': groupDid,
            'nonce': memberDid,
          },
        ),
        authority: authority,
      );
    }
    final presented = await vta.presentCredential(
      id: membership.id,
      claims: claims,
      audience: groupDid,
      nonce: memberDid,
      purpose: 'Join the group chat',
    );
    return GroupJoinProof(
      presentation: presented.presentation,
      authority: authority,
    );
  }

  static List<String> _subjectClaims(Map<String, dynamic> credential) =>
      switch (credential['credentialSubject']) {
        final Map<String, dynamic> subject => [
          for (final claim in subject.keys)
            if (claim != 'id') claim,
        ],
        _ => const [],
      };

  /// This proof as the attachments of a request to join.
  List<Attachment> toAttachments() => [
    _attachment(presentationAttachmentId, presentation),
    _attachment(authorityAttachmentId, authority),
  ];

  /// The proof among [attachments], or null when they carry none, or one
  /// that cannot be read.
  static GroupJoinProof? fromAttachments(List<Attachment> attachments) {
    final presentation = _read(attachments, presentationAttachmentId);
    final authority = _read(attachments, authorityAttachmentId);
    if (presentation == null || authority == null) return null;
    return GroupJoinProof(presentation: presentation, authority: authority);
  }

  static Attachment _attachment(String id, Map<String, dynamic> content) =>
      Attachment(
        id: id,
        mediaType: _mediaType,
        data: AttachmentData(
          base64: base64UrlEncode(utf8.encode(jsonEncode(content))),
        ),
      );

  static Map<String, dynamic>? _read(List<Attachment> attachments, String id) {
    final encoded = attachments
        .where((attachment) => attachment.id == id)
        .firstOrNull
        ?.data
        ?.base64;
    if (encoded == null) return null;
    try {
      final decoded = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(encoded))),
      );
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}

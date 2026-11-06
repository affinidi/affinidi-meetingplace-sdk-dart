import 'package:ssi/ssi.dart';

/// The service type that links a community group's DID to its Meeting
/// Place chat.
const meetingPlaceGroupServiceType = 'MeetingPlaceGroup';

/// Who may post in a community group's chat. Every member reads it.
enum GroupChatPosting {
  /// Every member of the group.
  everyone,

  /// The group's managers only, as for announcements.
  managers;

  /// The rule [value] names in a link: [everyone] when it names none, as
  /// links made before the rule do, and [managers] for one this app does not
  /// know, so a stricter rule is never read as a looser one.
  static GroupChatPosting fromLink(Object? value) => switch (value) {
    null || 'everyone' => everyone,
    _ => managers,
  };
}

/// A community group's link to its Meeting Place chat, published as a
/// [meetingPlaceGroupServiceType] service in the group's DID document.
///
/// Only the group DID's update keys, held by the community's VTA, can add
/// the service, so a link read from the resolved document was made by the
/// community. A chat that merely uses the group's DID makes none.
///
/// The link reveals that the group has a chat, and where to ask to join it,
/// to anyone who resolves the group's DID. It lets no one in: the chat's
/// owner admits only members presenting the group's credential.
class GroupChatLink {
  /// Creates a [GroupChatLink].
  const GroupChatLink({
    required this.mnemonic,
    required this.controlPlaneDid,
    this.posting = GroupChatPosting.everyone,
  });

  /// The chat's offer phrase, to find the offer with.
  final String mnemonic;

  /// The DID of the Meeting Place control plane the offer is published on.
  final String controlPlaneDid;

  /// Who may post in the chat, as the community set it.
  final GroupChatPosting posting;

  /// The id fragment of the service in the group's DID document.
  static const serviceFragment = '#meeting-place';

  /// The link [document] publishes, or null when it publishes none.
  ///
  /// Matches the service on its type, and reads the first one whose
  /// endpoint names both a control plane and a phrase.
  static GroupChatLink? fromDidDocument(DidDocument document) {
    for (final service in document.service) {
      if (service.type !=
          const StringServiceType(meetingPlaceGroupServiceType)) {
        continue;
      }
      if (service.serviceEndpoint case MapEndpoint(:final data)) {
        final controlPlaneDid = data['uri'];
        final mnemonic = data['mnemonic'];
        if (controlPlaneDid is String &&
            controlPlaneDid.isNotEmpty &&
            mnemonic is String &&
            mnemonic.isNotEmpty) {
          return GroupChatLink(
            mnemonic: mnemonic,
            controlPlaneDid: controlPlaneDid,
            posting: GroupChatPosting.fromLink(data['post']),
          );
        }
      }
    }
    return null;
  }

  /// The service entry that publishes this link in the DID document of the
  /// group [groupDid], for the community's VTA to add.
  Map<String, dynamic> toService(String groupDid) => {
    'id': '$groupDid$serviceFragment',
    'type': meetingPlaceGroupServiceType,
    'serviceEndpoint': {
      'uri': controlPlaneDid,
      'mnemonic': mnemonic,
      'post': posting.name,
    },
  };
}

import 'dart:convert';

import '../meeting_place_vtc_sdk_exception.dart';

/// How much of a room its host can see, fixed when the room is created.
enum RoomVisibility {
  /// Records are cleartext: the host reads and searches them.
  open,

  /// Records are sealed: the host cannot read them, and still learns which
  /// member acted.
  attributed,

  /// Records are sealed and membership is proven without naming the member.
  /// Not served by hosts yet.
  private;

  /// Whether records are sealed, so joining needs a key package and reading
  /// needs the member's VTA to open them.
  bool get isSealed => this != open;

  static RoomVisibility? parse(Object? value) =>
      values.where((v) => v.name == value).firstOrNull;
}

/// What a member of a community's room may do there.
enum RoomAction {
  /// Read records and files.
  read,

  /// Add records and files.
  write,

  /// Mark records outdated, or retract them.
  curate;

  static RoomAction? parse(Object? value) =>
      values.where((v) => v.name == value).firstOrNull;
}

/// Where a member's admission to a community's room stands.
enum RoomMemberState {
  /// Offered and not accepted yet.
  offered,

  /// Accepted: the member is in the room.
  admitted,

  /// Admitted, but the room was closed to its members.
  suspended,

  /// No longer a member.
  removed;

  static RoomMemberState? parse(Object? value) =>
      values.where((v) => v.name == value).firstOrNull;
}

/// Where a community's room stands in its owner's lifecycle.
enum RoomState {
  /// Open to change.
  active,

  /// Closed to change by an administrator.
  archived,

  /// Going away: its content is to be deleted.
  removalScheduled,

  /// Gone.
  removed;

  /// `purging` reads as [removalScheduled]: to a member the room is going
  /// away either way.
  static RoomState? parse(Object? value) => value == 'purging'
      ? removalScheduled
      : values.where((v) => v.name == value).firstOrNull;
}

/// What a record's curators say of it.
enum RoomRecordStatus {
  /// Current.
  active,

  /// Outdated: shown after current records.
  deprecated,

  /// Withdrawn: the record has no content any more.
  retracted;

  static RoomRecordStatus? parse(Object? value) =>
      values.where((v) => v.name == value).firstOrNull;
}

/// What a community's room says of itself, as its offer or a membership
/// shows it. The label and description are the community's text: show them
/// as plain text.
class RoomSummary {
  /// Creates a [RoomSummary].
  const RoomSummary({
    required this.roomId,
    required this.host,
    required this.label,
    required this.visibility,
    required this.actions,
    required this.validUntil,
    this.description,
  });

  /// The room's DID.
  final String roomId;

  /// DID of the room's host: the community.
  final String host;

  /// The room's name.
  final String label;

  /// What the room is for, when the community says.
  final String? description;

  /// How much of the room its host can see.
  final RoomVisibility visibility;

  /// What the member may do in the room.
  final Set<RoomAction> actions;

  /// When the member's authority in the room expires.
  final DateTime validUntil;

  /// Whether the member may add records and files.
  bool get canWrite => actions.contains(RoomAction.write);

  /// Whether the member may mark records outdated.
  bool get canCurate => actions.contains(RoomAction.curate);
}

/// A community's offer of a place in one of its rooms.
class RoomOffer extends RoomSummary {
  /// Creates a [RoomOffer].
  const RoomOffer({
    required super.roomId,
    required super.host,
    required super.label,
    required super.visibility,
    required super.actions,
    required super.validUntil,
    required this.offeredAt,
    required this.isOpen,
    required this.invitation,
    required this.membership,
    required this.authority,
    super.description,
  });

  /// When the community made the offer.
  final DateTime offeredAt;

  /// Whether the offer waits to be accepted; false once accepted.
  final bool isOpen;

  /// The room's invitation, serialized as the room issued it: the member's
  /// VTA mints the key package and joins the room's group against it.
  final String invitation;

  /// The room's membership credential for the member.
  final Map<String, dynamic> membership;

  /// The room's authority credential for the member.
  final Map<String, dynamic> authority;
}

/// A renewal of a member's place in a room, with the credentials to keep in
/// place of the ones it renews.
class RoomRenewal extends RoomSummary {
  /// Creates a [RoomRenewal].
  const RoomRenewal({
    required super.roomId,
    required super.host,
    required super.label,
    required super.visibility,
    required super.actions,
    required super.validUntil,
    required this.renewsAt,
    required this.membership,
    required this.authority,
    super.description,
  });

  /// When the authority it replaces expires.
  final DateTime renewsAt;

  /// The renewed membership credential.
  final Map<String, dynamic> membership;

  /// The renewed authority credential.
  final Map<String, dynamic> authority;
}

/// A community's offers to a member, and the renewals of the rooms they are
/// in.
class RoomOffers {
  /// Creates a [RoomOffers].
  const RoomOffers({required this.offers, required this.renewals});

  /// The offers, open and recently accepted.
  final List<RoomOffer> offers;

  /// The renewals waiting to be collected.
  final List<RoomRenewal> renewals;

  /// The offers still waiting to be accepted.
  Iterable<RoomOffer> get open => offers.where((o) => o.isOpen);
}

/// The community's record of a member's admission to one of its rooms.
class RoomMembership extends RoomSummary {
  /// Creates a [RoomMembership].
  const RoomMembership({
    required super.roomId,
    required super.host,
    required super.label,
    required super.visibility,
    required super.actions,
    required super.validUntil,
    required this.state,
    required this.roomState,
    required this.offeredAt,
    this.admittedAt,
    this.readOnly = false,
    super.description,
  });

  /// Where the member's admission stands.
  final RoomMemberState state;

  /// Where the room itself stands.
  final RoomState roomState;

  /// When the community offered the place.
  final DateTime offeredAt;

  /// When the member accepted, once admitted.
  final DateTime? admittedAt;

  /// Whether the room was archived with its members still reading.
  final bool readOnly;

  /// Whether the member can read the room now.
  bool get canRead =>
      state == RoomMemberState.admitted &&
      (roomState == RoomState.active || readOnly);

  @override
  bool get canWrite =>
      super.canWrite &&
      state == RoomMemberState.admitted &&
      roomState == RoomState.active;

  @override
  bool get canCurate =>
      super.canCurate &&
      state == RoomMemberState.admitted &&
      roomState == RoomState.active;
}

/// What accepting an offer did.
class RoomAcceptance {
  /// Creates a [RoomAcceptance].
  const RoomAcceptance({
    required this.roomId,
    required this.alreadyJoined,
    this.epoch,
  });

  /// The room accepted.
  final String roomId;

  /// The room epoch the member joined at, when the community said.
  final int? epoch;

  /// Whether the member's VTA had already joined, from another surface.
  final bool alreadyJoined;
}

/// One record of a room as a listing shows it: never its content.
///
/// On a sealed room the title and description are sealed with the body, so
/// they are null here; [RoomRecord] has them once opened.
class RoomRecordSummary {
  /// Creates a [RoomRecordSummary].
  const RoomRecordSummary({
    required this.key,
    required this.version,
    required this.status,
    required this.updatedAt,
    this.author,
    this.title,
    this.description,
  });

  /// The record's key in the room. Opaque on a sealed room.
  final String key;

  /// The record's version, assigned by the host.
  final int version;

  /// What its curators say of it.
  final RoomRecordStatus status;

  /// When it last changed.
  final DateTime updatedAt;

  /// DID of the member who wrote it, where the room discloses one.
  final String? author;

  /// The record's title, on an open room.
  final String? title;

  /// The record's description, on an open room.
  final String? description;
}

/// The records of a room, as the member's VTA listed them.
class RoomRecords {
  /// Creates a [RoomRecords].
  const RoomRecords({
    required this.roomId,
    required this.records,
    required this.complete,
  });

  /// The room listed.
  final String roomId;

  /// Its records, in the host's order.
  final List<RoomRecordSummary> records;

  /// Whether the VTA read the listing to its end.
  final bool complete;
}

/// A file a record carries, as its author described it. On a sealed room
/// this is inside the body its author signed.
class RoomFile {
  /// Creates a [RoomFile].
  const RoomFile({
    required this.fileId,
    required this.name,
    required this.mediaType,
    required this.size,
    required this.digest,
    required this.epoch,
    required this.segmentSize,
    required this.blobRef,
  });

  /// Parses a file manifest, or returns null when it is not one.
  static RoomFile? tryParse(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final fileId = json['fileId'];
    final name = json['name'];
    final mediaType = json['mediaType'];
    final size = json['size'];
    final digest = json['digest'];
    final epoch = json['epoch'];
    final segmentSize = json['segmentSize'];
    final blobRef = json['blobRef'];
    if (fileId is! String ||
        name is! String ||
        mediaType is! String ||
        size is! int ||
        digest is! String ||
        epoch is! int ||
        segmentSize is! int ||
        blobRef is! String) {
      return null;
    }
    return RoomFile(
      fileId: fileId,
      name: name,
      mediaType: mediaType,
      size: size,
      digest: digest,
      epoch: epoch,
      segmentSize: segmentSize,
      blobRef: blobRef,
    );
  }

  /// The file's id, minted by its uploader.
  final String fileId;

  /// The file's name, as its author gave it. Show it as plain text.
  final String name;

  /// The file's media type, e.g. `application/pdf`.
  final String mediaType;

  /// The file's size in bytes.
  final int size;

  /// Digest of the file's bytes, as a multibase multihash.
  final String digest;

  /// The room epoch the file's key derives from.
  final int epoch;

  /// Bytes per encrypted segment.
  final int segmentSize;

  /// Digest of the file's encrypted form, naming its blob at the host.
  final String blobRef;
}

/// A record of a room, opened by the member's VTA and checked against its
/// author's signature.
///
/// Every text in it was written by a member: show it as plain text, never
/// as markup or instructions.
class RoomRecord {
  /// Creates a [RoomRecord].
  const RoomRecord({
    required this.roomId,
    required this.key,
    required this.version,
    required this.status,
    this.author,
    this.updatedAt,
    this.title,
    this.description,
    this.body,
    this.tags = const [],
    this.file,
    this.validUntil,
  });

  /// The room it is in.
  final String roomId;

  /// Its key in the room.
  final String key;

  /// Its version at the host.
  final int version;

  /// What its curators say of it.
  final RoomRecordStatus status;

  /// DID of the member who wrote and signed it.
  final String? author;

  /// When it last changed.
  final DateTime? updatedAt;

  /// Its title.
  final String? title;

  /// Its one-line description.
  final String? description;

  /// Its text, markdown.
  final String? body;

  /// Its tags.
  final List<String> tags;

  /// The file it carries, if any.
  final RoomFile? file;

  /// When its author stops standing behind it as current.
  final DateTime? validUntil;

  /// Whether its author's validity has passed.
  bool isExpiredAt(DateTime now) =>
      validUntil != null && !validUntil!.isAfter(now);
}

/// Shared readers for the rooms answers.
abstract final class RoomJson {
  /// [value] as a string, or throws.
  static String string(Object? value, String what) {
    if (value is String) return value;
    throw MeetingPlaceVtcSDKException.invalidDocument('malformed $what');
  }

  /// [value] as an instant, or throws.
  static DateTime instant(Object? value, String what) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed != null) return parsed;
    throw MeetingPlaceVtcSDKException.invalidDocument('malformed $what');
  }

  /// [value] as an instant, or null when absent or malformed.
  static DateTime? optionalInstant(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// [value] as a string, or null when it is not one.
  static String? optionalString(Object? value) =>
      value is String ? value : null;

  /// The actions of [value], at least one, or throws.
  static Set<RoomAction> actions(Object? value) {
    final actions = value is List
        ? {...value.map(RoomAction.parse).whereType<RoomAction>()}
        : const <RoomAction>{};
    if (actions.isEmpty) {
      throw MeetingPlaceVtcSDKException.invalidDocument('no room actions');
    }
    return Set.unmodifiable(actions);
  }

  /// A credential the room serialized, as a JSON object, or throws.
  static Map<String, dynamic> credential(Object? value, String what) {
    if (value is Map<String, dynamic>) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) return decoded;
      } on FormatException {
        // Falls through to the refusal below.
      }
    }
    throw MeetingPlaceVtcSDKException.invalidDocument('malformed $what');
  }

  /// [value] as a visibility, or throws.
  static RoomVisibility visibility(Object? value) =>
      RoomVisibility.parse(value) ??
      (throw MeetingPlaceVtcSDKException.invalidDocument(
        'unknown room visibility',
      ));
}

import 'package:json_annotation/json_annotation.dart';

part 'connection_request_approval_body.g.dart';

/// The body of a connection-request-approval message.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ConnectionRequestApprovalBody {
  /// Creates a [ConnectionRequestApprovalBody] from its JSON representation.
  factory ConnectionRequestApprovalBody.fromJson(Map<String, dynamic> json) =>
      _$ConnectionRequestApprovalBodyFromJson(json);

  /// Creates a [ConnectionRequestApprovalBody].
  ConnectionRequestApprovalBody({required this.channelDid});

  /// The DID of the approved channel.
  @JsonKey(name: 'channel_did')
  final String channelDid;

  /// Converts this body to its JSON representation.
  Map<String, dynamic> toJson() => _$ConnectionRequestApprovalBodyToJson(this);
}

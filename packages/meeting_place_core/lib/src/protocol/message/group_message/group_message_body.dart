import 'package:json_annotation/json_annotation.dart';

part 'group_message_body.g.dart';

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class GroupMessageBody {
  factory GroupMessageBody.fromJson(Map<String, dynamic> json) =>
      _$GroupMessageBodyFromJson(json);

  GroupMessageBody({
    required this.ciphertext,
    required this.iv,
    required this.authenticationTag,
    required this.preCapsule,
    required this.fromDid,
    required this.seqNo,
  });

  @JsonKey(name: 'ciphertext')
  final String ciphertext;

  @JsonKey(name: 'iv')
  final String iv;

  @JsonKey(name: 'authentication_tag')
  final String authenticationTag;

  @JsonKey(name: 'pre_capsule')
  final String preCapsule;

  @JsonKey(name: 'from_did')
  final String fromDid;

  @JsonKey(name: 'seq_no')
  final int seqNo;

  Map<String, dynamic> toJson() => _$GroupMessageBodyToJson(this);
}

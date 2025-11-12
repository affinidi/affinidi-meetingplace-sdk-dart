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

  @JsonKey(name: 'authenticationTag')
  final String authenticationTag;

  @JsonKey(name: 'preCapsule')
  final String preCapsule;

  @JsonKey(name: 'fromDid')
  final String fromDid;

  @JsonKey(name: 'seqNo')
  final int seqNo;

  Map<String, dynamic> toJson() => _$GroupMessageBodyToJson(this);
}

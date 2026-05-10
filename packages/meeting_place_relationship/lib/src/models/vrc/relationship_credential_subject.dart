import 'package:json_annotation/json_annotation.dart';

part 'relationship_credential_subject.g.dart';

@JsonSerializable()
class RelationshipCredentialSubject {
  const RelationshipCredentialSubject({required this.from, required this.to});

  factory RelationshipCredentialSubject.fromJson(Map<String, dynamic> json) =>
      _$RelationshipCredentialSubjectFromJson(json);

  final Party from;
  final Party to;

  Map<String, dynamic> toJson() => _$RelationshipCredentialSubjectToJson(this);
}

@JsonSerializable()
class Party {
  const Party({required this.did, required this.name});

  factory Party.fromJson(Map<String, dynamic> json) => _$PartyFromJson(json);

  final String did;
  final String name;

  Map<String, dynamic> toJson() => _$PartyToJson(this);
}

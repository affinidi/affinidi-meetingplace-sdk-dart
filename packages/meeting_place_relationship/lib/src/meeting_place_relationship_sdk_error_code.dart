enum MeetingPlaceRelationshipSDKErrorCode {
  // vrc codes
  vrcInvalidCredential('relationship_vrc_invalid_credential'),

  // others
  generic('generic');

  const MeetingPlaceRelationshipSDKErrorCode(this.value);
  final String value;
}

/// MatrixRTC call scope values defined by the Matrix spec.
enum MatrixRtcCallScope {
  /// Call is scoped to a room — visible to all members (`m.room`).
  room('m.room'),

  /// Call is scoped to a user — direct call (`m.user`).
  user('m.user');

  const MatrixRtcCallScope(this.value);

  final String value;
}

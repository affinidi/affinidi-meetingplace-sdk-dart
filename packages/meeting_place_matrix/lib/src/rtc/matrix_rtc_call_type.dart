/// MatrixRTC call session type values defined by the Matrix spec.
enum MatrixRtcCallType {
  /// Standard call session type (`m.call`).
  call('m.call');

  const MatrixRtcCallType(this.value);

  final String value;
}

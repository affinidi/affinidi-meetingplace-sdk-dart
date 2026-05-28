final _matrixMediaIdPattern = RegExp(r'^[A-Za-z0-9_-]+$');

const matrixMxcUriScheme = 'mxc://';

({String serverName, String mediaId}) parseMatrixMediaUri(String mxcUri) {
  if (!mxcUri.startsWith(matrixMxcUriScheme)) {
    throw const FormatException('Must start with mxc://');
  }

  final withoutScheme = mxcUri.substring(matrixMxcUriScheme.length);
  final slashIndex = withoutScheme.indexOf('/');
  if (slashIndex < 0) {
    throw const FormatException('Invalid mxc:// format');
  }

  final serverName = withoutScheme.substring(0, slashIndex);
  final mediaId = withoutScheme.substring(slashIndex + 1);
  if (serverName.isEmpty || mediaId.isEmpty) {
    throw const FormatException('Invalid mxc:// format');
  }
  if (!_matrixMediaIdPattern.hasMatch(mediaId)) {
    throw const FormatException('Invalid Matrix media ID characters');
  }

  return (serverName: serverName, mediaId: mediaId);
}

import 'package:matrix/matrix.dart' as matrix;
import 'package:ssi/ssi.dart';

/// Returns an authenticated [matrix.Client] for [didManager], transparently
/// re-authenticating when the session has expired.
///
/// Shared by the room and call collaborators so each can obtain a live client
/// without owning the login/session lifecycle, which stays in `MatrixService`.
typedef EnsureMatrixSession =
    Future<matrix.Client> Function(
      DidManager didManager, {
      bool keepSyncActiveAfterLogin,
    });

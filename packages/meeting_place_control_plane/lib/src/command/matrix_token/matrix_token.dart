import 'package:ssi/ssi.dart';

import '../../core/command/command.dart';
import 'matrix_token_output.dart';

/// Model that represents the request sent for the [MatrixTokenCommand]
/// operation.
class MatrixTokenCommand extends DiscoveryCommand<MatrixTokenCommandOutput> {
  /// Creates a new instance of [MatrixTokenCommand].
  MatrixTokenCommand({required this.didManager, required this.homeserver});

  /// The [DidManager] that manages the DID for the matrix token request.
  final DidManager didManager;

  /// Matrix homeserver host or base URI.
  final Uri homeserver;
}

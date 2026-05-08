import '../../core/command/command.dart';
import 'matrix_token_output.dart';

/// Model that represents the request sent for the [MatrixTokenCommand]
/// operation.
class MatrixTokenCommand extends DiscoveryCommand<MatrixTokenCommandOutput> {
  /// Creates a new instance of [MatrixTokenCommand].
  MatrixTokenCommand({required this.homeserver});

  /// Matrix homeserver host or base URI.
  final Uri homeserver;
}

import '../../core/command/command.dart';
import 'update_offers_score_output.dart';

/// Command that requests a batch update of offer scores (e.g. VRC count).
class UpdateOffersScoreCommand
    extends DiscoveryCommand<UpdateOffersScoreCommandOutput> {
  UpdateOffersScoreCommand({
    required this.score,
    required this.offerLinksOrMnemonics,
  });

  /// Latest score (VRC count) to set.
  final int score;

  /// List of offerLinks or mnemonics to update.
  final List<String> offerLinksOrMnemonics;
}

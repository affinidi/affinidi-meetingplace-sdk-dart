import '../../core/command/command.dart';
import 'update_offers_score_result.dart';

/// Command that requests a batch update of offer scores (e.g. VRC count).
class UpdateOffersScoreRequest
    extends DiscoveryCommand<UpdateOffersScoreResult> {
  /// Creates a new instance of [UpdateOffersScoreRequest].
  UpdateOffersScoreRequest({required this.score, required this.mnemonics});

  /// Latest score (VRC count) to set.
  final int score;

  /// List of mnemonics to update.
  final List<String> mnemonics;
}

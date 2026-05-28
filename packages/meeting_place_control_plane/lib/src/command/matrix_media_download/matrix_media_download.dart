import 'package:ssi/ssi.dart';

import '../../core/command/command.dart';
import 'matrix_media_download_output.dart';

class MatrixMediaDownloadCommand
    extends DiscoveryCommand<MatrixMediaDownloadCommandOutput> {
  MatrixMediaDownloadCommand({
    required this.didManager,
    required this.homeserver,
    required this.roomId,
    required this.mxcUri,
  });

  final DidManager didManager;
  final Uri homeserver;
  final String roomId;
  final String mxcUri;
}

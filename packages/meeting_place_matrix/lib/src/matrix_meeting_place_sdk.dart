import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'matrix_config.dart';
import 'matrix_service.dart';
import 'matrix_transport.dart';

/// A [MeetingPlaceCoreSDK] backed by a Matrix homeserver.
///
/// Extends [MeetingPlaceCoreSDK] so consumers interact with a single object
/// and do not need to declare `meeting_place_core` as an explicit dependency.
/// The additional [matrixService] field exposes matrix-specific APIs for
/// consumers that need them (e.g. `meeting_place_matrix_livekit`).
///
/// Use [MatrixMeetingPlaceSDK.create] to instantiate.
class MatrixMeetingPlaceSDK extends MeetingPlaceCoreSDK {
  MatrixMeetingPlaceSDK._({
    required MeetingPlaceCoreSDKInit init,
    required this.matrixService,
  }) : super.fromInit(init);

  /// The underlying [MatrixService] — exposed for matrix-specific consumers
  /// (e.g. `meeting_place_matrix_livekit`) that need VoIP or OpenID token
  /// operations without those APIs leaking through [MeetingPlaceCoreSDK].
  final MatrixService matrixService;

  static Future<MatrixMeetingPlaceSDK> create({
    required Wallet wallet,
    required RepositoryConfig repositoryConfig,
    required MatrixConfig config,
    MeetingPlaceCoreSDKOptions options = const MeetingPlaceCoreSDKOptions(),
    MeetingPlaceCoreSDKLogger? logger,
  }) async {
    MatrixService? matrixServiceRef;

    final sdk = await MeetingPlaceCoreSDK.create(
      wallet: wallet,
      repositoryConfig: repositoryConfig,
      config: config,
      options: options,
      logger: logger,
      channelTransportFactory: (controlPlaneSDK) {
        final svc = MatrixService(
          config: config,
          controlPlaneSDK: controlPlaneSDK,
          logger:
              logger ??
              DefaultMeetingPlaceCoreSDKLogger(className: 'MatrixService'),
        );
        matrixServiceRef = svc;
        return MatrixTransport(matrixService: svc);
      },
      $factory: (init) =>
          MatrixMeetingPlaceSDK._(init: init, matrixService: matrixServiceRef!),
    );

    return sdk as MatrixMeetingPlaceSDK;
  }
}

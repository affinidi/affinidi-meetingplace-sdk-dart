import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:ssi/ssi.dart';

import '../../loggers/default_meeting_place_core_sdk_logger.dart';
import '../../loggers/meeting_place_core_sdk_logger.dart';
import '../../sdk/results/register_for_didcomm_notifications_result.dart';
import '../connection_manager/connection_manager.dart';

class NotificationService {
  NotificationService({
    required ControlPlaneSDK controlPlaneSDK,
    required MeetingPlaceMediatorSDK mediatorSDK,
    required ConnectionManager connectionManager,
    MeetingPlaceCoreSDKLogger? logger,
  })  : _controlPlaneSDK = controlPlaneSDK,
        _mediatorSDK = mediatorSDK,
        _connectionManager = connectionManager,
        _logger =
            logger ?? DefaultMeetingPlaceCoreSDKLogger(className: _className);

  static const String _className = 'NotificationService';

  final ControlPlaneSDK _controlPlaneSDK;
  final MeetingPlaceMediatorSDK _mediatorSDK;
  final ConnectionManager _connectionManager;
  final MeetingPlaceCoreSDKLogger _logger;

  Future<RegisterForDidcommNotificationsResult>
      registerForDIDCommNotifications({
    required Wallet wallet,
    required String mediatorDid,
    required String controlPlaneDid,
    String? recipientDid,
  }) async {
    final methodName = 'registerForDIDCommNotifications';
    _logger.info(
      'Started registering for DIDComm notifications',
      name: methodName,
    );

    final didManager = await _getRecipientDidManagerOrCreate(
      wallet: wallet,
      did: recipientDid,
    );

    final didDoc = await didManager.getDidDocument();
    final deviceToken = '$mediatorDid::${didDoc.id}';

    await Future.wait([
      _registerDeviceOnControlPlaneAPI(deviceToken, PlatformType.didcomm),
      _allowServiceToSendMessages(
        didManager: didManager,
        didDoc: didDoc,
        controlPlaneDid: controlPlaneDid,
      ),
    ]);

    final device = Device(
      deviceToken: deviceToken,
      platformType: PlatformType.didcomm,
    );

    _logger.info(
      'Finished registering for DIDComm notifications',
      name: methodName,
    );
    return RegisterForDidcommNotificationsResult(
      recipientDid: didManager,
      device: device,
    );
  }

  Future<Device> registerForPushNotifications(String deviceToken) async {
    final methodName = 'registerForPushNotifications';
    _logger.info(
      'Started registering for push notifications',
      name: methodName,
    );

    final platformType = PlatformType.pushNotification;
    try {
      final device = _controlPlaneSDK.device;

      if (device.deviceToken == deviceToken &&
          device.platformType == platformType) {
        _logger.warning('Device already registered', name: methodName);
        return device;
      }

      await _registerDeviceOnControlPlaneAPI(deviceToken, platformType);
    } on MissingDeviceException {
      await _registerDeviceOnControlPlaneAPI(deviceToken, platformType);
    }

    _logger.info(
      'Finished registering for push notifications',
      name: methodName,
    );

    return Device(deviceToken: deviceToken, platformType: platformType);
  }

  Future<DidManager> _getRecipientDidManagerOrCreate({
    required Wallet wallet,
    String? did,
  }) {
    return did != null
        ? _connectionManager.getDidManagerForDid(wallet, did)
        : _connectionManager.generateDid(wallet);
  }

  Future<void> _registerDeviceOnControlPlaneAPI(
    String deviceToken,
    PlatformType platformType,
  ) {
    return _controlPlaneSDK.execute(
      RegisterDeviceCommand(
        deviceToken: deviceToken,
        platformType: platformType,
      ),
    );
  }

  Future<void> _allowServiceToSendMessages({
    required DidManager didManager,
    required DidDocument didDoc,
    required String controlPlaneDid,
  }) {
    return _mediatorSDK.updateAcl(
      ownerDidManager: didManager,
      acl: AccessListAdd(ownerDid: didDoc.id, granteeDids: [controlPlaneDid]),
    );
  }
}

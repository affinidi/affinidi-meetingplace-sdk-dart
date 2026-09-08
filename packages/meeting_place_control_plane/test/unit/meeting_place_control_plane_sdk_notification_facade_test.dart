import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:test/test.dart';

import 'mocks.dart';

void main() {
  late RecordingMeetingPlaceControlPlaneSDK sdk;
  late Device device;

  setUp(() {
    sdk = RecordingMeetingPlaceControlPlaneSDK();
    device = Device(
      deviceToken: 'device-token',
      platformType: PlatformType.pushNotification,
    );
  });

  group('When using notification facade methods', () {
    group('and notifying an offer acceptance', () {
      test('it executes the matching command and returns its result', () async {
        final output = NotifyAcceptanceResult(success: true);
        sdk.stubbedResult = output;

        final request = NotifyAcceptanceRequest(
          mnemonic: 'coffee-chat',
          acceptOfferDid: 'did:key:accepting',
          offerLink: 'https://example.com/offers/1',
          senderInfo: 'Alice',
        );
        final result = await sdk.notifyAcceptance(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as NotifyAcceptanceRequest;
        expect(command.mnemonic, 'coffee-chat');
        expect(command.acceptOfferDid, 'did:key:accepting');
        expect(command.offerLink, 'https://example.com/offers/1');
        expect(command.senderInfo, 'Alice');
      });
    });

    group('and notifying a group offer acceptance', () {
      test('it executes the matching command and returns its result', () async {
        final output = NotifyGroupAcceptanceResult(success: true);
        sdk.stubbedResult = output;

        final request = NotifyAcceptanceGroupRequest(
          mnemonic: 'group-chat',
          acceptOfferDid: 'did:key:accepting',
          offerLink: 'https://example.com/group-offers/1',
          senderInfo: 'Alice',
        );
        final result = await sdk.notifyGroupAcceptance(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as NotifyAcceptanceGroupRequest;
        expect(command.mnemonic, 'group-chat');
        expect(command.acceptOfferDid, 'did:key:accepting');
        expect(command.offerLink, 'https://example.com/group-offers/1');
        expect(command.senderInfo, 'Alice');
      });
    });

    group('and notifying a channel', () {
      test('it executes the matching command and returns its result', () async {
        final output = NotifyChannelResult(success: true);
        sdk.stubbedResult = output;

        final request = NotifyChannelRequest(
          notificationToken: 'notification-token',
          did: 'did:key:channel',
          type: 'channel-updated',
        );
        final result = await sdk.notifyChannel(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as NotifyChannelRequest;
        expect(command.notificationToken, 'notification-token');
        expect(command.did, 'did:key:channel');
        expect(command.type, 'channel-updated');
      });
    });

    group('and notifying an outreach recipient', () {
      test('it executes the matching command and returns its result', () async {
        final output = NotifyOutreachResult(success: true);
        sdk.stubbedResult = output;

        final request = NotifyOutreachRequest(
          mnemonic: 'outreach-offer',
          senderInfo: 'Alice',
        );
        final result = await sdk.notifyOutreach(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as NotifyOutreachRequest;
        expect(command.mnemonic, 'outreach-offer');
        expect(command.senderInfo, 'Alice');
      });
    });

    group('and registering a notification channel', () {
      test('it executes the matching command and returns its result', () async {
        final output = RegisterNotificationResult(
          notificationToken: 'notification-token',
        );
        sdk.stubbedResult = output;

        final request = RegisterNotificationRequest(
          myDid: 'did:key:alice',
          theirDid: 'did:key:bob',
          device: device,
        );
        final result = await sdk.registerNotification(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as RegisterNotificationRequest;
        expect(command.myDid, 'did:key:alice');
        expect(command.theirDid, 'did:key:bob');
        expect(command.device, same(device));
      });
    });

    group('and deregistering a notification channel', () {
      test('it executes the matching command and returns its result', () async {
        final output = DeregisterNotificationResult(success: true);
        sdk.stubbedResult = output;

        final request = DeregisterNotificationRequest(
          notificationToken: 'notification-token',
        );
        final result = await sdk.deregisterNotification(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as DeregisterNotificationRequest;
        expect(command.notificationToken, 'notification-token');
      });
    });

    group('and fetching pending notifications', () {
      test('it executes the matching command and returns its result', () async {
        final output = GetPendingNotificationsResult(events: const []);
        sdk.stubbedResult = output;

        final request = GetPendingNotificationsRequest(device: device);
        final result = await sdk.getPendingNotifications(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as GetPendingNotificationsRequest;
        expect(command.device, same(device));
      });
    });

    group('and deleting pending notifications', () {
      test('it executes the matching command and returns its result', () async {
        final notificationIds = ['notification-1', 'notification-2'];
        final output = DeletePendingNotificationsResult(
          deletedNotificationIds: notificationIds,
        );
        sdk.stubbedResult = output;

        final request = DeletePendingNotificationsRequest(
          device: device,
          notificationIds: notificationIds,
        );
        final result = await sdk.deletePendingNotifications(request);

        expect(result, same(output));
        expect(sdk.lastCommand, same(request));
        final command = sdk.lastCommand as DeletePendingNotificationsRequest;
        expect(command.device, same(device));
        expect(command.notificationIds, same(notificationIds));
      });
    });
  });
}

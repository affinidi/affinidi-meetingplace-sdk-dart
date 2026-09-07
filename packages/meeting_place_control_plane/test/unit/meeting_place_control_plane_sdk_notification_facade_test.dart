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

        final result = await sdk.notifyAcceptance(
          mnemonic: 'coffee-chat',
          acceptOfferDid: 'did:key:accepting',
          offerLink: 'https://example.com/offers/1',
          senderInfo: 'Alice',
        );

        expect(result, same(output));
        final command = sdk.lastCommand as NotifyAcceptanceCommand;
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

        final result = await sdk.notifyGroupAcceptance(
          mnemonic: 'group-chat',
          acceptOfferDid: 'did:key:accepting',
          offerLink: 'https://example.com/group-offers/1',
          senderInfo: 'Alice',
        );

        expect(result, same(output));
        final command = sdk.lastCommand as NotifyAcceptanceGroupCommand;
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

        final result = await sdk.notifyChannel(
          notificationToken: 'notification-token',
          did: 'did:key:channel',
          type: 'channel-updated',
        );

        expect(result, same(output));
        final command = sdk.lastCommand as NotifyChannelCommand;
        expect(command.notificationToken, 'notification-token');
        expect(command.did, 'did:key:channel');
        expect(command.type, 'channel-updated');
      });
    });

    group('and notifying an outreach recipient', () {
      test('it executes the matching command and returns its result', () async {
        final output = NotifyOutreachResult(success: true);
        sdk.stubbedResult = output;

        final result = await sdk.notifyOutreach(
          mnemonic: 'outreach-offer',
          senderInfo: 'Alice',
        );

        expect(result, same(output));
        final command = sdk.lastCommand as NotifyOutreachCommand;
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

        final result = await sdk.registerNotification(
          myDid: 'did:key:alice',
          theirDid: 'did:key:bob',
          device: device,
        );

        expect(result, same(output));
        final command = sdk.lastCommand as RegisterNotificationCommand;
        expect(command.myDid, 'did:key:alice');
        expect(command.theirDid, 'did:key:bob');
        expect(command.device, same(device));
      });
    });

    group('and deregistering a notification channel', () {
      test('it executes the matching command and returns its result', () async {
        final output = DeregisterNotificationResult(success: true);
        sdk.stubbedResult = output;

        final result = await sdk.deregisterNotification(
          notificationToken: 'notification-token',
        );

        expect(result, same(output));
        final command = sdk.lastCommand as DeregisterNotificationCommand;
        expect(command.notificationToken, 'notification-token');
      });
    });

    group('and fetching pending notifications', () {
      test('it executes the matching command and returns its result', () async {
        final output = GetPendingNotificationsResult(events: const []);
        sdk.stubbedResult = output;

        final result = await sdk.getPendingNotifications(device: device);

        expect(result, same(output));
        final command = sdk.lastCommand as GetPendingNotificationsCommand;
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

        final result = await sdk.deletePendingNotifications(
          device: device,
          notificationIds: notificationIds,
        );

        expect(result, same(output));
        final command = sdk.lastCommand as DeletePendingNotificationsCommand;
        expect(command.device, same(device));
        expect(command.notificationIds, same(notificationIds));
      });
    });
  });
}

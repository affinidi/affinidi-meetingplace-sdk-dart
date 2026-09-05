import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../utils/direct_connection_fixture.dart';

void main() {
  group('onBuildAttachments over the direct connection', () {
    test("attaches Bob's onBuildAttachments result to InvitationAcceptance, "
        'received by Alice', () async {
      final attachment = Attachment(
        id: const Uuid().v4(),
        data: AttachmentData(base64: 'Ym9i'),
      );

      final fixture = await DirectConnectionFixture.create(
        bobOptions: MeetingPlaceCoreSDKOptions(
          onBuildAttachments: (channel, getDidManager) async => [attachment],
        ),
      );

      final received = <ChannelAttachmentEvent>[];
      final completer = Completer<void>();
      fixture.aliceSDK.channelAttachments.listen((event) {
        received.add(event);
        if (!completer.isCompleted) completer.complete();
      });

      final directConnectionOfferSession = await fixture
          .createDirectConnection();

      await fixture.acceptDirectConnection(
        directConnectionOfferSession.directConnectionUrl,
      );

      await DirectConnectionFixture.waitForFirstChannelFromCreate(
        directConnectionOfferSession,
      );

      await completer.future.timeout(const Duration(seconds: 10));

      expect(received, hasLength(1));
      expect(received.first.attachments, hasLength(1));
      expect(received.first.attachments.first.id, equals(attachment.id));
    });

    test("attaches Alice's onBuildAttachments result to "
        'ConnectionRequestApproval, received by Bob', () async {
      final attachment = Attachment(
        id: const Uuid().v4(),
        data: AttachmentData(base64: 'YWxpY2U='),
      );

      final fixture = await DirectConnectionFixture.create(
        aliceOptions: MeetingPlaceCoreSDKOptions(
          onBuildAttachments: (channel, getDidManager) async => [attachment],
        ),
      );

      final received = <ChannelAttachmentEvent>[];
      final completer = Completer<void>();
      fixture.bobSDK.channelAttachments.listen((event) {
        received.add(event);
        if (!completer.isCompleted) completer.complete();
      });

      final directConnectionOfferSession = await fixture
          .createDirectConnection();

      final directConnectionAcceptanceSession = await fixture
          .acceptDirectConnection(
            directConnectionOfferSession.directConnectionUrl,
          );

      await DirectConnectionFixture.waitForFirstChannelFromCreate(
        directConnectionOfferSession,
      );
      await DirectConnectionFixture.waitForFirstChannelFromAccept(
        directConnectionAcceptanceSession,
      );

      await completer.future.timeout(const Duration(seconds: 10));

      expect(received, hasLength(1));
      expect(received.first.attachments, hasLength(1));
      expect(received.first.attachments.first.id, equals(attachment.id));
    });
  });
}

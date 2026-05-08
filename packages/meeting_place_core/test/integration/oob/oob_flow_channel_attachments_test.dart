import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../utils/oob_flow_fixture.dart';

void main() {
  group('channelAttachments stream', () {
    test(
      'emits (channel, attachments) on Alice side when Bob accepts with attachments',
      () async {
        final fixture = await OobFlowFixture.create();

        final attachment = Attachment(
          id: const Uuid().v4(),
          data: AttachmentData(base64: 'dGVzdA=='),
        );

        final received = <(Channel, List<Attachment>)>[];
        final completer = Completer<void>();

        fixture.aliceSDK.channelAttachments.listen((event) {
          received.add(event);
          if (!completer.isCompleted) completer.complete();
        });

        final oobOfferSession = await fixture.createOobFlow();

        await fixture.bobSDK.acceptOobFlow(
          oobOfferSession.oobUrl,
          contactCard: OobFlowFixture.bobContactCard(),
          attachments: [attachment],
        );

        await OobFlowFixture.waitForFirstChannelFromCreate(oobOfferSession);

        await completer.future.timeout(const Duration(seconds: 10));

        expect(received, hasLength(1));
        expect(received.first.$2, hasLength(1));
        expect(received.first.$2.first.id, equals(attachment.id));
      },
    );

    test('does not emit when Bob accepts without attachments', () async {
      final fixture = await OobFlowFixture.create();

      final received = <(Channel, List<Attachment>)>[];
      fixture.aliceSDK.channelAttachments.listen(received.add);

      final oobOfferSession = await fixture.createOobFlow();

      await fixture.acceptOobFlow(oobOfferSession.oobUrl);

      await OobFlowFixture.waitForFirstChannelFromCreate(oobOfferSession);

      expect(received, isEmpty);
    });

    test('stream is done after closeChannelAttachmentsStream', () async {
      final fixture = await OobFlowFixture.create();

      final doneFuture = fixture.aliceSDK.channelAttachments
          .listen((_) {})
          .asFuture<void>();

      await fixture.aliceSDK.closeChannelAttachmentsStream();

      await expectLater(doneFuture, completes);
    });
  });
}

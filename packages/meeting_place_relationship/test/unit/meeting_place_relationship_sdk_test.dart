import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../fixtures/r_card_fixture.dart';
import '../fixtures/vrc_fixture.dart';
import '../utils/mocks.dart';

void main() {
  group('MeetingPlaceRelationshipSDK', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late StreamController<(Channel, List<Attachment>)> channelAttachmentsCtrl;

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<(Channel, List<Attachment>)>.broadcast();
      mockCoreSDK = mockCoreSDKWithAttachmentStream(channelAttachmentsCtrl);
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test(
      'incomingRCards returns the same stream instance on repeated access',
      () {
        final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
        expect(sdk.incomingRCards, same(sdk.incomingRCards));
      },
    );

    test('attachments with wrong format do not emit', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');

      final emitted = <ReceivedRCard>[];
      final sub = sdk.incomingRCards.listen(emitted.add);

      channelAttachmentsCtrl.add((
        channel,
        [makeAttachment(format: 'unknown_plugin', dataJson: '{}')],
      ));

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
    });

    test('empty attachment list does not emit', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');

      final emitted = <ReceivedRCard>[];
      final sub = sdk.incomingRCards.listen(emitted.add);

      channelAttachmentsCtrl.add((channel, []));

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
    });

    test('invalid R-Card attachment does not emit', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final channel = MockChannel();
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');

      final emitted = <ReceivedRCard>[];
      final sub = sdk.incomingRCards.listen(emitted.add);

      channelAttachmentsCtrl.add((channel, [rCardAttachment()]));

      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
    });
  });

  group('MeetingPlaceRelationshipSDK.parseRCardFromAttachments', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late StreamController<(Channel, List<Attachment>)> channelAttachmentsCtrl;

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<(Channel, List<Attachment>)>.broadcast();
      mockCoreSDK = mockCoreSDKWithAttachmentStream(channelAttachmentsCtrl);
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test('returns null for empty attachment list', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final result = await sdk.parseRCardFromAttachments(
        attachments: [],
        contactChannelDid: 'did:example:other',
      );
      expect(result, isNull);
    });

    test('returns null for wrong attachment format', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final result = await sdk.parseRCardFromAttachments(
        attachments: [makeAttachment(format: 'other_plugin', dataJson: '{}')],
        contactChannelDid: 'did:example:other',
      );
      expect(result, isNull);
    });

    test('returns null for invalid R-Card (no proof)', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final result = await sdk.parseRCardFromAttachments(
        attachments: [rCardAttachment()],
        contactChannelDid: 'did:example:other',
      );
      expect(result, isNull);
    });
  });

  group('MeetingPlaceRelationshipSDK.parseVrc', () {
    late MockMeetingPlaceCoreSDK mockCoreSDK;
    late StreamController<(Channel, List<Attachment>)> channelAttachmentsCtrl;

    setUp(() {
      channelAttachmentsCtrl =
          StreamController<(Channel, List<Attachment>)>.broadcast();
      mockCoreSDK = mockCoreSDKWithAttachmentStream(channelAttachmentsCtrl);
    });

    tearDown(() async {
      await channelAttachmentsCtrl.close();
    });

    test('returns null for empty string', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final result = await sdk.parseVrc(vcBlob: '', channelId: 'ch-1');
      expect(result, isNull);
    });

    test('returns null for non-VRC blob', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final result = await sdk.parseVrc(vcBlob: 'not-json', channelId: 'ch-1');
      expect(result, isNull);
    });

    test('returns null for VRC without proof', () async {
      final sdk = MeetingPlaceRelationshipSDK(coreSDK: mockCoreSDK);
      final result = await sdk.parseVrc(
        vcBlob: vrcBlobWithoutProof,
        channelId: 'ch-1',
      );
      expect(result, isNull);
    });
  });
}

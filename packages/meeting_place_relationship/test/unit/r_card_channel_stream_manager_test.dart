import 'dart:async';
import 'dart:convert';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_relationship/meeting_place_relationship.dart';
import 'package:meeting_place_relationship/src/rcard/parser/r_card_parser.dart';
import 'package:meeting_place_relationship/src/rcard/r_card_channel_stream_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../fixtures/r_card_fixture.dart';
import '../utils/mocks.dart';

void main() {
  late StreamController<(Channel, List<Attachment>)> channelAttachmentsCtrl;
  late MockChannel channel;

  setUp(() {
    channelAttachmentsCtrl =
        StreamController<(Channel, List<Attachment>)>.broadcast();
    channel = MockChannel();
  });

  tearDown(() async {
    await channelAttachmentsCtrl.close();
  });

  RCardChannelStreamManager makeManager() {
    return RCardChannelStreamManager(
      channelAttachments: channelAttachmentsCtrl.stream,
      parser: RCardParser(),
      logger: DefaultMeetingPlaceCoreSDKLogger(
        className: 'RCardChannelStreamManagerTest',
      ),
    );
  }

  group('RCardChannelStreamManager — null/empty channel DID', () {
    test('null otherPartyPermanentChannelDid does not emit', () async {
      when(() => channel.otherPartyPermanentChannelDid).thenReturn(null);
      final manager = makeManager();
      final emitted = <ReceivedRCard>[];
      final sub = manager.stream.listen(emitted.add);

      channelAttachmentsCtrl.add((channel, [rCardAttachment()]));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await manager.close();
    });

    test('empty otherPartyPermanentChannelDid does not emit', () async {
      when(() => channel.otherPartyPermanentChannelDid).thenReturn('');
      final manager = makeManager();
      final emitted = <ReceivedRCard>[];
      final sub = manager.stream.listen(emitted.add);

      channelAttachmentsCtrl.add((channel, [rCardAttachment()]));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await manager.close();
    });
  });

  group('RCardChannelStreamManager — attachment envelope', () {
    setUp(() {
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');
    });

    test('wrong attachment format does not emit', () async {
      final manager = makeManager();
      final emitted = <ReceivedRCard>[];
      final sub = manager.stream.listen(emitted.add);

      channelAttachmentsCtrl.add((
        channel,
        [makeAttachment(format: 'unknown_plugin', dataJson: '{}')],
      ));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await manager.close();
    });

    test('null attachment data does not emit', () async {
      final manager = makeManager();
      final emitted = <ReceivedRCard>[];
      final sub = manager.stream.listen(emitted.add);

      channelAttachmentsCtrl.add((
        channel,
        [
          makeAttachment(
            format: RCardDIDCommAttachmentBuilder.attachmentFormat,
            dataJson: null,
          ),
        ],
      ));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await manager.close();
    });

    test('non-JSON data payload does not emit', () async {
      final manager = makeManager();
      final emitted = <ReceivedRCard>[];
      final sub = manager.stream.listen(emitted.add);

      channelAttachmentsCtrl.add((
        channel,
        [rCardAttachment(overrideDataJson: 'not-json')],
      ));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await manager.close();
    });

    test('missing vcBlob key does not emit', () async {
      final manager = makeManager();
      final emitted = <ReceivedRCard>[];
      final sub = manager.stream.listen(emitted.add);

      channelAttachmentsCtrl.add((
        channel,
        [
          rCardAttachment(overrideDataJson: jsonEncode({'isUpdate': false})),
        ],
      ));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await manager.close();
    });

    test('non-string vcBlob does not emit', () async {
      final manager = makeManager();
      final emitted = <ReceivedRCard>[];
      final sub = manager.stream.listen(emitted.add);

      channelAttachmentsCtrl.add((
        channel,
        [
          rCardAttachment(
            overrideDataJson: jsonEncode({'vcBlob': 42, 'isUpdate': false}),
          ),
        ],
      ));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await manager.close();
    });

    test('empty attachment list does not emit', () async {
      final manager = makeManager();
      final emitted = <ReceivedRCard>[];
      final sub = manager.stream.listen(emitted.add);

      channelAttachmentsCtrl.add((channel, []));
      await Future<void>.delayed(Duration.zero);

      expect(emitted, isEmpty);
      await sub.cancel();
      await manager.close();
    });
  });

  group('RCardChannelStreamManager — happy path', () {
    late List<Attachment> signedAttachments;
    late String issuerDid;

    setUpAll(() async {
      final wallet = PersistentWallet(InMemoryKeyStore());
      final didManager = DidKeyManager(
        wallet: wallet,
        store: InMemoryDidStore(),
      );
      final keyPair = await wallet.generateKey();
      await didManager.addVerificationMethod(keyPair.id);
      final didDoc = await didManager.getDidDocument();
      issuerDid = didDoc.id;

      final vc = await CredentialBuilder.buildRCard(
        issuerDid: issuerDid,
        subjectDid: issuerDid,
        subject: const RCardSubject(firstName: 'Alice'),
        issuerDidManager: didManager,
      );
      signedAttachments = RCardDIDCommAttachmentBuilder.fromVcJson(vc.toJson());
    });

    setUp(() {
      when(
        () => channel.otherPartyPermanentChannelDid,
      ).thenReturn('did:example:other');
    });

    test('valid signed R-Card emits on stream', () async {
      final manager = makeManager();
      final emitted = <ReceivedRCard>[];
      final sub = manager.stream.listen(emitted.add);

      channelAttachmentsCtrl.add((channel, signedAttachments));
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(emitted, hasLength(1));
      expect(emitted.first.issuerDid, issuerDid);
      expect(emitted.first.contactChannelDid, 'did:example:other');
      await sub.cancel();
      await manager.close();
    });

    test('stream returns same instance on repeated access', () async {
      final manager = makeManager();
      expect(manager.stream, same(manager.stream));
      await manager.close();
    });

    test('close() completes without error', () async {
      final manager = makeManager();
      await expectLater(manager.close(), completes);
    });
  });
}

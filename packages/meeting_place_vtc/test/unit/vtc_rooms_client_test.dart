import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import '../utils/fake_join_vtc.dart';
import '../utils/fake_room_key_holder.dart';
import '../utils/fake_vtc.dart';
import '../utils/fakes.dart';

const _room = 'did:webvh:QmRoom:community.example:room-dids:talks';

Matcher _throwsCode(MeetingPlaceVtcSDKErrorCode code) => throwsA(
  isA<MeetingPlaceVtcSDKException>().having((e) => e.code, 'code', code),
);

Map<String, dynamic> _credential(String type, String subject) => {
  'id': 'urn:uuid:$type',
  'type': ['VerifiableCredential', type],
  'issuer': _room,
  'credentialSubject': {'id': subject},
};

Map<String, dynamic> _offer(
  String member, {
  String visibility = 'attributed',
  String state = 'open',
}) => {
  'roomId': _room,
  'host': vtcDid,
  'label': 'Talks',
  'description': 'Slides and recordings.',
  'visibility': visibility,
  'actions': ['read', 'write'],
  'offeredAt': '2026-11-09T10:00:00Z',
  'validUntil': '2027-02-07T10:00:00Z',
  'state': state,
  'credentials': {
    'invitation': jsonEncode(_credential('InvitationCredential', member)),
    'membership': jsonEncode(_credential('MembershipCredential', member)),
    'authority': jsonEncode(_credential('AuthorityCredential', member)),
  },
};

void main() {
  late FakeJoinVtc vtc;
  late FakeHttpAdapter adapter;
  late FakeRoomKeyHolder holder;

  VtcRoomsClient client() => VtcRoomsClient(
    didResolver: FakeDidResolver({vtcDid: vtc.didDocument}),
    transport: TrustTaskHttpTransport(dio: Dio()..httpClientAdapter = adapter),
  );

  setUp(() {
    adapter = FakeHttpAdapter();
    vtc = FakeJoinVtc();
    adapter.handler = vtc.handle;
    holder = FakeRoomKeyHolder();
  });

  group('VtcRoomsClient.offers', () {
    test('lists offers and renewals, asked as the member', () async {
      final member = holder.member.did;
      vtc.answerTo[RoomTask.offersList] = (payload) => payload['cursor'] == null
          ? {
              'items': [_offer(member)],
              'nextCursor': 'page-2',
              'renewals': [
                {
                  ..._offer(member)..remove('credentials'),
                  'issuedAt': '2026-11-09T10:00:00Z',
                  'renewsAt': '2026-11-20T10:00:00Z',
                  'credentials': {
                    'membership': jsonEncode(
                      _credential('MembershipCredential', member),
                    ),
                    'authority': jsonEncode(
                      _credential('AuthorityCredential', member),
                    ),
                  },
                },
              ],
            }
          : {
              'items': [_offer(member, state: 'accepted')],
            };

      final offers = await client().offers(
        vtcDid,
        holder: holder,
        memberDid: member,
      );

      expect(vtc.received, hasLength(2));
      final request = vtc.received.first;
      expect(request['type'], RoomTask.offersList);
      expect(request['issuer'], member);
      expect(request['recipient'], vtcDid);
      expect(request['proof'], isNotNull);
      expect(holder.acted, hasLength(2));

      expect(offers.offers, hasLength(2));
      expect(offers.open, hasLength(1));
      final offer = offers.open.single;
      expect(offer.label, 'Talks');
      expect(offer.visibility, RoomVisibility.attributed);
      expect(offer.actions, {RoomAction.read, RoomAction.write});
      expect(offer.canWrite, isTrue);
      expect(offer.membership['type'], contains('MembershipCredential'));
      expect(offers.renewals.single.renewsAt, DateTime.utc(2026, 11, 20, 10));
    });

    test('refuses a document the VTA changed', () async {
      holder.tamper = true;
      vtc.answerTo[RoomTask.offersList] = (_) => {'items': <Object>[]};

      await expectLater(
        client().offers(vtcDid, holder: holder, memberDid: holder.member.did),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
      expect(vtc.received, isEmpty);
    });
  });

  group('VtcRoomsClient.accept', () {
    RoomOffer offerFor(String visibility) => RoomOffer(
      roomId: _room,
      host: vtcDid,
      label: 'Talks',
      visibility: RoomVisibility.parse(visibility)!,
      actions: const {RoomAction.read},
      validUntil: DateTime.utc(2027),
      offeredAt: DateTime.utc(2026, 11, 9),
      isOpen: true,
      invitation: 'invitation-vic',
      membership: _credential('MembershipCredential', holder.member.did),
      authority: _credential('AuthorityCredential', holder.member.did),
    );

    test('joins a sealed room with a key package and the Welcome', () async {
      vtc.answerTo[RoomTask.offersAccept] = (payload) => {
        'roomId': payload['roomId'],
        'state': 'admitted',
        'epoch': 3,
        'welcome': 'welcome-1',
        'ratchetTree': 'tree-1',
      };

      final acceptance = await client().accept(
        vtcDid,
        holder: holder,
        member: holder.member,
        offer: offerFor('attributed'),
      );

      expect(holder.kept.map((k) => k.$2), ['members', 'members']);
      expect(holder.kept.map((k) => k.$3), [null, null]);
      expect(holder.keyPackagesMinted.single, (_room, 'invitation-vic'));
      expect(vtc.received.single['payload'], {
        'roomId': _room,
        'keyPackage': 'kp-$_room',
      });
      expect(holder.welcomes.single, {
        'roomId': _room,
        'invitation': 'invitation-vic',
        'welcome': 'welcome-1',
        'ratchetTree': 'tree-1',
      });
      expect(acceptance.epoch, 3);
      expect(acceptance.alreadyJoined, isFalse);
    });

    test('asks nothing more of a room the VTA already joined', () async {
      holder.held.add(HeldRoom(roomId: _room, member: holder.member.did));

      final acceptance = await client().accept(
        vtcDid,
        holder: holder,
        member: holder.member,
        offer: offerFor('attributed'),
      );

      expect(acceptance.alreadyJoined, isTrue);
      expect(vtc.received, isEmpty);
      expect(holder.keyPackagesMinted, isEmpty);
    });

    test('takes a Welcome another surface delivered first', () async {
      holder.refuseWelcomeWith = 'alreadyJoined';
      vtc.answerTo[RoomTask.offersAccept] = (_) => {
        'roomId': _room,
        'state': 'admitted',
        'epoch': 3,
        'welcome': 'welcome-1',
      };

      final acceptance = await client().accept(
        vtcDid,
        holder: holder,
        member: holder.member,
        offer: offerFor('attributed'),
      );

      expect(acceptance.alreadyJoined, isTrue);
    });

    test('accepts an open room without a key package', () async {
      vtc.answerTo[RoomTask.offersAccept] = (_) => {
        'roomId': _room,
        'state': 'admitted',
        'epoch': 1,
      };

      final acceptance = await client().accept(
        vtcDid,
        holder: holder,
        member: holder.member,
        offer: offerFor('open'),
      );

      expect(vtc.received.single['payload'], {'roomId': _room});
      expect(holder.keyPackagesMinted, isEmpty);
      expect(holder.welcomes, isEmpty);
      expect(acceptance.epoch, 1);
    });

    test('refuses a sealed admission without a Welcome', () async {
      vtc.answerTo[RoomTask.offersAccept] = (_) => {
        'roomId': _room,
        'state': 'admitted',
        'epoch': 3,
      };

      await expectLater(
        client().accept(
          vtcDid,
          holder: holder,
          member: holder.member,
          offer: offerFor('attributed'),
        ),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('passes on the community refusing the offer', () async {
      vtc.refusal = {'code': 'vtc/rooms/offers/accept:offerExpired'};

      await expectLater(
        client().accept(
          vtcDid,
          holder: holder,
          member: holder.member,
          offer: offerFor('attributed'),
        ),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.refusalCode,
            'refusalCode',
            'vtc/rooms/offers/accept:offerExpired',
          ),
        ),
      );
      expect(holder.welcomes, isEmpty);
    });
  });

  group('VtcRoomsClient.write', () {
    Future<RoomWrite> write(RoomVisibility visibility) => client().write(
      vtcDid,
      holder: holder,
      memberDid: holder.member.did,
      roomId: _room,
      visibility: visibility,
      title: 'Opening keynote',
      body: 'Welcome to DevCon 2026',
    );

    test(
      'seals a sealed room record as the member at the next version',
      () async {
        vtc.answerTo[RoomTask.recordsList] = (_) => {
          'records': <Object>[],
          'headVersion': 4,
        };
        vtc.answerTo[RoomTask.recordsPut] = (payload) => {
          'key': payload['key'],
          'version': 5,
        };

        final written = await write(RoomVisibility.attributed);

        expect(written.version, 5);
        final body = holder.sealedBodies.single;
        expect(body['author'], holder.member.did);
        expect(body['roomId'], _room);
        expect(body['key'], written.key);
        expect(body['version'], 5);
        expect(body['title'], 'Opening keynote');
        expect(body.containsKey('proof'), isFalse);

        final put = vtc.received.last;
        expect(put['type'], RoomTask.recordsPut);
        expect(put['issuer'], holder.member.did);
        expect(put['recipient'], vtcDid);
        final payload = put['payload'] as Map<String, dynamic>;
        expect(payload['sealed'], {
          'ciphertext': 'ct-5',
          'nonce': 'n',
          'epoch': 1,
        });
        expect(payload['presentation'], isNotNull);
        expect(payload.containsKey('cleartext'), isFalse);
      },
    );

    test('seals again for the version the host gave', () async {
      vtc.answerTo[RoomTask.recordsList] = (_) => {
        'records': <Object>[],
        'headVersion': 4,
      };
      var puts = 0;
      vtc.answerTo[RoomTask.recordsPut] = (payload) => {
        'key': payload['key'],
        'version': puts++ == 0 ? 6 : 7,
      };

      final written = await write(RoomVisibility.attributed);

      expect(written.version, 7);
      expect(holder.sealedBodies.map((b) => b['version']), [5, 7]);
      final retry = vtc.received.last['payload'] as Map<String, dynamic>;
      expect(retry['expectedVersion'], 6);
    });

    test('writes an open room record in the clear', () async {
      vtc.answerTo[RoomTask.recordsPut] = (payload) => {
        'key': payload['key'],
        'version': 1,
      };

      await write(RoomVisibility.open);

      expect(holder.sealedBodies, isEmpty);
      final payload = vtc.received.single['payload'] as Map<String, dynamic>;
      expect(payload['cleartext'], {
        'title': 'Opening keynote',
        'body': 'Welcome to DevCon 2026',
      });
    });

    test('passes on the VTA refusing a member who may only read', () async {
      holder.refuseActWith = 'rooms/keys/act:actionNotHeld';

      await expectLater(
        write(RoomVisibility.open),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.refusalCode,
            'refusalCode',
            'rooms/keys/act:actionNotHeld',
          ),
        ),
      );
      expect(vtc.received, isEmpty);
    });

    test('refuses a host request the VTA changed', () async {
      holder.tamper = true;

      await expectLater(
        write(RoomVisibility.open),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
      expect(vtc.received, isEmpty);
    });
  });

  group('VtcRoomsClient.collectRenewal', () {
    RoomRenewal renewal() => RoomRenewal(
      roomId: _room,
      host: vtcDid,
      label: 'Talks',
      visibility: RoomVisibility.attributed,
      actions: const {RoomAction.read},
      validUntil: DateTime.utc(2027, 3),
      renewsAt: DateTime.utc(2027, 2),
      membership: _credential('MembershipCredential', holder.member.did),
      authority: _credential('AuthorityCredential', holder.member.did),
    );

    test('keeps each renewed credential in place of the old one', () async {
      holder.stored['MembershipCredential'] = [
        const HeldCredential(id: 'old-vmc', types: ['MembershipCredential']),
      ];
      holder.stored['AuthorityCredential'] = [
        const HeldCredential(id: 'old-vac', types: ['AuthorityCredential']),
      ];

      await client().collectRenewal(
        renewal(),
        holder: holder,
        member: holder.member,
      );

      expect(holder.kept.map((k) => k.$3), ['old-vmc', 'old-vac']);
    });

    test('refuses to pick between two held memberships', () async {
      holder.stored['MembershipCredential'] = [
        const HeldCredential(id: 'a', types: ['MembershipCredential']),
        const HeldCredential(id: 'b', types: ['MembershipCredential']),
      ];

      await expectLater(
        client().collectRenewal(
          renewal(),
          holder: holder,
          member: holder.member,
        ),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
      expect(holder.kept, isEmpty);
    });
  });

  group('VtcRoomsClient.memberships', () {
    test('reads states, and closes writing in an archived room', () async {
      Map<String, dynamic> membership(
        String state,
        String roomState, {
        String? access,
      }) => {
        ..._offer(holder.member.did)
          ..remove('credentials')
          ..remove('state'),
        'state': state,
        'roomState': roomState,
        'roomAccess': ?access,
      };
      vtc.answerTo[RoomTask.membershipsList] = (_) => {
        'items': [
          membership('admitted', 'active'),
          membership('admitted', 'archived', access: 'readOnly'),
          membership('removed', 'purging', access: 'noAccess'),
        ],
      };

      final memberships = await client().memberships(
        vtcDid,
        holder: holder,
        memberDid: holder.member.did,
      );

      final [active, archived, removed] = memberships;
      expect(active.canRead, isTrue);
      expect(active.canWrite, isTrue);
      expect(archived.canRead, isTrue);
      expect(archived.canWrite, isFalse);
      expect(removed.roomState, RoomState.removalScheduled);
      expect(removed.canRead, isFalse);
    });
  });

  group('VtcRoomsClient.records', () {
    test('lists records without their content', () async {
      holder.browsed = {
        'roomId': _room,
        'complete': true,
        'records': [
          {
            'key': 'k1',
            'version': 4,
            'status': 'deprecated',
            'updatedAt': '2026-11-09T10:00:00Z',
            'author': 'did:key:z6Mkauthor',
            'epoch': 2,
          },
        ],
        'verification': {'priorRoots': 'noneHeld'},
      };

      final records = await client().records(
        holder: holder,
        roomId: _room,
        host: vtcDid,
      );

      final record = records.records.single;
      expect(records.complete, isTrue);
      expect(record.key, 'k1');
      expect(record.status, RoomRecordStatus.deprecated);
      expect(record.title, isNull);
    });
  });

  group('VtcRoomsClient.record', () {
    final author = Ed25519DidKeySigner.generate();

    Future<String> sealedBody({
      String key = 'k1',
      int version = 4,
      Map<String, dynamic> extra = const {},
      Ed25519DidKeySigner? signer,
    }) async {
      final signed = await EddsaJcs2022.sign(
        {
          'roomId': _room,
          'key': key,
          'version': version,
          'author': author.did,
          'title': 'Opening keynote',
          'body': 'The slides.',
          'tags': ['keynote'],
          'file': {
            'fileId': 'f1',
            'name': 'keynote.pdf',
            'mediaType': 'application/pdf',
            'size': 1024,
            'digest': 'zDigest',
            'epoch': 2,
            'segmentSize': 262128,
            'blobRef': 'zBlob',
          },
          ...extra,
        },
        signer: signer ?? author,
        purpose: ProofPurpose.assertionMethod,
      );
      return base64Url.encode(utf8.encode(jsonEncode(signed)));
    }

    Map<String, dynamic> readAnswer(
      String plaintext, {
      int version = 4,
      Map<String, dynamic>? ext,
      String? hostAuthor,
    }) => {
      'roomId': _room,
      'key': 'k1',
      'version': version,
      'status': 'active',
      'updatedAt': '2026-11-09T10:00:00Z',
      'author': hostAuthor ?? author.did,
      'plaintext': plaintext,
      'verification': {'priorRoots': 'noneHeld'},
      'ext': ?ext,
    };

    Future<RoomRecord?> read() =>
        client().record(holder: holder, roomId: _room, host: vtcDid, key: 'k1');

    test('opens a sealed record its author signed', () async {
      holder.read = readAnswer(await sealedBody());

      final record = await read();

      expect(record!.title, 'Opening keynote');
      expect(record.author, author.did);
      expect(record.tags, ['keynote']);
      expect(record.file!.name, 'keynote.pdf');
      expect(record.file!.epoch, 2);
    });

    test('checks a curated record where its body was sealed', () async {
      holder.read = readAnswer(
        await sealedBody(version: 3),
        version: 5,
        ext: {
          VtcRoomsClient.memberExt: {'sealedAt': 3},
        },
      );

      expect((await read())!.version, 5);
    });

    test('refuses a body moved to another record', () async {
      holder.read = readAnswer(await sealedBody(key: 'k2'));

      await expectLater(
        read(),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a body moved to a later version', () async {
      holder.read = readAnswer(await sealedBody(version: 3), version: 4);

      await expectLater(
        read(),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses an altered body', () async {
      final signed =
          jsonDecode(utf8.decode(base64Url.decode(await sealedBody())))
              as Map<String, dynamic>;
      signed['title'] = 'Something else';
      holder.read = readAnswer(
        base64Url.encode(utf8.encode(jsonEncode(signed))),
      );

      await expectLater(
        read(),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidProof),
      );
    });

    test('refuses a body signed by someone other than its author', () async {
      holder.read = readAnswer(
        await sealedBody(signer: Ed25519DidKeySigner.generate()),
      );

      await expectLater(
        read(),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidProof),
      );
    });

    test('refuses a body the host attributes to another member', () async {
      holder.read = readAnswer(
        await sealedBody(),
        hostAuthor: Ed25519DidKeySigner.generate().did,
      );

      await expectLater(
        read(),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('refuses a body carrying unknown members', () async {
      holder.read = readAnswer(
        await sealedBody(extra: {'comment': 'smuggled'}),
      );

      await expectLater(
        read(),
        _throwsCode(MeetingPlaceVtcSDKErrorCode.invalidDocument),
      );
    });

    test('skips the room profile', () async {
      holder.read = {
        ...readAnswer('')..remove('plaintext'),
        'ext': {
          VtcRoomsClient.memberExt: {'roomProfile': true},
        },
      };

      expect(await read(), isNull);
    });

    test('reads an open room record as itself', () async {
      holder.read = {
        ...readAnswer('')..remove('plaintext'),
        'cleartext': {'title': 'Agenda', 'body': 'Day one.'},
      };

      final record = await read();

      expect(record!.title, 'Agenda');
      expect(record.author, author.did);
    });
  });
}

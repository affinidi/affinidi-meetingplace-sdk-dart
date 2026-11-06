import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

const _groupDid = 'did:webvh:QmGroup:vtc.example:group-dids:g1';
const _controlPlaneDid = 'did:web:control-plane.example';

DidDocument _document(List<Map<String, dynamic>> services) =>
    DidDocument.fromJson({
      '@context': ['https://www.w3.org/ns/did/v1'],
      'id': _groupDid,
      'service': services,
    });

void main() {
  group('GroupChatLink', () {
    test('reads the link the service publishes, as it was written', () {
      const link = GroupChatLink(
        mnemonic: 'identity-wg',
        controlPlaneDid: _controlPlaneDid,
      );

      final read = GroupChatLink.fromDidDocument(
        _document([link.toService(_groupDid)]),
      );

      expect(read!.mnemonic, 'identity-wg');
      expect(read.controlPlaneDid, _controlPlaneDid);
      expect(link.toService(_groupDid)['id'], '$_groupDid#meeting-place');
    });

    test('reads who may post, as the community set it', () {
      const link = GroupChatLink(
        mnemonic: 'announcements',
        controlPlaneDid: _controlPlaneDid,
        posting: GroupChatPosting.managers,
      );

      final read = GroupChatLink.fromDidDocument(
        _document([link.toService(_groupDid)]),
      );

      expect(read!.posting, GroupChatPosting.managers);
    });

    test('lets everyone post in a chat linked without a rule', () {
      final read = GroupChatLink.fromDidDocument(
        _document([
          {
            'id': '$_groupDid#meeting-place',
            'type': meetingPlaceGroupServiceType,
            'serviceEndpoint': {
              'uri': _controlPlaneDid,
              'mnemonic': 'book club',
            },
          },
        ]),
      );

      expect(read!.posting, GroupChatPosting.everyone);
    });

    test('reads a rule it does not know as managers only', () {
      final read = GroupChatLink.fromDidDocument(
        _document([
          {
            'id': '$_groupDid#meeting-place',
            'type': meetingPlaceGroupServiceType,
            'serviceEndpoint': {
              'uri': _controlPlaneDid,
              'mnemonic': 'board',
              'post': 'chairs',
            },
          },
        ]),
      );

      expect(read!.posting, GroupChatPosting.managers);
    });

    test('finds no link in a document without the service', () {
      expect(
        GroupChatLink.fromDidDocument(
          _document([
            {
              'id': '$_groupDid#didcomm',
              'type': 'DIDCommMessaging',
              'serviceEndpoint': {'uri': 'did:peer:2.mediator'},
            },
          ]),
        ),
        isNull,
      );
    });

    test('skips a service that names no phrase', () {
      expect(
        GroupChatLink.fromDidDocument(
          _document([
            {
              'id': '$_groupDid#meeting-place',
              'type': meetingPlaceGroupServiceType,
              'serviceEndpoint': {'uri': _controlPlaneDid},
            },
          ]),
        ),
        isNull,
      );
    });
  });
}

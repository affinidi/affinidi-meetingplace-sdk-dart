import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:meeting_place_core/src/service/connection_manager/connection_manager.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_acl_exception.dart';
import 'package:meeting_place_core/src/service/mediator/mediator_acl_service.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'fixtures/contact_card_fixture.dart';

// Mock classes
class MockMeetingPlaceMediatorSDK extends Mock
    implements MeetingPlaceMediatorSDK {}

class MockConnectionManager extends Mock implements ConnectionManager {}

class MockMeetingPlaceCoreSDKLogger extends Mock
    implements MeetingPlaceCoreSDKLogger {}

class MockWallet extends Mock implements Wallet {}

class MockDidManager extends Mock implements DidManager {}

class MockDidDocument extends Mock implements DidDocument {}

class MockAccessListRemove extends Mock implements AccessListRemove {}

void main() {
  late MockMeetingPlaceMediatorSDK mockMediatorSDK;
  late MockConnectionManager mockConnectionManager;
  late MockMeetingPlaceCoreSDKLogger mockLogger;
  late MediatorAclService service;

  const permanentChannelDid = 'did:example:permanent';
  const otherPartyPermanentChannelDid = 'did:example:otherparty';
  const mediatorDid = 'did:example:mediator';

  setUp(() {
    mockMediatorSDK = MockMeetingPlaceMediatorSDK();
    mockConnectionManager = MockConnectionManager();
    mockLogger = MockMeetingPlaceCoreSDKLogger();

    service = MediatorAclService(
      mediatorSDK: mockMediatorSDK,
      connectionManager: mockConnectionManager,
      logger: mockLogger,
    );

    // Register fallback values
    registerFallbackValue(MockWallet());
    registerFallbackValue(MockDidManager());
    registerFallbackValue(
      AccessListRemove(
        ownerDid: permanentChannelDid,
        granteeDids: const [otherPartyPermanentChannelDid],
      ),
    );
  });

  group('removePermissionFromChannel', () {
    late MockWallet mockWallet;
    late MockDidManager mockDidManager;
    late Channel channel;

    setUp(() {
      mockWallet = MockWallet();
      mockDidManager = MockDidManager();

      channel = Channel(
        offerLink: 'test-offer',
        publishOfferDid: 'did:example:publish',
        mediatorDid: mediatorDid,
        permanentChannelDid: permanentChannelDid,
        otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
        status: ChannelStatus.approved,
        contactCard: ContactCardFixture.getContactCardFixture(
          did: 'did:test',
          contactInfo: const {},
        ),
        type: ChannelType.individual,
      );
    });

    // Helper methods
    void stubGetDidManagerForDid() {
      when(
        () => mockConnectionManager.getDidManagerForDid(
          mockWallet,
          permanentChannelDid,
        ),
      ).thenAnswer((_) async => mockDidManager);
    }

    void stubUpdateAclSuccess() {
      when(
        () => mockMediatorSDK.updateAcl(
          ownerDidManager: any(named: 'ownerDidManager'),
          acl: any(named: 'acl'),
          mediatorDid: any(named: 'mediatorDid'),
        ),
      ).thenAnswer((_) async => {});
    }

    void stubUpdateAclThrows(Object exception) {
      when(
        () => mockMediatorSDK.updateAcl(
          ownerDidManager: any(named: 'ownerDidManager'),
          acl: any(named: 'acl'),
          mediatorDid: any(named: 'mediatorDid'),
        ),
      ).thenThrow(exception);
    }

    void verifyGetDidManagerForDidNeverCalled() {
      verifyNever(
        () => mockConnectionManager.getDidManagerForDid(any(), any()),
      );
    }

    void verifyUpdateAclNeverCalled() {
      verifyNever(
        () => mockMediatorSDK.updateAcl(
          ownerDidManager: any(named: 'ownerDidManager'),
          mediatorDid: any(named: 'mediatorDid'),
          acl: any(named: 'acl'),
        ),
      );
    }

    Channel createChannelWithoutDids({
      String? permanentDid,
      String? otherPartyDid,
    }) {
      return Channel(
        offerLink: 'test-offer',
        publishOfferDid: 'did:example:publish',
        mediatorDid: mediatorDid,
        permanentChannelDid: permanentDid,
        otherPartyPermanentChannelDid: otherPartyDid,
        status: ChannelStatus.approved,
        contactCard: ContactCardFixture.getContactCardFixture(
          did: 'did:test',
          contactInfo: const {},
        ),
        type: ChannelType.individual,
      );
    }

    Matcher throwsMediatorAclException() {
      return throwsA(
        isA<MediatorAclException>().having(
          (e) => e.code.value,
          'code',
          'mediator_acl_missing_channel_dids',
        ),
      );
    }

    test('successfully removes permission from channel', () async {
      stubGetDidManagerForDid();
      stubUpdateAclSuccess();

      await service.removePermissionFromChannel(
        wallet: mockWallet,
        channel: channel,
      );

      final captured = verify(
        () => mockMediatorSDK.updateAcl(
          ownerDidManager: captureAny(named: 'ownerDidManager'),
          acl: captureAny(named: 'acl'),
          mediatorDid: captureAny(named: 'mediatorDid'),
        ),
      ).captured;

      expect(captured[0], isA<DidManager>());
      final capturedAcl = captured[1] as AccessListRemove;

      final expectedOwnerDidHash = sha256
          .convert(utf8.encode(permanentChannelDid))
          .toString();
      final expectedGranteeDidHash = sha256
          .convert(utf8.encode(otherPartyPermanentChannelDid))
          .toString();

      expect(capturedAcl.ownerDid, expectedOwnerDidHash);
      expect(capturedAcl.granteeDids, [expectedGranteeDidHash]);
      expect(captured[2], mediatorDid);
    });

    test(
      'throws MediatorAclException when permanentChannelDid is null',
      () async {
        final channelWithoutPermanentDid = createChannelWithoutDids(
          otherPartyDid: otherPartyPermanentChannelDid,
        );

        expect(
          () => service.removePermissionFromChannel(
            wallet: mockWallet,
            channel: channelWithoutPermanentDid,
          ),
          throwsMediatorAclException(),
        );

        verifyGetDidManagerForDidNeverCalled();
        verifyUpdateAclNeverCalled();
      },
    );

    test(
      'throws MediatorAclException when otherPartyPermanentChannelDid is null',
      () async {
        final channelWithoutOtherPartyDid = createChannelWithoutDids(
          permanentDid: permanentChannelDid,
        );

        expect(
          () => service.removePermissionFromChannel(
            wallet: mockWallet,
            channel: channelWithoutOtherPartyDid,
          ),
          throwsMediatorAclException(),
        );

        verifyGetDidManagerForDidNeverCalled();
        verifyUpdateAclNeverCalled();
      },
    );

    test(
      'throws MediatorAclException when both permanent DIDs are null',
      () async {
        final channelWithoutDids = createChannelWithoutDids();

        expect(
          () => service.removePermissionFromChannel(
            wallet: mockWallet,
            channel: channelWithoutDids,
          ),
          throwsMediatorAclException(),
        );

        verifyGetDidManagerForDidNeverCalled();
        verifyUpdateAclNeverCalled();
      },
    );

    test(
      'continues without throwing when updateAcl throws invalid did:web error',
      () async {
        stubGetDidManagerForDid();

        final ssiException = SsiException(
          code: SsiExceptionType.invalidDidWeb.code,
          message: 'Invalid did:web',
        );

        stubUpdateAclThrows(
          MeetingPlaceMediatorSDKException(
            message: 'Mediator error',
            code: 'invalid_did_web',
            innerException: ssiException,
          ),
        );

        await service.removePermissionFromChannel(
          wallet: mockWallet,
          channel: channel,
        );

        verify(
          () => mockLogger.error(
            any(),
            error: any(named: 'error'),
            name: any(named: 'name'),
          ),
        ).called(1);
      },
    );

    test(
      'rethrows MeetingPlaceMediatorSDKException when it is not an invalid did:web error',
      () async {
        stubGetDidManagerForDid();

        final ssiException = SsiException(
          code: 'other_error',
          message: 'Some other error',
        );

        stubUpdateAclThrows(
          MeetingPlaceMediatorSDKException(
            message: 'Mediator error',
            code: 'other_error',
            innerException: ssiException,
          ),
        );

        await expectLater(
          service.removePermissionFromChannel(
            wallet: mockWallet,
            channel: channel,
          ),
          throwsA(isA<MeetingPlaceMediatorSDKException>()),
        );
      },
    );

    test(
      'rethrows MeetingPlaceMediatorSDKException when innerException is not SsiException',
      () async {
        stubGetDidManagerForDid();

        stubUpdateAclThrows(
          MeetingPlaceMediatorSDKException(
            message: 'Mediator error',
            code: 'generic_error',
            innerException: Exception('Some other exception'),
          ),
        );

        await expectLater(
          service.removePermissionFromChannel(
            wallet: mockWallet,
            channel: channel,
          ),
          throwsA(isA<MeetingPlaceMediatorSDKException>()),
        );
      },
    );

    test('rethrows generic exceptions from updateAcl', () async {
      stubGetDidManagerForDid();
      stubUpdateAclThrows(Exception('Generic error'));

      await expectLater(
        service.removePermissionFromChannel(
          wallet: mockWallet,
          channel: channel,
        ),
        throwsException,
      );
    });
  });

  group('toPublic', () {
    late MockDidManager mockDidManager;
    late MockDidDocument mockDidDocument;
    const ownerDid = 'did:example:owner';

    setUp(() {
      mockDidManager = MockDidManager();
      mockDidDocument = MockDidDocument();

      when(() => mockDidDocument.id).thenReturn(ownerDid);
      when(
        () => mockDidManager.getDidDocument(),
      ).thenAnswer((_) async => mockDidDocument);
    });

    void stubUpdateAclSuccess() {
      when(
        () => mockMediatorSDK.updateAcl(
          ownerDidManager: any(named: 'ownerDidManager'),
          acl: any(named: 'acl'),
          mediatorDid: any(named: 'mediatorDid'),
        ),
      ).thenAnswer((_) async => {});
    }

    test('successfully sets ACL to public', () async {
      stubUpdateAclSuccess();

      await service.toPublic(
        didManager: mockDidManager,
        mediatorDid: mediatorDid,
      );

      verify(() => mockDidManager.getDidDocument()).called(1);

      final captured = verify(
        () => mockMediatorSDK.updateAcl(
          ownerDidManager: captureAny(named: 'ownerDidManager'),
          acl: captureAny(named: 'acl'),
          mediatorDid: captureAny(named: 'mediatorDid'),
        ),
      ).captured;

      expect(captured[0], mockDidManager);
      final capturedAcl = captured[1] as AclSet;

      final expectedOwnerDidHash = sha256
          .convert(utf8.encode(ownerDid))
          .toString();

      expect(capturedAcl.ownerDid, expectedOwnerDidHash);
      expect(capturedAcl.acls, AclSet.publicAclFlag);
      expect(captured[2], mediatorDid);
    });
  });

  group('addToAcl', () {
    late MockDidManager mockDidManager;
    late MockDidDocument mockDidDocument;
    const ownerDid = 'did:example:owner';
    const grantee1 = 'did:example:grantee1';
    const grantee2 = 'did:example:grantee2';
    final granteeDids = [grantee1, grantee2];

    setUp(() {
      mockDidManager = MockDidManager();
      mockDidDocument = MockDidDocument();

      when(() => mockDidDocument.id).thenReturn(ownerDid);
      when(
        () => mockDidManager.getDidDocument(),
      ).thenAnswer((_) async => mockDidDocument);
    });

    void stubUpdateAclSuccess() {
      when(
        () => mockMediatorSDK.updateAcl(
          ownerDidManager: any(named: 'ownerDidManager'),
          acl: any(named: 'acl'),
          mediatorDid: any(named: 'mediatorDid'),
        ),
      ).thenAnswer((_) async => {});
    }

    test('successfully adds DIDs to ACL', () async {
      stubUpdateAclSuccess();

      await service.addToAcl(
        didManager: mockDidManager,
        mediatorDid: mediatorDid,
        granteeDids: granteeDids,
      );

      verify(() => mockDidManager.getDidDocument()).called(1);

      final captured = verify(
        () => mockMediatorSDK.updateAcl(
          ownerDidManager: captureAny(named: 'ownerDidManager'),
          acl: captureAny(named: 'acl'),
          mediatorDid: captureAny(named: 'mediatorDid'),
        ),
      ).captured;

      expect(captured[0], mockDidManager);
      final capturedAcl = captured[1] as AccessListAdd;

      final expectedOwnerDidHash = sha256
          .convert(utf8.encode(ownerDid))
          .toString();
      final expectedGrantee1Hash = sha256
          .convert(utf8.encode(grantee1))
          .toString();
      final expectedGrantee2Hash = sha256
          .convert(utf8.encode(grantee2))
          .toString();

      expect(capturedAcl.ownerDid, expectedOwnerDidHash);
      expect(capturedAcl.granteeDids, [
        expectedGrantee1Hash,
        expectedGrantee2Hash,
      ]);
      expect(captured[2], mediatorDid);
    });
  });
}

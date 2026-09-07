import 'dart:async';
import 'dart:io';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

import 'mocks.dart';

class _MockDidManager extends Mock implements DidManager {}

class _MockDidResolver extends Mock implements DidResolver {}

DidDocument _didDocument(String did, Uri apiBaseUri) => DidDocument.fromJson({
  '@context': ['https://www.w3.org/ns/did/v1'],
  'id': did,
  'verificationMethod': const <Object>[],
  'authentication': const <Object>[],
  'service': [
    {
      'id': '$did#control-plane',
      'type': 'RestAPI',
      'serviceEndpoint': apiBaseUri.toString(),
    },
  ],
});

/// Polls [condition] until it's true, failing the test if [timeout] elapses
/// first. Used to observe the state of a real loopback connection without
/// relying on a fixed delay.
Future<void> _waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late MeetingPlaceControlPlaneSDK sdk;

  setUp(() {
    sdk = MeetingPlaceControlPlaneSDK(
      didManager: _MockDidManager(),
      controlPlaneDid: 'did:web:123456789abcdefghi',
      mediatorDid: 'did:web:mediator',
      didResolver: _MockDidResolver(),
    );
  });

  group('MeetingPlaceControlPlaneSDK.device', () {
    test('throws MeetingPlaceControlPlaneSDKException with missingDevice code '
        'when no device has been set', () {
      expect(
        () => sdk.device,
        throwsA(
          isA<MeetingPlaceControlPlaneSDKException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceControlPlaneSDKErrorCode.missingDevice.value,
          ),
        ),
      );
    });

    test('returns the device once one has been set', () {
      final device = Device(
        deviceToken: 'token',
        platformType: PlatformType.pushNotification,
      );

      sdk.device = device;

      expect(sdk.device, same(device));
    });
  });

  group('MeetingPlaceControlPlaneSDK.dispose', () {
    test('closes the underlying HTTP connection even when initialization '
        'fails after the API client was constructed, e.g. an authentication '
        'failure', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      });

      const controlPlaneDid = 'did:web:example.com';
      final apiBaseUri = Uri.parse(
        'http://${server.address.address}:${server.port}/v1',
      );

      final didManager = _MockDidManager();
      when(
        didManager.getDidDocument,
      ).thenAnswer((_) async => DidDocument.create(id: 'did:key:test-sender'));

      final failingSdk = MeetingPlaceControlPlaneSDK(
        didManager: didManager,
        controlPlaneDid: controlPlaneDid,
        mediatorDid: 'did:web:mediator',
        didResolver: FakeDidResolver({
          controlPlaneDid: _didDocument(controlPlaneDid, apiBaseUri),
        }),
      );

      await expectLater(
        failingSdk.execute(
          AuthenticateCommand(controlPlaneDid: controlPlaneDid),
        ),
        throwsA(isA<MeetingPlaceControlPlaneSDKException>()),
      );
      expect(failingSdk.isInitialized, isFalse);

      // The failed authentication attempt above went over a real
      // connection to the control plane.
      await _waitUntil(() => server.connectionsInfo().total > 0);

      await failingSdk.dispose();

      // dispose() must close the HTTP client it already constructed, even
      // though init never reached isInitialized = true, otherwise the
      // connection above leaks.
      await _waitUntil(() => server.connectionsInfo().total == 0);
    });
  });
}

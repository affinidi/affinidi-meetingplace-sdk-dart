import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/api/control_plane_api_client.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';

class MockDidResolver extends Mock implements DidResolver {}

class MockControlPlaneSDKLogger extends Mock implements ControlPlaneSDKLogger {}

class MockControlPlaneApiClient extends Mock implements ControlPlaneApiClient {}

class MockControlPlaneSDK extends Mock implements ControlPlaneSDK {}

class FakeAuthenticateCommand extends Fake implements AuthenticateCommand {}

class FakeDidResolver implements DidResolver {
  FakeDidResolver(this._documents);

  final Map<String, DidDocument> _documents;

  @override
  Future<DidDocument> resolveDid(String did) async {
    final document = _documents[did];
    if (document == null) {
      throw Exception('Missing DID document for $did');
    }
    return document;
  }
}

DidDocument didDocumentFixture(String did) => DidDocument.fromJson({
  '@context': ['https://www.w3.org/ns/did/v1'],
  'id': did,
  'verificationMethod': const <Object>[],
  'authentication': const <Object>[],
});

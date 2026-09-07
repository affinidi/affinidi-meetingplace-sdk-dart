import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/api/did_web_document_api.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';

class MockMeetingPlaceControlPlaneSDKLogger extends Mock
    implements MeetingPlaceControlPlaneSDKLogger {}

class MockDidWebDocumentApi extends Mock implements DidWebDocumentApi {}

class MockMeetingPlaceControlPlaneSDK extends Mock
    implements MeetingPlaceControlPlaneSDK {}

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

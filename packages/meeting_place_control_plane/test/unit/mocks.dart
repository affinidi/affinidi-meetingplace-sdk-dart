import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/api/did_web_document_api.dart';
import 'package:meeting_place_control_plane/src/core/command/command.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';

class MockMeetingPlaceControlPlaneSDKLogger extends Mock
    implements MeetingPlaceControlPlaneSDKLogger {}

class MockDidWebDocumentApi extends Mock implements DidWebDocumentApi {}

class MockMeetingPlaceControlPlaneSDK extends Mock
    implements MeetingPlaceControlPlaneSDK {}

class MockDidManager extends Mock implements DidManager {}

class MockDidResolver extends Mock implements DidResolver {}

class RecordingMeetingPlaceControlPlaneSDK extends MeetingPlaceControlPlaneSDK {
  factory RecordingMeetingPlaceControlPlaneSDK() {
    final recorder = _CommandRecorder();
    return RecordingMeetingPlaceControlPlaneSDK._(recorder);
  }

  RecordingMeetingPlaceControlPlaneSDK._(this._recorder)
    : super(
        didManager: MockDidManager(),
        controlPlaneDid: 'did:web:control-plane.example',
        mediatorDid: 'did:web:mediator.example',
        didResolver: MockDidResolver(),
        commandExecutor: _recorder.record,
      );

  final _CommandRecorder _recorder;

  DiscoveryCommand<dynamic>? get lastCommand => _recorder.lastCommand;

  set stubbedResult(Object? result) => _recorder.stubbedResult = result;
}

class _CommandRecorder {
  DiscoveryCommand<dynamic>? lastCommand;
  Object? stubbedResult;

  Future<T> record<T>(DiscoveryCommand<T> command) async {
    lastCommand = command;
    return stubbedResult as T;
  }
}

class FakeAuthenticateCommand extends Fake implements AuthenticateRequest {}

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

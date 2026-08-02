import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:test/test.dart';

void main() {
  test('forwards agentDid to core SDK options', () {
    const options = MeetingPlaceMatrixSdkOptions(
      agentDid: 'did:key:test-agent',
    );

    expect(options.agentDid, equals('did:key:test-agent'));
  });
}

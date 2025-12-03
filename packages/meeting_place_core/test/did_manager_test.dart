import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import 'utils/sdk.dart';

void main() async {
  final MeetingPlaceCoreSDK aliceSDK = await initSDKInstance();

  test('generates DID and retrieves it from wallet', () async {
    final generatedDidManager = await aliceSDK.generateDid();
    final generatedDidDoc = await generatedDidManager.getDidDocument();

    final receivedDidManager = await aliceSDK.getDidManager(generatedDidDoc.id);
    final receivedDidDoc = await receivedDidManager.getDidDocument();

    expect(generatedDidDoc.id, equals(receivedDidDoc.id));
  });

  test('getDidManager with non-owned DID throws exception', () async {
    const nonOwnedDid =
        'did:key:z6MkpTHR8VNsBxYAAWHut2Geadd9jSwuBV8xRoAnwWsdvktH';

    expect(
      () async => await aliceSDK.getDidManager(nonOwnedDid),
      throwsA(isA<MeetingPlaceCoreSDKException>()),
    );
  });
}

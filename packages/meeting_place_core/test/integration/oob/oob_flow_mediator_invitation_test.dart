import 'package:dio/dio.dart';
import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:test/test.dart';

import '../../utils/sdk.dart';

void main() {
  late MeetingPlaceCoreSDK aliceSDK;

  setUp(() async {
    aliceSDK = await initSDKInstance();
  });

  test('creates oob invitation on mediator instance', () async {
    final did = await aliceSDK.generateDid();
    final didDoc = await did.getDidDocument();

    final oobUrl = await aliceSDK.mediator.createOob(did, getMediatorDid());

    final response = await Dio().get(oobUrl.toString());

    expect(response.data!['message'], equals('Success'));

    final actual = OobInvitationMessage.fromBase64(response.data['data']);
    expect(actual.from, didDoc.id);
    expect(
      actual.toPlainTextMessage().type,
      Uri.parse('https://didcomm.org/out-of-band/2.0/invitation'),
    );

    final oobActual = await aliceSDK.mediator.getOob(oobUrl, didManager: did);
    expect(oobActual.id, actual.id);
  });
}

import 'dart:async';

import 'package:meeting_place_core/meeting_place_core.dart';
import 'package:ssi/ssi.dart';

import 'print.dart';
import 'sdk.dart';

void main() async {
  final aliceSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));
  final bobSDK = await initSDK(wallet: PersistentWallet(InMemoryKeyStore()));

  final aliceWaitFor = Completer<void>();
  final bobWaitFor = Completer<void>();

  // Alice creates a direct connection
  final directConnection = await aliceSDK.createDirectConnection(
    CreateDirectConnectionRequest(
      contactCard: ContactCard(
        did: 'did:test:alice',
        type: 'individual',
        contactInfo: {'firstName': 'Alice'},
      ),
    ),
  );

  // Alice listens on acceptance
  directConnection.stream.listen((data) {
    prettyPrint('Alice received: ${data.eventType.name}');
    aliceWaitFor.complete();
  });

  // Bob accepts the direct connection
  final acceptance = await bobSDK.acceptDirectConnection(
    AcceptDirectConnectionRequest(
      directConnectionUrl: directConnection.directConnectionUrl,
      contactCard: ContactCard(
        did: 'did:test:bob',
        type: 'individual',
        contactInfo: {'firstName': 'Bob'},
      ),
    ),
  );

  // Bob listens for approval
  acceptance.stream.listen((data) {
    prettyPrint('Bob received: ${data.eventType.name}');
    bobWaitFor.complete();
  });

  await Future.wait([aliceWaitFor.future, bobWaitFor.future]);

  // Close stream
  await directConnection.stream.dispose();
  await acceptance.stream.dispose();
}

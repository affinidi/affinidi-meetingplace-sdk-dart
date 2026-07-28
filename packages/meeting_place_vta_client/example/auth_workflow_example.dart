import 'package:meeting_place_vta_client/meeting_place_vta_client.dart';

import 'mocks/auth_workflow_mocks.dart';

Future<void> main() async {
  final transport = createAuthWorkflowMockTransport();
  final client = VtaClient(
    baseUrl: 'https://vta.example',
    transport: transport,
  );
  final protocol = createAuthWorkflowMockProtocol();
  final workflow = VtaAuthWorkflow(
    client: client,
    holderDid: 'did:key:zHolder',
    vtaDid: 'did:webvh:vta.example',
    protocol: protocol,
  );

  final auth = await workflow.connect(scopes: const ['auth:read']);
  final token = await workflow.getValidAccessToken();
  final whoami = await workflow.whoAmI();

  print('Connected. session=${auth.session.sessionId}');
  print('Access token: $token');
  print('whoami subject=${whoami.subject} roles=${whoami.roles}');
}

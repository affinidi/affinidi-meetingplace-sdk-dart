# meeting_place_personal_agent

Personal-agent setup capability for Meeting Place applications.

This package contains MPX-specific orchestration flows and depends on
`vta_dart_client` for transport/auth primitives and the `VtaClient` HTTP
adapter.

## Usage

```dart
import 'package:meeting_place_personal_agent/meeting_place_personal_agent.dart';

final api = VtaPersonalAgentSetupApi(
  remote: VtaRestPersonalAgentSetupRemote(client: vtaClient),
);

final result = await api.ensurePersonalAgentSetup(
  request: const VtaPersonalAgentSetupRequest(
    holderDid: 'did:key:z...',
  ),
);
```

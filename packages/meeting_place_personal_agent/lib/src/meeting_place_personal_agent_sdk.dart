import 'package:vta_dart_client/vta_dart_client.dart';

import 'personal_agent_setup/adapters/adapter.dart';
import 'personal_agent_setup/adapters/hosted_adapter.dart';
import 'personal_agent_setup/models.dart';

class MeetingPlacePersonalAgentSDK {
  const MeetingPlacePersonalAgentSDK({required this.remote});

  factory MeetingPlacePersonalAgentSDK.hosted({
    required String baseUrl,
    String endpoint = '/personal-agent/setup',
    String? authToken,
  }) {
    final client = VtaClient(baseUrl: baseUrl, authToken: authToken);
    return MeetingPlacePersonalAgentSDK(
      remote: RestPersonalAgentSetupRemote(client: client, endpoint: endpoint),
    );
  }

  final PersonalAgentSetupRemote remote;

  Future<PersonalAgentSetupResult> ensurePersonalAgentSetup({
    required PersonalAgentSetupRequest request,
  }) async {
    request.validate();
    final response = await remote.ensurePersonalAgentSetup(request: request);
    return PersonalAgentSetupResult.fromJson(response);
  }

  Future<PersonalAgentOfferResult> fetchPersonalAgentOffer({
    required String setupId,
  }) async {
    final normalized = setupId.trim();
    if (normalized.isEmpty) {
      throw const VtaValidationException(
        'setupId must not be empty.',
        code: 'e.vta.personal_agent.setup_id_required',
      );
    }
    final response = await remote.fetchPersonalAgentOffer(setupId: normalized);
    return PersonalAgentOfferResult.fromJson(response);
  }

  /// Upload the user's context file and store it as the agent's initial memory.
  Future<PersonalAgentContextStatus> uploadPersonalAgentContext({
    required String setupId,
    required String content,
  }) async {
    final normalized = setupId.trim();
    if (normalized.isEmpty) {
      throw const VtaValidationException(
        'setupId must not be empty.',
        code: 'e.vta.personal_agent.setup_id_required',
      );
    }
    if (content.trim().isEmpty) {
      throw const VtaValidationException(
        'content must not be empty.',
        code: 'e.vta.personal_agent.content_required',
      );
    }
    final response = await remote.uploadPersonalAgentContext(
      setupId: normalized,
      content: content.trim(),
    );
    return PersonalAgentContextStatus.fromJson(response);
  }

  /// Check whether the user's context has been uploaded and stored.
  Future<PersonalAgentContextStatus> fetchPersonalAgentContextStatus({
    required String setupId,
  }) async {
    final normalized = setupId.trim();
    if (normalized.isEmpty) {
      throw const VtaValidationException(
        'setupId must not be empty.',
        code: 'e.vta.personal_agent.setup_id_required',
      );
    }
    final response = await remote.fetchPersonalAgentContextStatus(
      setupId: normalized,
    );
    return PersonalAgentContextStatus.fromJson(response);
  }

  Future<PersonalAgentAuthorizationSnapshot>
  fetchPersonalAgentAuthorizationSnapshot({
    required String setupId,
  }) async {
    final normalized = setupId.trim();
    if (normalized.isEmpty) {
      throw const VtaValidationException(
        'setupId must not be empty.',
        code: 'e.vta.personal_agent.setup_id_required',
      );
    }
    final response = await remote.fetchPersonalAgentAuthorizationSnapshot(
      setupId: normalized,
    );
    return PersonalAgentAuthorizationSnapshot.fromJson(response);
  }
}

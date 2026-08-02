import '../models.dart';

abstract class PersonalAgentSetupRemote {
  Future<Map<String, dynamic>> ensurePersonalAgentSetup({
    required PersonalAgentSetupRequest request,
  });

  Future<Map<String, dynamic>> fetchPersonalAgentOffer({
    required String setupId,
  });

  Future<Map<String, dynamic>> uploadPersonalAgentContext({
    required String setupId,
    required String content,
    String? contextKey,
  });

  Future<Map<String, dynamic>> fetchPersonalAgentContextStatus({
    required String setupId,
  });

  Future<Map<String, dynamic>> fetchPersonalAgentAuthorizationSnapshot({
    required String setupId,
  });
}

import '../models.dart';

abstract class PersonalAgentSetupRemote {
  Future<Map<String, dynamic>> ensurePersonalAgentSetup({
    required PersonalAgentSetupRequest request,
  });

  Future<Map<String, dynamic>> fetchPersonalAgentOffer({
    required String setupId,
  });
}

import 'package:vta_dart_client/vta_dart_client.dart';

enum PersonalAgentMode { suggestions, autoReply }

class PersonalAgentSetupRequest {
  const PersonalAgentSetupRequest({
    required this.holderDid,
    this.contextName = 'personal-ai',
    this.agentDisplayName = 'My Personal AI',
    this.mode = PersonalAgentMode.suggestions,
  });

  final String holderDid;
  final String contextName;
  final String agentDisplayName;
  final PersonalAgentMode mode;

  void validate() {
    if (holderDid.trim().isEmpty) {
      throw const VtaValidationException(
        'holderDid must not be empty.',
        code: 'e.vta.personal_agent.holder_did_required',
      );
    }
    if (contextName.trim().isEmpty) {
      throw const VtaValidationException(
        'contextName must not be empty.',
        code: 'e.vta.personal_agent.context_name_required',
      );
    }
    if (agentDisplayName.trim().isEmpty) {
      throw const VtaValidationException(
        'agentDisplayName must not be empty.',
        code: 'e.vta.personal_agent.display_name_required',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'holder_did': holderDid,
      'context_name': contextName,
      'agent_display_name': agentDisplayName,
      'mode': modeToWire(mode),
    };
  }
}

class PersonalAgentProfile {
  const PersonalAgentProfile({
    required this.agentDid,
    required this.displayName,
    required this.mode,
  });

  final String agentDid;
  final String displayName;
  final PersonalAgentMode mode;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'agent_did': agentDid,
      'display_name': displayName,
      'mode': modeToWire(mode),
    };
  }

  factory PersonalAgentProfile.fromJson(Map<String, dynamic> json) {
    return PersonalAgentProfile(
      agentDid: requiredString(json, ['agent_did', 'agentDid']),
      displayName: requiredString(json, ['display_name', 'displayName']),
      mode: wireToMode(requiredString(json, ['mode'])),
    );
  }
}

class PersonalAgentSetupResult {
  const PersonalAgentSetupResult({
    required this.holderDid,
    required this.contextId,
    required this.contextCreated,
    required this.agentDid,
    required this.agentCreated,
    required this.profile,
    this.setupId,
    this.setupStatus,
    this.offerAvailable,
    this.mpxConnectionCreated,
    this.availableInContacts,
  });

  final String holderDid;
  final String contextId;
  final bool contextCreated;
  final String agentDid;
  final bool agentCreated;
  final PersonalAgentProfile profile;
  final String? setupId;
  final String? setupStatus;
  final bool? offerAvailable;
  final bool? mpxConnectionCreated;
  final bool? availableInContacts;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'holder_did': holderDid,
      'context_id': contextId,
      'context_created': contextCreated,
      'agent_did': agentDid,
      'agent_created': agentCreated,
      'profile': profile.toJson(),
      if (setupId != null) 'setup_id': setupId,
      if (setupStatus != null) 'setup_status': setupStatus,
      if (offerAvailable != null) 'offer_available': offerAvailable,
      if (mpxConnectionCreated != null)
        'mpx_connection_created': mpxConnectionCreated,
      if (availableInContacts != null)
        'available_in_contacts': availableInContacts,
    };
  }

  factory PersonalAgentSetupResult.fromJson(Map<String, dynamic> json) {
    final profileJson = requiredObject(json, ['profile']);
    final profile = PersonalAgentProfile.fromJson(profileJson);

    return PersonalAgentSetupResult(
      holderDid: requiredString(json, ['holder_did', 'holderDid']),
      contextId: requiredString(json, ['context_id', 'contextId']),
      contextCreated: requiredBool(json, ['context_created', 'contextCreated']),
      agentDid: requiredString(json, ['agent_did', 'agentDid']),
      agentCreated: requiredBool(json, ['agent_created', 'agentCreated']),
      profile: profile,
      setupId: optionalString(json, ['setup_id', 'setupId']),
      setupStatus: optionalString(json, ['setup_status', 'setupStatus']),
      offerAvailable: optionalBool(json, ['offer_available', 'offerAvailable']),
      mpxConnectionCreated: optionalBool(json, [
        'mpx_connection_created',
        'mpxConnectionCreated',
      ]),
      availableInContacts: optionalBool(json, [
        'available_in_contacts',
        'availableInContacts',
      ]),
    );
  }
}

class PersonalAgentOfferResult {
  const PersonalAgentOfferResult({
    required this.setupId,
    required this.status,
    this.holderDid,
    this.agentDid,
    this.mnemonic,
    this.notificationDid,
    this.channelId,
    this.channelDid,
    this.updatedAt,
  });

  final String setupId;
  final String status;
  final String? holderDid;
  final String? agentDid;
  final String? mnemonic;
  final String? notificationDid;
  final String? channelId;
  final String? channelDid;
  final String? updatedAt;

  factory PersonalAgentOfferResult.fromJson(Map<String, dynamic> json) {
    return PersonalAgentOfferResult(
      setupId: requiredString(json, ['setup_id', 'setupId']),
      status: requiredString(json, ['status']),
      holderDid: optionalString(json, ['holder_did', 'holderDid']),
      agentDid: optionalString(json, ['agent_did', 'agentDid']),
      mnemonic: optionalString(json, ['mnemonic']),
      notificationDid: optionalString(json, [
        'notification_did',
        'notificationDid',
      ]),
      channelId: optionalString(json, ['channel_id', 'channelId']),
      channelDid: optionalString(json, ['channel_did', 'channelDid']),
      updatedAt: optionalString(json, ['updated_at', 'updatedAt']),
    );
  }
}

String modeToWire(PersonalAgentMode mode) {
  switch (mode) {
    case PersonalAgentMode.suggestions:
      return 'suggestions';
    case PersonalAgentMode.autoReply:
      return 'auto_reply';
  }
}

PersonalAgentMode wireToMode(String value) {
  if (value == 'suggestions') {
    return PersonalAgentMode.suggestions;
  }
  if (value == 'auto_reply') {
    return PersonalAgentMode.autoReply;
  }
  throw VtaParseException(
    'Unsupported personal agent mode "$value".',
    code: 'e.vta.personal_agent.invalid_mode',
  );
}

String requiredString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  throw VtaParseException(
    'Missing required string field ${keys.first}.',
    code: 'e.vta.personal_agent.invalid_payload',
  );
}

bool requiredBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
  }
  throw VtaParseException(
    'Missing required bool field ${keys.first}.',
    code: 'e.vta.personal_agent.invalid_payload',
  );
}

Map<String, dynamic> requiredObject(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
  }
  throw VtaParseException(
    'Missing required object field ${keys.first}.',
    code: 'e.vta.personal_agent.invalid_payload',
  );
}

String? optionalString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

bool? optionalBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
  }
  return null;
}

/// Result of uploading a personal context file or checking its status.
class PersonalAgentContextStatus {
  const PersonalAgentContextStatus({
    required this.setupId,
    required this.provisioned,
    required this.itemCount,
  });

  final String setupId;

  /// Whether the context has been uploaded and stored.
  final bool provisioned;

  /// Number of memory items stored for this user.
  final int itemCount;

  factory PersonalAgentContextStatus.fromJson(Map<String, dynamic> json) {
    return PersonalAgentContextStatus(
      setupId: requiredString(json, ['setup_id', 'setupId']),
      provisioned: requiredBool(json, ['provisioned']),
      itemCount: (json['item_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class PersonalAgentAuthorizationSnapshot {
  const PersonalAgentAuthorizationSnapshot({
    required this.setupId,
    required this.domainMap,
  });

  final String setupId;
  final Map<String, dynamic> domainMap;

  factory PersonalAgentAuthorizationSnapshot.fromJson(
    Map<String, dynamic> json,
  ) {
    return PersonalAgentAuthorizationSnapshot(
      setupId: requiredString(json, ['setup_id', 'setupId']),
      domainMap:
          _optionalObject(json, ['domain_map', 'domainMap']) ??
          <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'setup_id': setupId, 'domain_map': domainMap};
  }
}

Map<String, dynamic>? _optionalObject(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
  }
  return null;
}

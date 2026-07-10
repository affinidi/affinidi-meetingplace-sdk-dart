import 'package:vta_dart_client/vta_dart_client.dart';

import '../models.dart';
import 'adapter.dart';

class InMemoryPersonalAgentSetupRemote implements PersonalAgentSetupRemote {
  InMemoryPersonalAgentSetupRemote();

  final Map<String, _MockEntry> _entriesByHolder = <String, _MockEntry>{};
  final Map<String, _MockEntry> _entriesBySetupId = <String, _MockEntry>{};

  @override
  Future<Map<String, dynamic>> ensurePersonalAgentSetup({
    required PersonalAgentSetupRequest request,
  }) async {
    final existing = _entriesByHolder[request.holderDid];
    if (existing != null) {
      return <String, dynamic>{
        'setup_id': existing.setupId,
        'setup_status': 'offer_created',
        'offer_available': true,
        'holder_did': existing.holderDid,
        'context_id': existing.contextId,
        'context_created': false,
        'agent_did': existing.agentDid,
        'agent_created': false,
        'profile': <String, dynamic>{
          'agent_did': existing.agentDid,
          'display_name': request.agentDisplayName,
          'mode': modeToWire(request.mode),
        },
      };
    }

    final contextId = 'ctx-${_stableSuffix(request.holderDid)}';
    final agentDid = 'did:key:z${_stableSuffix(request.holderDid)}agent';

    final setupId = 'pa-${_stableSuffix(request.holderDid)}';
    final entry = _MockEntry(
      setupId: setupId,
      holderDid: request.holderDid,
      contextId: contextId,
      agentDid: agentDid,
    );
    _entriesByHolder[request.holderDid] = entry;
    _entriesBySetupId[setupId] = entry;

    return <String, dynamic>{
      'setup_id': setupId,
      'setup_status': 'offer_created',
      'offer_available': true,
      'holder_did': request.holderDid,
      'context_id': contextId,
      'context_created': true,
      'agent_did': agentDid,
      'agent_created': true,
      'profile': <String, dynamic>{
        'agent_did': agentDid,
        'display_name': request.agentDisplayName,
        'mode': modeToWire(request.mode),
      },
    };
  }

  @override
  Future<Map<String, dynamic>> fetchPersonalAgentOffer({
    required String setupId,
  }) async {
    final entry = _entriesBySetupId[setupId];
    if (entry == null) {
      throw const VtaValidationException(
        'Unknown setupId.',
        code: 'e.vta.personal_agent.unknown_setup',
      );
    }
    return <String, dynamic>{
      'setup_id': entry.setupId,
      'holder_did': entry.holderDid,
      'agent_did': entry.agentDid,
      'status': 'offer_created',
      'mnemonic': 'alarm gravity tonic elastic exit',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  @override
  Future<Map<String, dynamic>> uploadPersonalAgentContext({
    required String setupId,
    required String content,
  }) async {
    final entry = _entriesBySetupId[setupId];
    if (entry == null) {
      throw const VtaValidationException(
        'Unknown setupId.',
        code: 'e.vta.personal_agent.unknown_setup',
      );
    }
    entry.contextProvisioned = true;
    return <String, dynamic>{
      'setup_id': setupId,
      'provisioned': true,
      'item_count': 1,
    };
  }

  @override
  Future<Map<String, dynamic>> fetchPersonalAgentContextStatus({
    required String setupId,
  }) async {
    final entry = _entriesBySetupId[setupId];
    if (entry == null) {
      throw const VtaValidationException(
        'Unknown setupId.',
        code: 'e.vta.personal_agent.unknown_setup',
      );
    }
    return <String, dynamic>{
      'setup_id': setupId,
      'provisioned': entry.contextProvisioned,
      'item_count': entry.contextProvisioned ? 1 : 0,
    };
  }

  String _stableSuffix(String value) {
    final input = value.trim();
    if (input.isEmpty) {
      return 'holder';
    }
    final compact = input.replaceAll(':', '').replaceAll('-', '');
    return compact.length <= 16
        ? compact
        : compact.substring(compact.length - 16);
  }
}

class _MockEntry {
  _MockEntry({
    required this.setupId,
    required this.holderDid,
    required this.contextId,
    required this.agentDid,
  });

  final String setupId;
  final String holderDid;
  final String contextId;
  final String agentDid;
  bool contextProvisioned = false;
}

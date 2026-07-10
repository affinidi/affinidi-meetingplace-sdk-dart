import 'package:meeting_place_personal_agent/meeting_place_personal_agent.dart';
import 'package:test/test.dart';
import 'package:vta_dart_client/vta_dart_client.dart';

void main() {
  group('MeetingPlacePersonalAgentSDK', () {
    test('validates holder DID is required', () async {
      final sdk = MeetingPlacePersonalAgentSDK(
        remote: InMemoryPersonalAgentSetupRemote(),
      );

      await expectLater(
        sdk.ensurePersonalAgentSetup(
          request: const PersonalAgentSetupRequest(holderDid: '  '),
        ),
        throwsA(
          isA<VtaValidationException>().having(
            (e) => e.code,
            'code',
            'e.vta.personal_agent.holder_did_required',
          ),
        ),
      );
    });

    test('creates context/agent on first ensure call', () async {
      final sdk = MeetingPlacePersonalAgentSDK(
        remote: InMemoryPersonalAgentSetupRemote(),
      );

      final result = await sdk.ensurePersonalAgentSetup(
        request: const PersonalAgentSetupRequest(
          holderDid: 'did:key:zHolderA',
          contextName: 'work',
          agentDisplayName: 'Work AI',
          mode: PersonalAgentMode.suggestions,
        ),
      );

      expect(result.holderDid, 'did:key:zHolderA');
      expect(result.contextCreated, isTrue);
      expect(result.agentCreated, isTrue);
      expect(result.profile.displayName, 'Work AI');
      expect(result.profile.mode, PersonalAgentMode.suggestions);
      expect(result.contextId, startsWith('ctx-'));
      expect(result.agentDid, startsWith('did:key:'));
    });

    test('is idempotent on subsequent ensure call for same holder', () async {
      final sdk = MeetingPlacePersonalAgentSDK(
        remote: InMemoryPersonalAgentSetupRemote(),
      );
      const request = PersonalAgentSetupRequest(
        holderDid: 'did:key:zHolderB',
        contextName: 'work',
        agentDisplayName: 'Work AI',
      );

      final first = await sdk.ensurePersonalAgentSetup(request: request);
      final second = await sdk.ensurePersonalAgentSetup(request: request);

      expect(first.contextCreated, isTrue);
      expect(first.agentCreated, isTrue);
      expect(second.contextCreated, isFalse);
      expect(second.agentCreated, isFalse);
      expect(second.contextId, first.contextId);
      expect(second.agentDid, first.agentDid);
    });

    test('parses auto-reply mode from remote response', () async {
      final sdk = const MeetingPlacePersonalAgentSDK(
        remote: _StaticRemote(
          response: <String, dynamic>{
            'holder_did': 'did:key:zHolderC',
            'context_id': 'ctx-c',
            'context_created': true,
            'agent_did': 'did:key:zAgentC',
            'agent_created': true,
            'profile': <String, dynamic>{
              'agent_did': 'did:key:zAgentC',
              'display_name': 'Auto Agent',
              'mode': 'auto_reply',
            },
          },
        ),
      );

      final result = await sdk.ensurePersonalAgentSetup(
        request: const PersonalAgentSetupRequest(holderDid: 'did:key:zHolderC'),
      );

      expect(result.profile.mode, PersonalAgentMode.autoReply);
    });
  });
}

class _StaticRemote implements PersonalAgentSetupRemote {
  const _StaticRemote({required this.response});

  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> ensurePersonalAgentSetup({
    required PersonalAgentSetupRequest request,
  }) async {
    return response;
  }

  @override
  Future<Map<String, dynamic>> fetchPersonalAgentOffer({
    required String setupId,
  }) async {
    return <String, dynamic>{'setup_id': setupId, 'status': 'offer_created'};
  }

  @override
  Future<Map<String, dynamic>> uploadPersonalAgentContext({
    required String setupId,
    required String content,
  }) async {
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
    return <String, dynamic>{
      'setup_id': setupId,
      'provisioned': false,
      'item_count': 0,
    };
  }
}

import 'package:ssi/ssi.dart';
import 'mediator_config.dart';

class MediatorUtils {
  static Future<MediatorConfig> resolveMediator(
    String mediatorDid, {
    required DidResolver didResolver,
  }) async {
    final didDocument = await didResolver.resolveDid(mediatorDid);
    final service = didDocument.service.firstWhere(
      (service) => service.type == 'DIDCommMessaging',
    );

    final endpoints = service.toJson()['serviceEndpoint'] as List<Object>;

    final mediatorEndpoint = endpoints.firstWhere(
      (endpoint) =>
          (endpoint as Map<String, dynamic>)['uri'].startsWith('http'),
    );

    final mediatorWSSEndpoint = endpoints.firstWhere(
      (endpoint) => (endpoint as Map<String, dynamic>)['uri'].startsWith('wss'),
    );

    return MediatorConfig(
      mediatorDid: mediatorDid,
      mediatorEndpoint: (mediatorEndpoint as Map<String, dynamic>)['uri'],
      mediatorWSSEndpoint: (mediatorWSSEndpoint as Map<String, dynamic>)['uri'],
    );
  }

  static Future<MediatorConfig?> getMediatorConfig({
    required DidResolver didResolver,
    required String defaultMediatorDid,
    String? selectedMediatorDid,
  }) async {
    if (selectedMediatorDid != null) {
      return MediatorUtils.resolveMediator(
        selectedMediatorDid,
        didResolver: didResolver,
      );
    }

    if (defaultMediatorDid.isNotEmpty) {
      return MediatorUtils.resolveMediator(
        defaultMediatorDid,
        didResolver: didResolver,
      );
    }

    return null;
  }
}

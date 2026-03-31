import 'package:ssi/ssi.dart';
import 'mediator_config.dart';

class MediatorUtils {
  static Future<MediatorConfig> resolveMediator(
    String mediatorDid, {
    required DidResolver didResolver,
  }) async {
    final didDocument = await didResolver.resolveDid(mediatorDid);
    final service = didDocument.service.firstWhere(
      (service) => service.type.toString() == 'DIDCommMessaging',
    );

    final endpoints = service.toJson()['serviceEndpoint'] as List<Object>;

    final mediatorEndpoint = endpoints.cast<Map<String, dynamic>>().firstWhere(
      (Map<String, dynamic> endpoint) =>
          (endpoint['uri'] as String).startsWith('http'),
    );

    final mediatorWSSEndpoint = endpoints
        .cast<Map<String, dynamic>>()
        .firstWhere(
          (Map<String, dynamic> endpoint) =>
              (endpoint['uri'] as String).startsWith('wss'),
        );

    return MediatorConfig(
      mediatorDid: mediatorDid,
      mediatorEndpoint: mediatorEndpoint['uri'] as String,
      mediatorWSSEndpoint: mediatorWSSEndpoint['uri'] as String,
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

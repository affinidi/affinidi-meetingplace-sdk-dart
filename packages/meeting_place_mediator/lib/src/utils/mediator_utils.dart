import 'package:ssi/ssi.dart';

class MediatorUtils {
  static Future<String> getMediatorEndpointByDid(
    String mediatorDid, {
    required DidResolver didResolver,
  }) async {
    final didDocument = await didResolver.resolveDid(mediatorDid);
    return getMediatorEndpointByDidDocument(didDocument);
  }

  static String getMediatorEndpointByDidDocument(DidDocument didDocument) {
    final service = didDocument.service.firstWhere(
      (service) => service.type.toString() == 'DIDCommMessaging',
    );

    final endpoints = service.toJson()['serviceEndpoint'] as List<Object>;

    final mediatorEndpoint = endpoints.cast<Map<String, dynamic>>().firstWhere(
          (Map<String, dynamic> endpoint) =>
              (endpoint['uri'] as String).startsWith('http'),
        );

    return mediatorEndpoint['uri'] as String;
  }
}

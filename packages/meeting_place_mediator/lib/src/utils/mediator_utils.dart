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

    final mediatorEndpoint = endpoints.firstWhere(
      (endpoint) =>
          (endpoint as Map<String, dynamic>)['uri'].startsWith('http'),
    );

    return (mediatorEndpoint as Map<String, dynamic>)['uri'];
  }
}

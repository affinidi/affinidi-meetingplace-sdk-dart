import 'package:ssi/ssi.dart';

class MediatorUtils {
  static Future<String> getMediatorEndpointByDid(
    String mediatorDid, {
    required DidResolver didResolver,
  }) async {
    final didDocument = await didResolver.resolveDid(mediatorDid);
    return _getMediatorEndpointByDidDocument(didDocument);
  }

  static String _getMediatorEndpointByDidDocument(DidDocument didDocument) {
    final serviceEndpoint = didDocument.service
        .firstWhere((service) => service.type == 'DIDCommMessaging')
        .serviceEndpoint;

    if (serviceEndpoint is StringEndpoint &&
        serviceEndpoint.url.startsWith('https')) {
      return serviceEndpoint.url;
    }

    if (serviceEndpoint is MapEndpoint &&
        (serviceEndpoint.data['uri'] as String).startsWith('https')) {
      return serviceEndpoint.data['uri'] as String;
    }

    if (serviceEndpoint is SetEndpoint) {
      for (final endpoint in serviceEndpoint.endpoints) {
        if (endpoint is MapEndpoint) {
          final uri = endpoint.data['uri'] as String;
          if (uri.startsWith('https')) {
            return uri;
          }
        }

        if (endpoint is StringEndpoint) {
          if (endpoint.url.startsWith('https')) {
            return endpoint.url;
          }
        }
      }
    }

    throw Exception('No valid mediator endpoint found in DID Document');
  }
}

import 'package:ssi/ssi.dart';
import 'mediator_config.dart';

enum EndpointType {
  http('https'),
  webSocket('wss');

  final String protocol;
  const EndpointType(this.protocol);
}

class MediatorUtils {
  static Future<MediatorConfig> resolveMediator(
    String mediatorDid, {
    required DidResolver didResolver,
  }) async {
    final didDocument = await didResolver.resolveDid(mediatorDid);
    return MediatorConfig(
      mediatorDid: mediatorDid,
      mediatorEndpoint: _getMediatorEndpointByDidDocument(didDocument,
          endpointType: EndpointType.http),
      mediatorWSSEndpoint: _getMediatorEndpointByDidDocument(didDocument,
          endpointType: EndpointType.webSocket),
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

  static String _getMediatorEndpointByDidDocument(
    DidDocument didDocument, {
    required EndpointType endpointType,
  }) {
    final serviceEndpoint = didDocument.service
        .firstWhere((service) => service.type == 'DIDCommMessaging')
        .serviceEndpoint;

    if (serviceEndpoint is StringEndpoint &&
        serviceEndpoint.url.startsWith(endpointType.protocol)) {
      return serviceEndpoint.url;
    }

    if (serviceEndpoint is MapEndpoint &&
        (serviceEndpoint.data['uri'] as String)
            .startsWith(endpointType.protocol)) {
      return serviceEndpoint.data['uri'] as String;
    }

    if (serviceEndpoint is SetEndpoint) {
      for (final endpoint in serviceEndpoint.endpoints) {
        if (endpoint is MapEndpoint) {
          final uri = endpoint.data['uri'] as String;
          if (uri.startsWith(endpointType.protocol)) {
            return uri;
          }
        }

        if (endpoint is StringEndpoint) {
          if (endpoint.url.startsWith(endpointType.protocol)) {
            return endpoint.url;
          }
        }
      }
    }

    throw Exception('No valid mediator endpoint found in DID Document');
  }
}

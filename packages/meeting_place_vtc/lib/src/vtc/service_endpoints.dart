import 'package:ssi/ssi.dart';

import '../trigger_link/host_rules.dart';

/// Whether [endpoint] may be used as an HTTPS endpoint: an `https` URL with
/// no userinfo, no port, and a host that meets the host rules.
///
/// The authority is read from the raw text, because URL parsing drops a
/// default `:443` and the rules forbid any port.
bool isUsableHttpsEndpoint(String endpoint) {
  if (!endpoint.toLowerCase().startsWith('https://')) return false;
  final authority = endpoint
      .substring('https://'.length)
      .split(RegExp('[/?#]'))[0];
  if (authority.contains('@') ||
      authority.contains(':') ||
      authority.startsWith('[')) {
    return false;
  }
  final uri = Uri.tryParse(endpoint);
  return uri != null && hostMeetsRules(uri.host.toLowerCase());
}

/// [value] as a URL when it is text [isUsableHttpsEndpoint] accepts, such
/// as a link a community publishes about itself; null otherwise.
Uri? httpsUrl(Object? value) =>
    value is String && isUsableHttpsEndpoint(value) ? Uri.parse(value) : null;

/// The first usable HTTPS endpoint of a service of [type] in [document], in
/// document order.
///
/// Services are matched on type, never on id, and an endpoint may be a
/// string or an object with a `uri`.
Uri? serviceEndpointOfType(DidDocument document, String type) {
  for (final service in document.service) {
    if (service.type != StringServiceType(type)) continue;
    final endpoint = switch (service.serviceEndpoint) {
      StringEndpoint(:final url) => url,
      MapEndpoint(:final data) => data['uri'],
      SetEndpoint() => null,
    };
    if (endpoint is String && isUsableHttpsEndpoint(endpoint)) {
      return Uri.parse(endpoint);
    }
  }
  return null;
}

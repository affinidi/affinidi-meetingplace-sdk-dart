final _label = RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$');
final _digitsOnly = RegExp(r'^[0-9]+$');
const _maxHostLength = 253;

/// Whether [host], already lowercased, is a public DNS name of two or more
/// labels, never an IP address or a local name.
///
/// The host rules of the VTI trigger-link chapter, applied to trigger links
/// and to every endpoint taken from a DID document.
bool hostMeetsRules(String host) {
  if (host.isEmpty || host.length > _maxHostLength || host.endsWith('.')) {
    return false;
  }
  if (host.startsWith('[')) return false;
  final labels = host.split('.');
  if (labels.length < 2 || !labels.every(_label.hasMatch)) return false;
  // A last label of digits only also refuses every IPv4 address.
  if (_digitsOnly.hasMatch(labels.last)) return false;
  if (host == 'localhost' || host.endsWith('.localhost')) return false;
  if (host.endsWith('.local') || host.endsWith('.home.arpa')) return false;
  return true;
}

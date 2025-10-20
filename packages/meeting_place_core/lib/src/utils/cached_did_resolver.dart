import 'package:ssi/ssi.dart';

class CachedDidResolver implements DidResolver {
  CachedDidResolver({this.resolverAddress});

  static Map<String, DidDocument> cacheDIDDocs = {};
  final String? resolverAddress;

  @override
  Future<DidDocument> resolveDid(String did) async {
    if (cacheDIDDocs.containsKey(did)) {
      return cacheDIDDocs[did]!;
    }

    final didDocument = await UniversalDIDResolver(
      resolverAddress: resolverAddress,
    ).resolveDid(did);

    cacheDIDDocs[didDocument.id] = didDocument;
    return didDocument;
  }
}

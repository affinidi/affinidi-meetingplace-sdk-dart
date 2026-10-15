import 'package:ssi/ssi.dart';

import '../meeting_place_vtc_sdk_exception.dart';

/// Answers with an already-resolved DID document, so that verifying a
/// community's answer cannot resolve its DID a second time and get a
/// different answer.
class ResolvedDocument implements DidResolver {
  /// Creates a [ResolvedDocument] that knows only [_document].
  ResolvedDocument(this._document);

  final DidDocument _document;

  @override
  Future<DidDocument> resolveDid(String did) async {
    if (did != _document.id) {
      throw MeetingPlaceVtcSDKException.didResolutionFailed();
    }
    return _document;
  }
}

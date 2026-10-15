import 'package:ssi/ssi.dart';

import '../meeting_place_vtc_sdk_exception.dart';
import 'service_endpoints.dart';

/// DID document service type of a VTC's Trust Task HTTPS base.
const trustTaskHttpsServiceType = 'TrustTaskHTTPS';

/// DID document service type of the page where members sign in.
const signInPortalServiceType = 'SignInPortal';

/// A Verifiable Trust Community as a wallet sends it Trust Tasks.
class VtcCommunityEndpoint {
  /// Creates a [VtcCommunityEndpoint].
  const VtcCommunityEndpoint({
    required this.didDocument,
    required this.trustTaskBase,
  });

  /// The community's resolved, verified DID document.
  final DidDocument didDocument;

  /// Base URL Trust Tasks are posted to, as `<base>/trust-tasks`.
  final Uri trustTaskBase;

  /// The community's DID.
  String get did => didDocument.id;
}

/// A Verifiable Trust Community as a wallet reaches it for sign-in.
class VtcEndpoints extends VtcCommunityEndpoint {
  /// Creates a [VtcEndpoints].
  const VtcEndpoints({
    required super.didDocument,
    required super.trustTaskBase,
    required this.signInOrigin,
  });

  /// Origin of the sign-in page, e.g. `https://community.example`.
  final String signInOrigin;
}

/// Resolves a VTC's DID and reads where to reach it from its DID document.
///
/// Endpoints are taken only from the resolved document, never from a link
/// or QR code, so a forged code cannot redirect the wallet.
class VtcResolver {
  /// Creates a [VtcResolver] that resolves DIDs with [didResolver].
  ///
  /// The default resolver verifies `did:webvh` logs.
  VtcResolver({DidResolver? didResolver})
    : _didResolver = didResolver ?? UniversalDIDResolver.defaultResolver;

  final DidResolver _didResolver;

  /// Resolves [vtcDid] and returns its sign-in endpoints.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the DID does not resolve to a
  /// document with that id, or the document lacks a usable
  /// [trustTaskHttpsServiceType] or [signInPortalServiceType] service.
  Future<VtcEndpoints> resolve(String vtcDid) async {
    final community = await resolveCommunity(vtcDid);
    final signInPortal = serviceEndpointOfType(
      community.didDocument,
      signInPortalServiceType,
    );
    if (signInPortal == null) {
      throw MeetingPlaceVtcSDKException.signInNotOffered(
        signInPortalServiceType,
      );
    }

    return VtcEndpoints(
      didDocument: community.didDocument,
      trustTaskBase: community.trustTaskBase,
      signInOrigin: signInPortal.origin,
    );
  }

  /// Resolves [vtcDid] and returns where it takes Trust Tasks.
  ///
  /// Throws [MeetingPlaceVtcSDKException] when the DID does not resolve to a
  /// document with that id, or the document lacks a usable
  /// [trustTaskHttpsServiceType] service.
  Future<VtcCommunityEndpoint> resolveCommunity(String vtcDid) async {
    final DidDocument document;
    try {
      document = await _didResolver.resolveDid(vtcDid);
    } catch (error) {
      throw MeetingPlaceVtcSDKException.didResolutionFailed(
        innerException: error,
      );
    }
    if (document.id != vtcDid) {
      throw MeetingPlaceVtcSDKException.didResolutionFailed();
    }

    final trustTaskBase = serviceEndpointOfType(
      document,
      trustTaskHttpsServiceType,
    );
    if (trustTaskBase == null) {
      throw MeetingPlaceVtcSDKException.signInNotOffered(
        trustTaskHttpsServiceType,
      );
    }
    return VtcCommunityEndpoint(
      didDocument: document,
      trustTaskBase: trustTaskBase,
    );
  }
}

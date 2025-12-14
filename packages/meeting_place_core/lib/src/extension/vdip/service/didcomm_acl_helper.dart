import 'package:affinidi_tdk_didcomm_mediator_client/affinidi_tdk_didcomm_mediator_client.dart';
import 'package:ssi/ssi.dart';
import 'package:uuid/uuid.dart';

/// Helper class for configuring Access Control
/// Lists (ACL) with DIDComm mediator.
///
/// Provides utility methods to manage ACL permissions for DIDComm messaging,
/// allowing specific DIDs to communicate through the mediator.
class DidcommAclHelper {
  DidcommAclHelper._();

  /// Configures ACL to allow communication
  /// with specified DIDs through the mediator.
  ///
  /// - [mediatorDidDocument] - The DID document of the mediator
  /// - [didManager] - The DID manager representing the entity configuring ACL
  /// - [theirDids] - List of DIDs that should be allowed to send messages
  /// - [expiresTime] - Optional expiration time for the ACL entry
  static Future<void> configureAcl({
    required DidDocument mediatorDidDocument,
    required DidManager didManager,
    required List<String> theirDids,
    DateTime? expiresTime,
  }) async {
    final ownDidDocument = await didManager.getDidDocument();

    final mediatorClient = await DidcommMediatorClient.init(
      mediatorDidDocument: mediatorDidDocument,
      didManager: didManager,
      authorizationProvider: await AffinidiAuthorizationProvider.init(
        mediatorDidDocument: mediatorDidDocument,
        didManager: didManager,
      ),
      clientOptions: const AffinidiClientOptions(),
    );

    final accessListAddMessage = AccessListAddMessage(
      id: const Uuid().v4(),
      from: ownDidDocument.id,
      to: [mediatorClient.mediatorDidDocument.id],
      theirDids: theirDids,
      expiresTime: expiresTime,
    );

    await mediatorClient.sendAclManagementMessage(accessListAddMessage);
  }
}

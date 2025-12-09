import 'package:affinidi_tdk_didcomm_mediator_client/affinidi_tdk_didcomm_mediator_client.dart';

class RequestCredentialResponse {
  RequestCredentialResponse({
    required this.credential,
    required this.credentialFormat,
  });

  final String credential;
  final CredentialFormat credentialFormat;
}

import '../client/vta_client.dart';
import '../models/session_info.dart';
import '../models/vta_authenticate_result.dart';
import 'auth_service.dart';
import 'session_manager.dart';
import 'auth_protocol.dart';

class VtaAuthWorkflow {
  VtaAuthWorkflow({
    required this.client,
    required this.holderDid,
    required this.vtaDid,
    required this.protocol,
    VtaSessionManager? sessionManager,
  }) : sessionManager =
           sessionManager ??
           VtaSessionManager(
             client: client,
             holderDid: holderDid,
             vtaDid: vtaDid,
             protocol: protocol,
           ) {
    authService = VtaAuthService(
      api: client.auth,
      sessionManager: this.sessionManager,
      holderDid: holderDid,
      vtaDid: vtaDid,
      protocol: protocol,
    );
  }

  final VtaClient client;
  final String holderDid;
  final String vtaDid;
  final VtaAuthProtocol protocol;
  final VtaSessionManager sessionManager;
  late final VtaAuthService authService;

  Future<VtaAuthenticateResult> connect({
    String? purpose,
    List<String> scopes = const <String>[],
  }) => authService.connect(purpose: purpose, scopes: scopes);

  Future<VtaAuthenticateResult> refresh({
    List<String> scopes = const <String>[],
  }) => authService.refresh(scopes: scopes);

  Future<String> getValidAccessToken({
    List<String> scopes = const <String>[],
  }) => authService.getValidAccessToken(scopes: scopes);

  Future<SessionInfo> whoAmI({
    bool ensureValidAccessToken = true,
    List<String> scopes = const <String>[],
  }) => authService.whoAmI(
    ensureValidAccessToken: ensureValidAccessToken,
    scopes: scopes,
  );

  Future<VtaAuthenticateResult> reconnect({
    String? purpose,
    List<String> scopes = const <String>[],
  }) => authService.reconnect(purpose: purpose, scopes: scopes);

  void disconnect() {
    authService.disconnect();
  }
}

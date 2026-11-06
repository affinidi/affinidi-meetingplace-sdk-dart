import 'package:meeting_place_vtc/meeting_place_vtc.dart';

/// Answers every status check with [state].
class FakeStatusList implements StatusListClient {
  CredentialStatusState state = CredentialStatusState.noStatus;
  final List<Map<String, dynamic>> checked = [];

  @override
  Future<CredentialStatusCheck> check(Map<String, dynamic> credential) async {
    checked.add(credential);
    return CredentialStatusCheck(state: state, checkedAt: DateTime.now());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

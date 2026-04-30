/// Output of [MatrixRegistrationCredentialCommand].
class MatrixRegistrationCredentialCommandOutput {
  MatrixRegistrationCredentialCommandOutput({
    required this.credential,
    required this.did,
    this.matrixLocalpart,
  });

  final String credential;
  final String did;
  final String? matrixLocalpart;
}

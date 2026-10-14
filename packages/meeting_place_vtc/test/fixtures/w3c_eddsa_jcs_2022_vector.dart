// Test vector from the W3C Data Integrity EdDSA Cryptosuites specification:
// https://github.com/w3c/vc-di-eddsa/tree/main/TestVectors (eddsa-jcs-2022).

const w3cPrivateKeyMultibase =
    'z3u2en7t5LR2WtQH5PfFqMqwVHBeXouLzo6haApm8XHqvjxq';

const w3cVerificationMethod =
    'did:key:z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2'
    '#z6MkrJVnaZkeFzdQyMZu1cgjg7k1pZZ6pvBQ7XJPt4swbTQ2';

const w3cCreated = '2023-02-24T23:36:38Z';

const w3cProofValue =
    'z2HnFSSPPBzR36zdDgK8PbEHeXbR56YF24jwMpt3R1eHXQzJDMWS93FCzpvJpwTWd3GAVFuU'
    'fjoJdcnTMuVor51aX';

Map<String, dynamic> w3cUnsignedCredential() => {
  '@context': [
    'https://www.w3.org/ns/credentials/v2',
    'https://www.w3.org/ns/credentials/examples/v2',
  ],
  'id': 'urn:uuid:58172aac-d8ba-11ed-83dd-0b3aef56cc33',
  'type': ['VerifiableCredential', 'AlumniCredential'],
  'name': 'Alumni Credential',
  'description': 'A minimum viable example of an Alumni Credential.',
  'issuer': 'https://vc.example/issuers/5678',
  'validFrom': '2023-01-01T00:00:00Z',
  'credentialSubject': {
    'id': 'did:example:abcdefgh',
    'alumniOf': 'The School of Examples',
  },
};

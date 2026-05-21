const vrcBlobMissingType =
    '{"@context":["https://www.w3.org/2018/credentials/v1"],'
    '"type":["VerifiableCredential"],'
    '"issuer":"did:example:issuer",'
    '"credentialSubject":{}}';

const vrcBlobWithoutProof =
    '{'
    '"@context":["https://www.w3.org/2018/credentials/v2",'
    '"https://w3id.org/security/data-integrity/v2",'
    '"https://schema.affinidi.io/TRelationshipCredentialV1R0.jsonld"],'
    '"id":"urn:uuid:test-vrc-no-proof",'
    '"type":["VerifiableCredential","RelationshipCredential"],'
    '"issuer":"did:key:test-issuer",'
    '"validFrom":"2024-01-01T00:00:00.000Z",'
    '"credentialSubject":{'
    '"from":{"did":"did:key:alice","name":"Alice"},'
    '"to":{"did":"did:key:bob","name":"Bob"}'
    '}'
    '}';

const vrcBlobWithoutId =
    '{"@context":["https://www.w3.org/2018/credentials/v2",'
    '"https://w3id.org/security/data-integrity/v2",'
    '"https://schema.affinidi.io/TRelationshipCredentialV1R0.jsonld"],'
    '"type":["VerifiableCredential","RelationshipCredential"],'
    '"issuer":"did:example:issuer",'
    '"validFrom":"2024-01-01T00:00:00Z",'
    '"proof":{},'
    '"credentialSubject":{'
    '"from":{"did":"did:example:issuer","name":"Alice"},'
    '"to":{"did":"did:example:holder","name":"Bob"}'
    '}}';

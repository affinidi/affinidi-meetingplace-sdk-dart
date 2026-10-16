import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:didcomm/didcomm.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:meeting_place_mediator/src/core/acl/trust_task_acl_body.dart';
import 'package:test/test.dart';

void main() {
  const owner = 'did:example:owner';
  const grantee = 'did:example:grantee';
  const mediator = 'did:example:mediator';

  String hash(String did) => sha256.convert(utf8.encode(did)).toString();

  group('AccessListAdd.toTrustTask', () {
    test('builds an access-list/update task adding the grantees', () {
      final task = AccessListAdd(
        ownerDid: owner,
        granteeDids: [grantee],
      ).toTrustTask(issuer: owner, mediatorDid: mediator)!;

      expect(task, isA<AccessListUpdateTask>());
      expect(task.issuer, owner);
      expect(task.recipient, mediator);
      expect(task.payload, {
        'did': hash(owner),
        'add': [hash(grantee)],
      });
    });

    test('returns null when there are no grantees', () {
      final task = AccessListAdd(
        ownerDid: owner,
        granteeDids: [],
      ).toTrustTask(issuer: owner, mediatorDid: mediator);

      expect(task, isNull);
    });
  });

  group('AccessListRemove.toTrustTask', () {
    test('builds an access-list/update task removing the grantees', () {
      final task = AccessListRemove(
        ownerDid: owner,
        granteeDids: [grantee],
      ).toTrustTask(issuer: owner, mediatorDid: mediator)!;

      expect(task, isA<AccessListUpdateTask>());
      expect(task.payload, {
        'did': hash(owner),
        'remove': [hash(grantee)],
      });
    });

    test('returns null when there are no grantees', () {
      final task = AccessListRemove(
        ownerDid: owner,
        granteeDids: [],
      ).toTrustTask(issuer: owner, mediatorDid: mediator);

      expect(task, isNull);
    });
  });

  group('AccessListSet', () {
    test('toPublic only switches the access list to explicit deny', () {
      final task = AccessListSet.toPublic(
        ownerDid: owner,
      ).toTrustTask(issuer: owner, mediatorDid: mediator);

      expect(task, isA<AccountUpdateTask>());
      expect(task.issuer, owner);
      expect(task.recipient, mediator);
      expect(task.payload, {
        'did': hash(owner),
        'acl': {'accessListMode': 'explicitDeny'},
      });
    });

    test('bitmask constructor only applies the access-list mode', () {
      final task = AccessListSet(
        ownerDid: owner,
        acls: 0x1050,
      ).toTrustTask(issuer: owner, mediatorDid: mediator);

      expect(task.payload, {
        'did': hash(owner),
        'acl': {'accessListMode': 'explicitAllow'},
      });
    });

    test('toJson keeps the legacy bitmask', () {
      expect(AccessListSet.toPublic(ownerDid: owner).toJson(), {
        'acl_set': {
          'did_hash': hash(owner),
          'acls': AccessListSet.publicAclFlag,
        },
      });
    });
  });

  group('owner other than the issuer', () {
    const issuer = 'did:example:issuer';

    test('AccessListAdd targets the owner', () {
      final task = AccessListAdd(
        ownerDid: owner,
        granteeDids: [grantee],
      ).toTrustTask(issuer: issuer, mediatorDid: mediator)!;

      expect(task.issuer, issuer);
      expect(task.payload['did'], hash(owner));
    });

    test('AccessListSet targets the owner', () {
      final task = AccessListSet.toPublic(
        ownerDid: owner,
      ).toTrustTask(issuer: issuer, mediatorDid: mediator);

      expect(task.issuer, issuer);
      expect(task.payload['did'], hash(owner));
    });
  });

  // fromJson only has hashes, so it builds the document itself instead of
  // using the didcomm task classes. It must still produce the same task.
  group('deprecated fromJson', () {
    Map<String, dynamic> body(AclBody acl, String method) =>
        acl.toJson()[method] as Map<String, dynamic>;

    // The id and issue time differ per task.
    Map<String, dynamic> taskJson(TrustTaskAclBody acl) =>
        acl.toTrustTask(issuer: owner, mediatorDid: mediator)!.toJson()
          ..remove('id')
          ..remove('issuedAt');

    test('AccessListAdd round-trips and builds the same task', () {
      final acl = AccessListAdd(ownerDid: owner, granteeDids: [grantee]);
      // ignore: deprecated_member_use_from_same_package
      final decoded = AccessListAdd.fromJson(body(acl, AccessListAdd.method));

      expect(decoded.toJson(), acl.toJson());
      expect(taskJson(decoded), taskJson(acl));
    });

    test('AccessListRemove round-trips and builds the same task', () {
      final acl = AccessListRemove(ownerDid: owner, granteeDids: [grantee]);
      // ignore: deprecated_member_use_from_same_package
      final decoded = AccessListRemove.fromJson(
        body(acl, AccessListRemove.method),
      );

      expect(decoded.toJson(), acl.toJson());
      expect(taskJson(decoded), taskJson(acl));
    });

    test('AccessListSet round-trips and builds the same task', () {
      final acl = AccessListSet.toPublic(ownerDid: owner);
      // ignore: deprecated_member_use_from_same_package
      final decoded = AccessListSet.fromJson(body(acl, AccessListSet.method));

      expect(decoded.toJson(), acl.toJson());
      expect(taskJson(decoded), taskJson(acl));
    });
  });
}

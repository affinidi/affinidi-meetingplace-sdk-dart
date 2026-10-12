import 'dart:io';

import 'package:didcomm/didcomm.dart';
import 'package:dio/dio.dart';
import 'package:meeting_place_mediator/meeting_place_mediator.dart';
import 'package:meeting_place_mediator/src/core/acl/acl_management.dart';
import 'package:meeting_place_mediator/src/core/acl/acl_update_sender.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ssi/ssi.dart';
import 'package:test/test.dart';

class MockMediatorClient extends Mock implements MediatorClient {}

class AppAclBody implements AclBody {
  @override
  Map<String, dynamic> toJson() => {'app_acl': <String, dynamic>{}};
}

MediatorClientException httpError(int statusCode) {
  final requestOptions = RequestOptions(path: '/inbound');
  return MediatorClientException(
    innerException: DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: statusCode,
      ),
      type: DioExceptionType.badResponse,
    ),
  );
}

void main() {
  const owner = 'did:example:owner';
  const grantee = 'did:example:grantee';
  const mediatorDid = 'did:example:mediator';

  late MockMediatorClient client;
  late List<AclManagement> aclManagementMessages;
  late MediatorClientException? aclManagementError;
  late AclUpdateSender sender;

  Future<void> runOnce(Future<void> Function() operation) => operation();

  Future<void> send(AclBody acl, {RetryRunner? retry}) {
    return sender.send(
      client: client,
      issuerDid: owner,
      acl: acl,
      expiresInSeconds: 60,
      retry: retry ?? runOnce,
    );
  }

  final grantAccess = AccessListAdd(ownerDid: owner, granteeDids: [grantee]);

  setUpAll(() {
    registerFallbackValue(
      TrustTaskMessage(
        id: 'fallback',
        document: TrustTaskDocument(
          type: AccessListUpdateTask.taskType,
          issuer: owner,
          recipient: mediatorDid,
          payload: const {},
        ),
      ),
    );
  });

  setUp(() {
    client = MockMediatorClient();
    when(
      () => client.mediatorDidDocument,
    ).thenReturn(DidDocument.create(id: mediatorDid));

    aclManagementMessages = [];
    aclManagementError = null;
    sender = AclUpdateSender(
      logger: DefaultMeetingPlaceMediatorSDKLogger(
        className: 'AclUpdateSenderTest',
        sdkName: 'test',
      ),
      sendAclManagementMessage: (_, message) async {
        if (aclManagementError case final error?) throw error;
        aclManagementMessages.add(message);
      },
    );
  });

  void answerTrustTasks({Object? error}) {
    final stub = when(() => client.sendTrustTask(any()));
    if (error == null) {
      stub.thenAnswer((_) async => PlainTextMessage(id: 'sent', type: Uri()));
    } else {
      stub.thenThrow(error);
    }
  }

  test('sends the ACL action as a Trust Task', () async {
    answerTrustTasks();

    await send(grantAccess);

    final message =
        verify(() => client.sendTrustTask(captureAny())).captured.single
            as TrustTaskMessage;
    expect(message.document.type, AccessListUpdateTask.taskType);
    expect(aclManagementMessages, isEmpty);
  });

  test('builds a fresh task id on every retry', () async {
    answerTrustTasks();

    await send(
      grantAccess,
      retry: (operation) async {
        await operation();
        await operation();
      },
    );

    final messages = verify(
      () => client.sendTrustTask(captureAny()),
    ).captured.cast<TrustTaskMessage>();
    expect(messages[0].id, isNot(messages[1].id));
    expect(messages[0].document.id, isNot(messages[1].document.id));
  });

  test('skips an action that changes nothing', () async {
    await send(AccessListAdd(ownerDid: owner, granteeDids: []));

    verifyNever(() => client.sendTrustTask(any()));
    expect(aclManagementMessages, isEmpty);
  });

  test('falls back to acl-management when the mediator answers the Trust '
      'Task with 501, and remembers it', () async {
    answerTrustTasks(error: httpError(HttpStatus.notImplemented));

    await send(grantAccess);
    await send(grantAccess);

    verify(() => client.sendTrustTask(any())).called(1);
    expect(aclManagementMessages, hasLength(2));
    expect(aclManagementMessages.first.body, grantAccess.toJson());
  });

  test('uses Trust Tasks again once a remembered legacy mediator answers '
      'acl-management with 501', () async {
    answerTrustTasks(error: httpError(HttpStatus.notImplemented));
    await send(grantAccess);

    aclManagementError = httpError(HttpStatus.notImplemented);
    answerTrustTasks();
    await send(grantAccess);

    verify(() => client.sendTrustTask(any())).called(2);
    expect(aclManagementMessages, hasLength(1));
  });

  test('sends the full legacy bitmask of an AccessListSet with '
      'acl-management', () async {
    answerTrustTasks(error: httpError(HttpStatus.notImplemented));

    final makePublic = AccessListSet.toPublic(ownerDid: owner);
    await send(makePublic);

    expect(aclManagementMessages.single.body, makePublic.toJson());
  });

  test('does not fall back on other errors', () async {
    answerTrustTasks(error: httpError(HttpStatus.forbidden));

    await expectLater(
      send(grantAccess),
      throwsA(isA<MediatorClientException>()),
    );
    expect(aclManagementMessages, isEmpty);
  });

  test('sends an app AclBody with acl-management', () async {
    final acl = AppAclBody();

    await send(acl);

    verifyNever(() => client.sendTrustTask(any()));
    expect(aclManagementMessages.single.body, acl.toJson());
  });
}

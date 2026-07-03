import 'dart:io';

import 'package:dio/dio.dart';
import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/api/api_client.dart';
import 'package:meeting_place_control_plane/src/api/control_plane_api_client.dart';
import 'package:meeting_place_control_plane/src/command/group_member_deregister/group_deregister_member_exception.dart';
import 'package:meeting_place_control_plane/src/command/group_member_deregister/group_deregister_member_handler.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockControlPlaneApiClient extends Mock
    implements ControlPlaneApiClient {}

class _MockDefaultApi extends Mock implements DefaultApi {}

class _MockLogger extends Mock implements ControlPlaneSDKLogger {}

class _FakeGroupDeregisterMemberInput extends Fake
    implements GroupDeregisterMemberInput {}

Response<GroupMemberDeregisterOK> _ok() => Response<GroupMemberDeregisterOK>(
  requestOptions: RequestOptions(path: '/'),
  data: GroupMemberDeregisterOKBuilder().build(),
  statusCode: 200,
);

DioException _dioError({required int statusCode, Map<String, dynamic>? data}) =>
    DioException(
      requestOptions: RequestOptions(path: '/v1/group-member-deregister'),
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
        requestOptions: RequestOptions(path: '/v1/group-member-deregister'),
        statusCode: statusCode,
        data: data,
      ),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeGroupDeregisterMemberInput());
  });

  late _MockControlPlaneApiClient apiClient;
  late _MockDefaultApi defaultApi;
  late _MockLogger logger;

  setUp(() {
    apiClient = _MockControlPlaneApiClient();
    defaultApi = _MockDefaultApi();
    logger = _MockLogger();

    when(() => apiClient.client).thenReturn(defaultApi);
  });

  GroupDeregisterMemberHandler newHandler() =>
      GroupDeregisterMemberHandler(apiClient: apiClient, logger: logger);

  GroupDeregisterMemberCommand newCommand() => GroupDeregisterMemberCommand(
    groupId: 'group-1',
    memberId: 'did:test:bob',
  );

  group('GroupDeregisterMemberHandler.handle', () {
    test('returns success on 2xx response', () async {
      when(
        () => defaultApi.groupMemberDeregister(
          groupDeregisterMemberInput: any(named: 'groupDeregisterMemberInput'),
        ),
      ).thenAnswer((_) async => _ok());

      final output = await newHandler().handle(newCommand());

      expect(output.success, isTrue);
    });

    test(
      '404 with errorCode "member_not_found" returns success (idempotent)',
      () async {
        when(
          () => defaultApi.groupMemberDeregister(
            groupDeregisterMemberInput: any(
              named: 'groupDeregisterMemberInput',
            ),
          ),
        ).thenThrow(
          _dioError(
            statusCode: HttpStatus.notFound,
            data: {'errorCode': 'member_not_found'},
          ),
        );

        final output = await newHandler().handle(newCommand());

        expect(output.success, isTrue);
      },
    );

    test('404 with a different errorCode rethrows DioException', () async {
      when(
        () => defaultApi.groupMemberDeregister(
          groupDeregisterMemberInput: any(named: 'groupDeregisterMemberInput'),
        ),
      ).thenThrow(
        _dioError(
          statusCode: HttpStatus.notFound,
          data: {'errorCode': 'group_not_found'},
        ),
      );

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            HttpStatus.notFound,
          ),
        ),
      );
    });

    test('404 with no errorCode rethrows DioException', () async {
      when(
        () => defaultApi.groupMemberDeregister(
          groupDeregisterMemberInput: any(named: 'groupDeregisterMemberInput'),
        ),
      ).thenThrow(_dioError(statusCode: HttpStatus.notFound));

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(isA<DioException>()),
      );
    });

    test(
      '410 with errorCode "group_deleted" returns success (idempotent)',
      () async {
        when(
          () => defaultApi.groupMemberDeregister(
            groupDeregisterMemberInput: any(
              named: 'groupDeregisterMemberInput',
            ),
          ),
        ).thenThrow(
          _dioError(
            statusCode: HttpStatus.gone,
            data: {'errorCode': 'group_deleted'},
          ),
        );

        final output = await newHandler().handle(newCommand());

        expect(output.success, isTrue);
      },
    );

    test('410 with a different errorCode rethrows DioException', () async {
      when(
        () => defaultApi.groupMemberDeregister(
          groupDeregisterMemberInput: any(named: 'groupDeregisterMemberInput'),
        ),
      ).thenThrow(
        _dioError(
          statusCode: HttpStatus.gone,
          data: {'errorCode': 'something_else'},
        ),
      );

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(isA<DioException>()),
      );
    });

    test(
      '''403 with errorCode "group_member_not_in_group" returns success (idempotent)''',
      () async {
        when(
          () => defaultApi.groupMemberDeregister(
            groupDeregisterMemberInput: any(
              named: 'groupDeregisterMemberInput',
            ),
          ),
        ).thenThrow(
          _dioError(
            statusCode: HttpStatus.forbidden,
            data: {'errorCode': 'group_member_not_in_group'},
          ),
        );

        final output = await newHandler().handle(newCommand());

        expect(output.success, isTrue);
      },
    );

    test('403 with a different errorCode rethrows DioException', () async {
      when(
        () => defaultApi.groupMemberDeregister(
          groupDeregisterMemberInput: any(named: 'groupDeregisterMemberInput'),
        ),
      ).thenThrow(
        _dioError(
          statusCode: HttpStatus.forbidden,
          data: {'errorCode': 'access_denied'},
        ),
      );

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(isA<DioException>()),
      );
    });

    test('other DioException is rethrown', () async {
      when(
        () => defaultApi.groupMemberDeregister(
          groupDeregisterMemberInput: any(named: 'groupDeregisterMemberInput'),
        ),
      ).thenThrow(_dioError(statusCode: HttpStatus.internalServerError));

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(isA<DioException>()),
      );
    });

    test('non-Dio error is wrapped as generic', () async {
      when(
        () => defaultApi.groupMemberDeregister(
          groupDeregisterMemberInput: any(named: 'groupDeregisterMemberInput'),
        ),
      ).thenThrow(StateError('boom'));

      await expectLater(
        newHandler().handle(newCommand()),
        throwsA(isA<GroupDeregisterException>()),
      );
    });
  });
}

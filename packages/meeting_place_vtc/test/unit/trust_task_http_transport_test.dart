import 'package:dio/dio.dart';
import 'package:meeting_place_vtc/meeting_place_vtc.dart';
import 'package:test/test.dart';

import '../utils/fakes.dart';

const _vtcDid = 'did:webvh:QmCommScid:community.example';

void main() {
  late FakeHttpAdapter adapter;
  late TrustTaskHttpTransport transport;
  final request = TrustTaskDocument.create(
    type: 'https://trusttasks.org/spec/auth/oob/claim/0.1',
    issuer: 'did:key:z6MkWallet',
    recipient: _vtcDid,
    payload: {'requestId': 'request-1'},
  );

  setUp(() {
    adapter = FakeHttpAdapter();
    transport = TrustTaskHttpTransport(dio: Dio()..httpClientAdapter = adapter);
  });

  group('TrustTaskHttpTransport', () {
    test('posts the document to <base>/trust-tasks without Origin', () async {
      adapter.answers.add((
        200,
        {
          'id': 'urn:uuid:answer',
          'type': 'https://trusttasks.org/spec/auth/oob/claim/0.1#response',
          'issuer': _vtcDid,
          'payload': {'requestId': 'request-1'},
        },
      ));

      final answer = await transport.send(
        Uri.parse('https://community.example/v1/'),
        request,
      );

      final sent = adapter.requests.single;
      expect(
        sent.options.uri.toString(),
        'https://community.example/v1/trust-tasks',
      );
      expect(sent.options.method, 'POST');
      expect(sent.options.headers.containsKey('Origin'), isFalse);
      expect(sent.options.headers.containsKey('Authorization'), isFalse);
      expect(sent.body, request.toJson());
      expect(answer.issuer, _vtcDid);
    });

    test('sends a bearer token when given one', () async {
      adapter.answers.add((
        200,
        {
          'id': 'urn:uuid:answer',
          'type': 'https://trusttasks.org/spec/auth/whoami/0.1#response',
          'issuer': 'did:webvh:QmVta:vta.example',
          'payload': <String, dynamic>{},
        },
      ));

      await transport.send(
        Uri.parse('https://vta.example'),
        request,
        bearerToken: 'token',
      );

      expect(
        adapter.requests.single.options.headers['Authorization'],
        'Bearer token',
      );
    });

    test('reads a Trust Task error as a refusal, whatever the status', () {
      adapter.answers.add((
        409,
        {
          'id': 'urn:uuid:error',
          'type': 'https://trusttasks.org/spec/trust-task-error/0.1',
          'issuer': _vtcDid,
          'payload': {'code': 'auth/oob/claim:alreadyClaimed'},
        },
      ));

      expect(
        transport.send(Uri.parse('https://community.example/v1'), request),
        throwsA(
          isA<MeetingPlaceVtcSDKException>()
              .having(
                (e) => e.code,
                'code',
                MeetingPlaceVtcSDKErrorCode.refused,
              )
              .having(
                (e) => e.refusalCode,
                'refusalCode',
                'auth/oob/claim:alreadyClaimed',
              ),
        ),
      );
    });

    test('fails when the answer is not a document', () {
      adapter.answers.add((429, 'Too Many Requests'));

      expect(
        transport.send(Uri.parse('https://community.example/v1'), request),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceVtcSDKErrorCode.transportFailed,
          ),
        ),
      );
    });

    test('fails when the service cannot be reached', () {
      adapter.failWith = DioExceptionType.connectionTimeout;

      expect(
        transport.send(Uri.parse('https://community.example/v1'), request),
        throwsA(
          isA<MeetingPlaceVtcSDKException>().having(
            (e) => e.code,
            'code',
            MeetingPlaceVtcSDKErrorCode.transportFailed,
          ),
        ),
      );
    });
  });
}

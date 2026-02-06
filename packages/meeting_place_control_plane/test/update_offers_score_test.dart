import 'package:built_value/json_object.dart';
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/api/control_plane_api_client.dart';
import 'package:meeting_place_control_plane/src/api/api_client/api/default_api.dart';
import 'package:meeting_place_control_plane/src/command/update_offers_score/update_offers_score.dart';
import 'package:meeting_place_control_plane/src/command/update_offers_score/update_offers_score_handler.dart';

class MockControlPlaneApiClient extends Mock implements ControlPlaneApiClient {}

class MockDefaultApi extends Mock implements DefaultApi {}

void main() {
  late MockControlPlaneApiClient mockApiClient;
  late MockDefaultApi mockDefaultApi;
  late UpdateOffersScoreHandler handler;

  setUp(() {
    mockApiClient = MockControlPlaneApiClient();
    mockDefaultApi = MockDefaultApi();
    when(() => mockApiClient.client).thenReturn(mockDefaultApi);

    handler = UpdateOffersScoreHandler(apiClient: mockApiClient);

    registerFallbackValue(RequestOptions(path: '/v1/update-offers-score'));
  });

  test(
    'handle calls API with score and offer links and returns updatedOffers and failedOffers',
    () async {
      when(
        () => mockDefaultApi.updateOffersScore(
          score: any(named: 'score'),
          mnemonics: any(named: 'mnemonics'),
        ),
      ).thenAnswer(
        (_) async => Response<JsonObject>(
          requestOptions: RequestOptions(path: '/v1/update-offers-score'),
          statusCode: 200,
          data: JsonObject(<String, dynamic>{
            'updatedOffers': ['link1', 'mnemonic2'],
            'failedOffers': <Map<String, dynamic>>[],
          }),
        ),
      );

      final command = UpdateOffersScoreCommand(
        score: 2,
        mnemonics: ['link1', 'mnemonic2'],
      );

      final result = await handler.handle(command);

      expect(result.updatedOffers, ['link1', 'mnemonic2']);
      expect(result.failedOffers, isEmpty);
      verify(
        () => mockDefaultApi.updateOffersScore(
          score: 2,
          mnemonics: ['link1', 'mnemonic2'],
        ),
      ).called(1);
    },
  );

  test('handle parses failedOffers from response', () async {
    when(
      () => mockDefaultApi.updateOffersScore(
        score: any(named: 'score'),
        mnemonics: any(named: 'mnemonics'),
      ),
    ).thenAnswer(
      (_) async => Response<JsonObject>(
        requestOptions: RequestOptions(path: '/v1/update-offers-score'),
        statusCode: 200,
        data: JsonObject(<String, dynamic>{
          'updatedOffers': ['ok1'],
          'failedOffers': <Map<String, dynamic>>[
            <String, dynamic>{'mnemonic': 'fail1'},
          ],
        }),
      ),
    );

    final result = await handler.handle(
      UpdateOffersScoreCommand(score: 1, mnemonics: ['ok1', 'fail1']),
    );

    expect(result.updatedOffers, ['ok1']);
    expect(result.failedOffers.length, 1);
    expect(result.failedOffers.first.mnemonic, 'fail1');
  });

  test('handle throws on non-2xx response', () async {
    when(
      () => mockDefaultApi.updateOffersScore(
        score: any(named: 'score'),
        mnemonics: any(named: 'mnemonics'),
      ),
    ).thenAnswer(
      (_) async => Response<JsonObject>(
        requestOptions: RequestOptions(path: '/v1/update-offers-score'),
        statusCode: 400,
        data: null,
      ),
    );

    final command = UpdateOffersScoreCommand(score: 1, mnemonics: ['offer1']);

    expect(() => handler.handle(command), throwsA(isA<DioException>()));
  });
}

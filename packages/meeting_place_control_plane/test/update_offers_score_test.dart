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
    'handle calls API with score and offer links and returns updated count',
    () async {
      when(
        () => mockDefaultApi.updateOffersScore(
          score: any(named: 'score'),
          offerLinksOrMnemonics: any(named: 'offerLinksOrMnemonics'),
        ),
      ).thenAnswer(
        (_) async => Response<JsonObject>(
          requestOptions: RequestOptions(path: '/v1/update-offers-score'),
          statusCode: 200,
          data: null,
        ),
      );

      final command = UpdateOffersScoreCommand(
        score: 2,
        offerLinksOrMnemonics: ['link1', 'mnemonic2'],
      );

      final result = await handler.handle(command);

      expect(result.updatedCount, 2);
      verify(
        () => mockDefaultApi.updateOffersScore(
          score: 2,
          offerLinksOrMnemonics: ['link1', 'mnemonic2'],
        ),
      ).called(1);
    },
  );

  test('handle throws on non-2xx response', () async {
    when(
      () => mockDefaultApi.updateOffersScore(
        score: any(named: 'score'),
        offerLinksOrMnemonics: any(named: 'offerLinksOrMnemonics'),
      ),
    ).thenAnswer(
      (_) async => Response<JsonObject>(
        requestOptions: RequestOptions(path: '/v1/update-offers-score'),
        statusCode: 400,
        data: null,
      ),
    );

    final command = UpdateOffersScoreCommand(
      score: 1,
      offerLinksOrMnemonics: ['offer1'],
    );

    expect(() => handler.handle(command), throwsA(isA<DioException>()));
  });
}

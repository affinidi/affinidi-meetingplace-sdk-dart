import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:meeting_place_control_plane/src/api/api_client/model/update_offers_score_input.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import 'package:meeting_place_control_plane/meeting_place_control_plane.dart';
import 'package:meeting_place_control_plane/src/api/control_plane_api_client.dart';
import 'package:meeting_place_control_plane/src/api/api_client/api/default_api.dart';
import 'package:meeting_place_control_plane/src/api/api_client/model/update_offers_score_ok.dart';
import 'package:meeting_place_control_plane/src/api/api_client/model/update_offers_score_ok_failed_offers_inner.dart';
import 'package:meeting_place_control_plane/src/command/update_offers_score/update_offers_score.dart';
import 'package:meeting_place_control_plane/src/command/update_offers_score/update_offers_score_handler.dart';

class MockControlPlaneApiClient extends Mock implements ControlPlaneApiClient {}

class MockDefaultApi extends Mock implements DefaultApi {}

void main() {
  late MockControlPlaneApiClient mockApiClient;
  late MockDefaultApi mockDefaultApi;
  late UpdateOffersScoreHandler handler;

  setUpAll(() {
    registerFallbackValue(
      UpdateOffersScoreInput(
        (b) => b
          ..score = 0
          ..mnemonics.replace([]),
      ),
    );
    registerFallbackValue(RequestOptions(path: '/v1/update-offers-score'));
  });

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
      final okResponse = UpdateOffersScoreOK(
        (b) => b
          ..updatedOffers.replace(['link1', 'mnemonic2'])
          ..failedOffers.replace(
            BuiltList<UpdateOffersScoreOKFailedOffersInner>(),
          ),
      );
      when(
        () => mockDefaultApi.updateOffersScore(
          updateOffersScoreInput: any(named: 'updateOffersScoreInput'),
        ),
      ).thenAnswer(
        (_) async => Response<UpdateOffersScoreOK>(
          requestOptions: RequestOptions(path: '/v1/update-offers-score'),
          statusCode: 200,
          data: okResponse,
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
          updateOffersScoreInput: any(named: 'updateOffersScoreInput'),
        ),
      ).called(1);
    },
  );

  test('handle parses failedOffers from response', () async {
    final failedOffer = UpdateOffersScoreOKFailedOffersInner(
      (b) => b..mnemonic = 'fail1',
    );
    final okResponse = UpdateOffersScoreOK(
      (b) => b
        ..updatedOffers.replace(['ok1'])
        ..failedOffers.replace([failedOffer]),
    );
    when(
      () => mockDefaultApi.updateOffersScore(
        updateOffersScoreInput: any(named: 'updateOffersScoreInput'),
      ),
    ).thenAnswer(
      (_) async => Response<UpdateOffersScoreOK>(
        requestOptions: RequestOptions(path: '/v1/update-offers-score'),
        statusCode: 200,
        data: okResponse,
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
        updateOffersScoreInput: any(named: 'updateOffersScoreInput'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/v1/update-offers-score'),
        response: Response<UpdateOffersScoreOK>(
          requestOptions: RequestOptions(path: '/v1/update-offers-score'),
          statusCode: 400,
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    final command = UpdateOffersScoreCommand(score: 1, mnemonics: ['offer1']);

    expect(() => handler.handle(command), throwsA(isA<DioException>()));
  });
}

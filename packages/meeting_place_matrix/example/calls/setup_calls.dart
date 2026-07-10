// ignore_for_file: avoid_print

import 'dart:io';

import 'package:matrix/matrix.dart' show DatabaseApi, MatrixSdkDatabase;
import 'package:meeting_place_matrix/meeting_place_matrix.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

/// Example showing how to initialize MeetingPlaceMatrixSDK with LiveKit
/// audio/video call support.
///
/// This example demonstrates:
/// - Setting up LiveKit configuration with JWT service URL and SFU URL
/// - Providing rtcDelegate and roomFactory for call functionality
/// - Listening to incoming call signals from the control plane
///
/// For a complete working example with repositories, see the other
/// examples in the package/example folder.

void main() async {
  // This shows the LiveKit-specific configuration only.
  // Complete SDK initialization requires:
  // - Initialized vodozemac (in your app's main.dart)
  // - Wallet with key storage
  // - Repository implementations for persistence
  // - RTC delegate and room factory for call functionality

  try {
    // Create MatrixConfig with LiveKit enabled
    final config = MatrixConfig(
      mediatorDid: Platform.environment['MEDIATOR_DID'] ?? 'did:test:mediator',
      controlPlaneDid:
          Platform.environment['CONTROL_PLANE_DID'] ?? 'did:test:controlplane',
      homeserver: Uri.parse(
          Platform.environment['MATRIX_HOMESERVER'] ?? 'http://localhost:8008'),
      databaseFactory: const CallbackMatrixDatabaseFactory(
        openDatabase: _openMatrixDatabase,
      ),
      deviceId: const Uuid().v4(),
      // LiveKit configuration — required for audio/video calls
      livekitServiceUrl: Uri.parse(
          Platform.environment['LIVEKIT_JWT_SERVICE_URL'] ??
              'https://livekit-jwt.example.com'),
      livekitSfuUrl: Uri.parse(Platform.environment['LIVEKIT_SFU_URL'] ??
          'wss://livekit.example.com'),
    );

    print('MatrixConfig created with LiveKit enabled');
    print('LiveKit JWT Service: ${config.livekitServiceUrl}');
    print('LiveKit SFU: ${config.livekitSfuUrl}');

    // When creating MeetingPlaceMatrixSDK, pass rtcDelegate and roomFactory:
    //
    // final sdk = await MeetingPlaceMatrixSDK.create(
    //   wallet: wallet,
    //   repositoryConfig: repositoryConfig,
    //   config: config,  // This config with LiveKit
    //   logger: logger,
    //   rtcDelegate: FlutterMatrixRTCDelegate(),        // Flutter only
    //   roomFactory: (_) => FlutterLiveKitRoom(),      // Flutter only
    // );
    //
    // Then listen to incoming call signals:
    // sdk.callSignals.listen((signal) {
    //   print('Call signal: $signal');
    // });
  } catch (e, st) {
    print('Error configuring LiveKit: $e\n$st');
  }
}

/// Opens the Matrix database for encryption and sync state.
Future<DatabaseApi> _openMatrixDatabase(MatrixDatabaseContext context) async {
  sqfliteFfiInit();
  final directory = Directory(
      '${Directory.systemTemp.path}/meeting_place_matrix_calls_example');
  await directory.create(recursive: true);
  return MatrixSdkDatabase.init(
    context.databaseName,
    database: await databaseFactoryFfi.openDatabase(
      '${directory.path}/${context.databaseName}.sqlite',
    ),
  );
}

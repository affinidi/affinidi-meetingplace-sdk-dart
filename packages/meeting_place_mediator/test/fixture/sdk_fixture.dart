import 'dart:io';

import 'package:dotenv/dotenv.dart';

final env = DotEnv(includePlatformEnvironment: true)..load(['test/.env']);

String getMediatorDid() =>
    Platform.environment['MEDIATOR_DID'] ??
    env['MEDIATOR_DID'] ??
    (throw Exception('MEDIATOR_DID not set in environment'));

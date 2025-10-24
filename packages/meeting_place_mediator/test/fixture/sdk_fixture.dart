import 'dart:io';

String getMediatorDid() =>
    Platform.environment['MEDIATOR_DID'] ??
    (throw Exception('MEDIATOR_DID not set in environment'));

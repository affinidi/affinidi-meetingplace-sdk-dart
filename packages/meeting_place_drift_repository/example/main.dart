import 'dart:io';

import 'package:meeting_place_drift_repository/meeting_place_drift_repository.dart';

void main() {
  final currDirectory = Directory.current;

  ConnectionOfferRepositoryDrift(
      database: ConnectionOfferDatabase(
    databaseName: 'sample-connection-offer-db-name',
    passphrase: 'sample-passphrase',
    directory: currDirectory,
  ));

  ChannelRepositoryDrift(
      database: ChannelDatabase(
    databaseName: 'sample-channel-db-name',
    passphrase: 'sample-passphrase',
    directory: currDirectory,
  ));

  GroupsRepositoryDrift(
      database: GroupsDatabase(
    databaseName: 'sample-group-name',
    passphrase: 'sample-passphrase',
    directory: currDirectory,
  ));

  ChatItemsRepositoryDrift(
      database: ChatItemsDatabase(
    databaseName: 'sample-chat-item-name',
    passphrase: 'sample-passphrase',
    directory: currDirectory,
  ));
}

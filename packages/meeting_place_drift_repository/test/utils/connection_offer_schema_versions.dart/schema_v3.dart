// dart format width=80
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class ConnectionOffers extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ConnectionOffers(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> offerName = GeneratedColumn<String>(
      'offer_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> offerLink = GeneratedColumn<String>(
      'offer_link', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> offerDescription = GeneratedColumn<String>(
      'offer_description', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> oobInvitationMessage =
      GeneratedColumn<String>('oob_invitation_message', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: true,
          $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> mnemonic = GeneratedColumn<String>(
      'mnemonic', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> expiresAt = GeneratedColumn<String>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
      'created_at', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> publishOfferDid = GeneratedColumn<String>(
      'publish_offer_did', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
      'type', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
      'status', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<int> maximumUsage = GeneratedColumn<int>(
      'maximum_usage', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> ownedByMe = GeneratedColumn<int>(
      'owned_by_me', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL CHECK (owned_by_me IN (0, 1))');
  late final GeneratedColumn<String> mediatorDid = GeneratedColumn<String>(
      'mediator_did', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> aliasId = GeneratedColumn<String>(
      'alias_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> outboundMessageId =
      GeneratedColumn<String>('outbound_message_id', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'NULL');
  late final GeneratedColumn<String> acceptOfferDid = GeneratedColumn<String>(
      'accept_offer_did', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> permanentChannelDid =
      GeneratedColumn<String>('permanent_channel_did', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'NULL');
  late final GeneratedColumn<String> otherPartyPermanentChannelDid =
      GeneratedColumn<String>(
          'other_party_permanent_channel_did', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'NULL');
  late final GeneratedColumn<String> notificationToken =
      GeneratedColumn<String>('notification_token', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'NULL');
  late final GeneratedColumn<String> otherPartyNotificationToken =
      GeneratedColumn<String>(
          'other_party_notification_token', aliasedName, true,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          $customConstraints: 'NULL');
  late final GeneratedColumn<String> externalRef = GeneratedColumn<String>(
      'external_ref', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
      'score', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  @override
  List<GeneratedColumn> get $columns => [
        id,
        offerName,
        offerLink,
        offerDescription,
        oobInvitationMessage,
        mnemonic,
        expiresAt,
        createdAt,
        publishOfferDid,
        type,
        status,
        maximumUsage,
        ownedByMe,
        mediatorDid,
        aliasId,
        outboundMessageId,
        acceptOfferDid,
        permanentChannelDid,
        otherPartyPermanentChannelDid,
        notificationToken,
        otherPartyNotificationToken,
        externalRef,
        score
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connection_offers';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  ConnectionOffers createAlias(String alias) {
    return ConnectionOffers(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['PRIMARY KEY(id)'];
  @override
  bool get dontWriteConstraints => true;
}

class ConnectionContactCards extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ConnectionContactCards(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT');
  late final GeneratedColumn<String> connectionOfferId = GeneratedColumn<
          String>('connection_offer_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints:
          'REFERENCES connection_offers(id)ON DELETE CASCADE UNIQUE NOT NULL');
  late final GeneratedColumn<String> did = GeneratedColumn<String>(
      'did', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> contactInfoJson = GeneratedColumn<String>(
      'contact_info_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL DEFAULT \'{}\'',
      defaultValue: const CustomExpression('\'{}\''));
  late final GeneratedColumn<String> profilePic = GeneratedColumn<String>(
      'profile_pic', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  @override
  List<GeneratedColumn> get $columns =>
      [id, connectionOfferId, did, type, contactInfoJson, profilePic];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connection_contact_cards';
  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  ConnectionContactCards createAlias(String alias) {
    return ConnectionContactCards(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class GroupConnectionOffers extends Table with TableInfo {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GroupConnectionOffers(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> connectionOfferId = GeneratedColumn<
          String>('connection_offer_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints:
          'REFERENCES connection_offers(id)ON DELETE CASCADE UNIQUE NOT NULL');
  late final GeneratedColumn<String> memberDid = GeneratedColumn<String>(
      'member_did', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'NOT NULL');
  late final GeneratedColumn<String> groupOwnerDid = GeneratedColumn<String>(
      'group_owner_did', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> groupDid = GeneratedColumn<String>(
      'group_did', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      $customConstraints: 'NULL');
  @override
  List<GeneratedColumn> get $columns => [
        connectionOfferId,
        memberDid,
        groupId,
        groupOwnerDid,
        groupDid,
        metadata
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_connection_offers';
  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Never map(Map<String, dynamic> data, {String? tablePrefix}) {
    throw UnsupportedError('TableInfo.map in schema verification code');
  }

  @override
  GroupConnectionOffers createAlias(String alias) {
    return GroupConnectionOffers(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class DatabaseAtV3 extends GeneratedDatabase {
  DatabaseAtV3(QueryExecutor e) : super(e);
  late final ConnectionOffers connectionOffers = ConnectionOffers(this);
  late final ConnectionContactCards connectionContactCards =
      ConnectionContactCards(this);
  late final GroupConnectionOffers groupConnectionOffers =
      GroupConnectionOffers(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [connectionOffers, connectionContactCards, groupConnectionOffers];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('connection_offers',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('connection_contact_cards', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('connection_offers',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('group_connection_offers', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
  @override
  int get schemaVersion => 3;
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

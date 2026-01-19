// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_offer_database.dart';

// ignore_for_file: type=lint
class $ConnectionOffersTable extends ConnectionOffers
    with TableInfo<$ConnectionOffersTable, ConnectionOffer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionOffersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: const Uuid().v4);
  static const VerificationMeta _offerNameMeta =
      const VerificationMeta('offerName');
  @override
  late final GeneratedColumn<String> offerName = GeneratedColumn<String>(
      'offer_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _offerLinkMeta =
      const VerificationMeta('offerLink');
  @override
  late final GeneratedColumn<String> offerLink = GeneratedColumn<String>(
      'offer_link', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _offerDescriptionMeta =
      const VerificationMeta('offerDescription');
  @override
  late final GeneratedColumn<String> offerDescription = GeneratedColumn<String>(
      'offer_description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _oobInvitationMessageMeta =
      const VerificationMeta('oobInvitationMessage');
  @override
  late final GeneratedColumn<String> oobInvitationMessage =
      GeneratedColumn<String>('oob_invitation_message', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mnemonicMeta =
      const VerificationMeta('mnemonic');
  @override
  late final GeneratedColumn<String> mnemonic = GeneratedColumn<String>(
      'mnemonic', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _expiresAtMeta =
      const VerificationMeta('expiresAt');
  @override
  late final GeneratedColumn<DateTime> expiresAt = GeneratedColumn<DateTime>(
      'expires_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _publishOfferDidMeta =
      const VerificationMeta('publishOfferDid');
  @override
  late final GeneratedColumn<String> publishOfferDid = GeneratedColumn<String>(
      'publish_offer_did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<ConnectionOfferType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ConnectionOfferType>(
              $ConnectionOffersTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<ConnectionOfferStatus, int>
      status = GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ConnectionOfferStatus>(
              $ConnectionOffersTable.$converterstatus);
  static const VerificationMeta _maximumUsageMeta =
      const VerificationMeta('maximumUsage');
  @override
  late final GeneratedColumn<int> maximumUsage = GeneratedColumn<int>(
      'maximum_usage', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _ownedByMeMeta =
      const VerificationMeta('ownedByMe');
  @override
  late final GeneratedColumn<bool> ownedByMe = GeneratedColumn<bool>(
      'owned_by_me', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("owned_by_me" IN (0, 1))'),
      clientDefault: () => false);
  static const VerificationMeta _mediatorDidMeta =
      const VerificationMeta('mediatorDid');
  @override
  late final GeneratedColumn<String> mediatorDid = GeneratedColumn<String>(
      'mediator_did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _aliasIdMeta =
      const VerificationMeta('aliasId');
  @override
  late final GeneratedColumn<String> aliasId = GeneratedColumn<String>(
      'alias_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _outboundMessageIdMeta =
      const VerificationMeta('outboundMessageId');
  @override
  late final GeneratedColumn<String> outboundMessageId =
      GeneratedColumn<String>('outbound_message_id', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _acceptOfferDidMeta =
      const VerificationMeta('acceptOfferDid');
  @override
  late final GeneratedColumn<String> acceptOfferDid = GeneratedColumn<String>(
      'accept_offer_did', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _permanentChannelDidMeta =
      const VerificationMeta('permanentChannelDid');
  @override
  late final GeneratedColumn<String> permanentChannelDid =
      GeneratedColumn<String>('permanent_channel_did', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _otherPartyPermanentChannelDidMeta =
      const VerificationMeta('otherPartyPermanentChannelDid');
  @override
  late final GeneratedColumn<String> otherPartyPermanentChannelDid =
      GeneratedColumn<String>(
          'other_party_permanent_channel_did', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notificationTokenMeta =
      const VerificationMeta('notificationToken');
  @override
  late final GeneratedColumn<String> notificationToken =
      GeneratedColumn<String>('notification_token', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _otherPartyNotificationTokenMeta =
      const VerificationMeta('otherPartyNotificationToken');
  @override
  late final GeneratedColumn<String> otherPartyNotificationToken =
      GeneratedColumn<String>(
          'other_party_notification_token', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _externalRefMeta =
      const VerificationMeta('externalRef');
  @override
  late final GeneratedColumn<String> externalRef = GeneratedColumn<String>(
      'external_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
        externalRef
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connection_offers';
  @override
  VerificationContext validateIntegrity(Insertable<ConnectionOffer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('offer_name')) {
      context.handle(_offerNameMeta,
          offerName.isAcceptableOrUnknown(data['offer_name']!, _offerNameMeta));
    } else if (isInserting) {
      context.missing(_offerNameMeta);
    }
    if (data.containsKey('offer_link')) {
      context.handle(_offerLinkMeta,
          offerLink.isAcceptableOrUnknown(data['offer_link']!, _offerLinkMeta));
    } else if (isInserting) {
      context.missing(_offerLinkMeta);
    }
    if (data.containsKey('offer_description')) {
      context.handle(
          _offerDescriptionMeta,
          offerDescription.isAcceptableOrUnknown(
              data['offer_description']!, _offerDescriptionMeta));
    }
    if (data.containsKey('oob_invitation_message')) {
      context.handle(
          _oobInvitationMessageMeta,
          oobInvitationMessage.isAcceptableOrUnknown(
              data['oob_invitation_message']!, _oobInvitationMessageMeta));
    } else if (isInserting) {
      context.missing(_oobInvitationMessageMeta);
    }
    if (data.containsKey('mnemonic')) {
      context.handle(_mnemonicMeta,
          mnemonic.isAcceptableOrUnknown(data['mnemonic']!, _mnemonicMeta));
    } else if (isInserting) {
      context.missing(_mnemonicMeta);
    }
    if (data.containsKey('expires_at')) {
      context.handle(_expiresAtMeta,
          expiresAt.isAcceptableOrUnknown(data['expires_at']!, _expiresAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('publish_offer_did')) {
      context.handle(
          _publishOfferDidMeta,
          publishOfferDid.isAcceptableOrUnknown(
              data['publish_offer_did']!, _publishOfferDidMeta));
    } else if (isInserting) {
      context.missing(_publishOfferDidMeta);
    }
    if (data.containsKey('maximum_usage')) {
      context.handle(
          _maximumUsageMeta,
          maximumUsage.isAcceptableOrUnknown(
              data['maximum_usage']!, _maximumUsageMeta));
    }
    if (data.containsKey('owned_by_me')) {
      context.handle(
          _ownedByMeMeta,
          ownedByMe.isAcceptableOrUnknown(
              data['owned_by_me']!, _ownedByMeMeta));
    }
    if (data.containsKey('mediator_did')) {
      context.handle(
          _mediatorDidMeta,
          mediatorDid.isAcceptableOrUnknown(
              data['mediator_did']!, _mediatorDidMeta));
    } else if (isInserting) {
      context.missing(_mediatorDidMeta);
    }
    if (data.containsKey('alias_id')) {
      context.handle(_aliasIdMeta,
          aliasId.isAcceptableOrUnknown(data['alias_id']!, _aliasIdMeta));
    }
    if (data.containsKey('outbound_message_id')) {
      context.handle(
          _outboundMessageIdMeta,
          outboundMessageId.isAcceptableOrUnknown(
              data['outbound_message_id']!, _outboundMessageIdMeta));
    }
    if (data.containsKey('accept_offer_did')) {
      context.handle(
          _acceptOfferDidMeta,
          acceptOfferDid.isAcceptableOrUnknown(
              data['accept_offer_did']!, _acceptOfferDidMeta));
    }
    if (data.containsKey('permanent_channel_did')) {
      context.handle(
          _permanentChannelDidMeta,
          permanentChannelDid.isAcceptableOrUnknown(
              data['permanent_channel_did']!, _permanentChannelDidMeta));
    }
    if (data.containsKey('other_party_permanent_channel_did')) {
      context.handle(
          _otherPartyPermanentChannelDidMeta,
          otherPartyPermanentChannelDid.isAcceptableOrUnknown(
              data['other_party_permanent_channel_did']!,
              _otherPartyPermanentChannelDidMeta));
    }
    if (data.containsKey('notification_token')) {
      context.handle(
          _notificationTokenMeta,
          notificationToken.isAcceptableOrUnknown(
              data['notification_token']!, _notificationTokenMeta));
    }
    if (data.containsKey('other_party_notification_token')) {
      context.handle(
          _otherPartyNotificationTokenMeta,
          otherPartyNotificationToken.isAcceptableOrUnknown(
              data['other_party_notification_token']!,
              _otherPartyNotificationTokenMeta));
    }
    if (data.containsKey('external_ref')) {
      context.handle(
          _externalRefMeta,
          externalRef.isAcceptableOrUnknown(
              data['external_ref']!, _externalRefMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectionOffer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectionOffer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      offerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}offer_name'])!,
      offerLink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}offer_link'])!,
      offerDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}offer_description']),
      oobInvitationMessage: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}oob_invitation_message'])!,
      mnemonic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mnemonic'])!,
      expiresAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}expires_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      publishOfferDid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}publish_offer_did'])!,
      type: $ConnectionOffersTable.$convertertype.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      status: $ConnectionOffersTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      maximumUsage: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}maximum_usage']),
      ownedByMe: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}owned_by_me'])!,
      mediatorDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mediator_did'])!,
      aliasId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}alias_id']),
      outboundMessageId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}outbound_message_id']),
      acceptOfferDid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}accept_offer_did']),
      permanentChannelDid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}permanent_channel_did']),
      otherPartyPermanentChannelDid: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}other_party_permanent_channel_did']),
      notificationToken: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}notification_token']),
      otherPartyNotificationToken: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}other_party_notification_token']),
      externalRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}external_ref']),
    );
  }

  @override
  $ConnectionOffersTable createAlias(String alias) {
    return $ConnectionOffersTable(attachedDatabase, alias);
  }

  static TypeConverter<ConnectionOfferType, int> $convertertype =
      const _ConnectionOfferTypeConverter();
  static TypeConverter<ConnectionOfferStatus, int> $converterstatus =
      const _ConnectionOfferStatusConverter();
}

class ConnectionOffer extends DataClass implements Insertable<ConnectionOffer> {
  /// Unique identifier for the connection offer.
  final String id;

  /// Name of the connection offer.
  final String offerName;

  /// Link to the connection offer.
  final String offerLink;

  /// Description of the connection offer.
  final String? offerDescription;

  /// Out-of-band invitation message associated with the offer.
  final String oobInvitationMessage;

  /// Mnemonic phrase for the connection offer.
  final String mnemonic;

  /// Expiration date and time of the connection offer.
  final DateTime? expiresAt;

  /// Creation date and time of the connection offer.
  final DateTime createdAt;

  /// DID of the publisher of the connection offer.
  final String publishOfferDid;

  /// Type of the connection offer.
  final ConnectionOfferType type;

  /// Status of the connection offer.
  final ConnectionOfferStatus status;

  /// Maximum usage count for the connection offer.
  final int? maximumUsage;

  /// Indicates if the offer is owned by the local user.
  final bool ownedByMe;

  /// The Mediator DID associated with the connection offer.
  final String mediatorDid;

  /// Alias ID for the connection offer.
  final String? aliasId;

  /// ID of the outbound message related to the connection offer.
  final String? outboundMessageId;

  /// DID of the accepted offer.
  final String? acceptOfferDid;

  /// Permanent DID of the connection channel.
  final String? permanentChannelDid;

  /// Permanent DID of the other party in the connection channel.
  final String? otherPartyPermanentChannelDid;

  /// Notification token for the connection offer.
  final String? notificationToken;

  /// Notification token for the other party in the connection offer.
  final String? otherPartyNotificationToken;

  /// External reference for the connection offer.
  final String? externalRef;
  const ConnectionOffer(
      {required this.id,
      required this.offerName,
      required this.offerLink,
      this.offerDescription,
      required this.oobInvitationMessage,
      required this.mnemonic,
      this.expiresAt,
      required this.createdAt,
      required this.publishOfferDid,
      required this.type,
      required this.status,
      this.maximumUsage,
      required this.ownedByMe,
      required this.mediatorDid,
      this.aliasId,
      this.outboundMessageId,
      this.acceptOfferDid,
      this.permanentChannelDid,
      this.otherPartyPermanentChannelDid,
      this.notificationToken,
      this.otherPartyNotificationToken,
      this.externalRef});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['offer_name'] = Variable<String>(offerName);
    map['offer_link'] = Variable<String>(offerLink);
    if (!nullToAbsent || offerDescription != null) {
      map['offer_description'] = Variable<String>(offerDescription);
    }
    map['oob_invitation_message'] = Variable<String>(oobInvitationMessage);
    map['mnemonic'] = Variable<String>(mnemonic);
    if (!nullToAbsent || expiresAt != null) {
      map['expires_at'] = Variable<DateTime>(expiresAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['publish_offer_did'] = Variable<String>(publishOfferDid);
    {
      map['type'] =
          Variable<int>($ConnectionOffersTable.$convertertype.toSql(type));
    }
    {
      map['status'] =
          Variable<int>($ConnectionOffersTable.$converterstatus.toSql(status));
    }
    if (!nullToAbsent || maximumUsage != null) {
      map['maximum_usage'] = Variable<int>(maximumUsage);
    }
    map['owned_by_me'] = Variable<bool>(ownedByMe);
    map['mediator_did'] = Variable<String>(mediatorDid);
    if (!nullToAbsent || aliasId != null) {
      map['alias_id'] = Variable<String>(aliasId);
    }
    if (!nullToAbsent || outboundMessageId != null) {
      map['outbound_message_id'] = Variable<String>(outboundMessageId);
    }
    if (!nullToAbsent || acceptOfferDid != null) {
      map['accept_offer_did'] = Variable<String>(acceptOfferDid);
    }
    if (!nullToAbsent || permanentChannelDid != null) {
      map['permanent_channel_did'] = Variable<String>(permanentChannelDid);
    }
    if (!nullToAbsent || otherPartyPermanentChannelDid != null) {
      map['other_party_permanent_channel_did'] =
          Variable<String>(otherPartyPermanentChannelDid);
    }
    if (!nullToAbsent || notificationToken != null) {
      map['notification_token'] = Variable<String>(notificationToken);
    }
    if (!nullToAbsent || otherPartyNotificationToken != null) {
      map['other_party_notification_token'] =
          Variable<String>(otherPartyNotificationToken);
    }
    if (!nullToAbsent || externalRef != null) {
      map['external_ref'] = Variable<String>(externalRef);
    }
    return map;
  }

  ConnectionOffersCompanion toCompanion(bool nullToAbsent) {
    return ConnectionOffersCompanion(
      id: Value(id),
      offerName: Value(offerName),
      offerLink: Value(offerLink),
      offerDescription: offerDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(offerDescription),
      oobInvitationMessage: Value(oobInvitationMessage),
      mnemonic: Value(mnemonic),
      expiresAt: expiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expiresAt),
      createdAt: Value(createdAt),
      publishOfferDid: Value(publishOfferDid),
      type: Value(type),
      status: Value(status),
      maximumUsage: maximumUsage == null && nullToAbsent
          ? const Value.absent()
          : Value(maximumUsage),
      ownedByMe: Value(ownedByMe),
      mediatorDid: Value(mediatorDid),
      aliasId: aliasId == null && nullToAbsent
          ? const Value.absent()
          : Value(aliasId),
      outboundMessageId: outboundMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(outboundMessageId),
      acceptOfferDid: acceptOfferDid == null && nullToAbsent
          ? const Value.absent()
          : Value(acceptOfferDid),
      permanentChannelDid: permanentChannelDid == null && nullToAbsent
          ? const Value.absent()
          : Value(permanentChannelDid),
      otherPartyPermanentChannelDid:
          otherPartyPermanentChannelDid == null && nullToAbsent
              ? const Value.absent()
              : Value(otherPartyPermanentChannelDid),
      notificationToken: notificationToken == null && nullToAbsent
          ? const Value.absent()
          : Value(notificationToken),
      otherPartyNotificationToken:
          otherPartyNotificationToken == null && nullToAbsent
              ? const Value.absent()
              : Value(otherPartyNotificationToken),
      externalRef: externalRef == null && nullToAbsent
          ? const Value.absent()
          : Value(externalRef),
    );
  }

  factory ConnectionOffer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectionOffer(
      id: serializer.fromJson<String>(json['id']),
      offerName: serializer.fromJson<String>(json['offerName']),
      offerLink: serializer.fromJson<String>(json['offerLink']),
      offerDescription: serializer.fromJson<String?>(json['offerDescription']),
      oobInvitationMessage:
          serializer.fromJson<String>(json['oobInvitationMessage']),
      mnemonic: serializer.fromJson<String>(json['mnemonic']),
      expiresAt: serializer.fromJson<DateTime?>(json['expiresAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      publishOfferDid: serializer.fromJson<String>(json['publishOfferDid']),
      type: serializer.fromJson<ConnectionOfferType>(json['type']),
      status: serializer.fromJson<ConnectionOfferStatus>(json['status']),
      maximumUsage: serializer.fromJson<int?>(json['maximumUsage']),
      ownedByMe: serializer.fromJson<bool>(json['ownedByMe']),
      mediatorDid: serializer.fromJson<String>(json['mediatorDid']),
      aliasId: serializer.fromJson<String?>(json['aliasId']),
      outboundMessageId:
          serializer.fromJson<String?>(json['outboundMessageId']),
      acceptOfferDid: serializer.fromJson<String?>(json['acceptOfferDid']),
      permanentChannelDid:
          serializer.fromJson<String?>(json['permanentChannelDid']),
      otherPartyPermanentChannelDid:
          serializer.fromJson<String?>(json['otherPartyPermanentChannelDid']),
      notificationToken:
          serializer.fromJson<String?>(json['notificationToken']),
      otherPartyNotificationToken:
          serializer.fromJson<String?>(json['otherPartyNotificationToken']),
      externalRef: serializer.fromJson<String?>(json['externalRef']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'offerName': serializer.toJson<String>(offerName),
      'offerLink': serializer.toJson<String>(offerLink),
      'offerDescription': serializer.toJson<String?>(offerDescription),
      'oobInvitationMessage': serializer.toJson<String>(oobInvitationMessage),
      'mnemonic': serializer.toJson<String>(mnemonic),
      'expiresAt': serializer.toJson<DateTime?>(expiresAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'publishOfferDid': serializer.toJson<String>(publishOfferDid),
      'type': serializer.toJson<ConnectionOfferType>(type),
      'status': serializer.toJson<ConnectionOfferStatus>(status),
      'maximumUsage': serializer.toJson<int?>(maximumUsage),
      'ownedByMe': serializer.toJson<bool>(ownedByMe),
      'mediatorDid': serializer.toJson<String>(mediatorDid),
      'aliasId': serializer.toJson<String?>(aliasId),
      'outboundMessageId': serializer.toJson<String?>(outboundMessageId),
      'acceptOfferDid': serializer.toJson<String?>(acceptOfferDid),
      'permanentChannelDid': serializer.toJson<String?>(permanentChannelDid),
      'otherPartyPermanentChannelDid':
          serializer.toJson<String?>(otherPartyPermanentChannelDid),
      'notificationToken': serializer.toJson<String?>(notificationToken),
      'otherPartyNotificationToken':
          serializer.toJson<String?>(otherPartyNotificationToken),
      'externalRef': serializer.toJson<String?>(externalRef),
    };
  }

  ConnectionOffer copyWith(
          {String? id,
          String? offerName,
          String? offerLink,
          Value<String?> offerDescription = const Value.absent(),
          String? oobInvitationMessage,
          String? mnemonic,
          Value<DateTime?> expiresAt = const Value.absent(),
          DateTime? createdAt,
          String? publishOfferDid,
          ConnectionOfferType? type,
          ConnectionOfferStatus? status,
          Value<int?> maximumUsage = const Value.absent(),
          bool? ownedByMe,
          String? mediatorDid,
          Value<String?> aliasId = const Value.absent(),
          Value<String?> outboundMessageId = const Value.absent(),
          Value<String?> acceptOfferDid = const Value.absent(),
          Value<String?> permanentChannelDid = const Value.absent(),
          Value<String?> otherPartyPermanentChannelDid = const Value.absent(),
          Value<String?> notificationToken = const Value.absent(),
          Value<String?> otherPartyNotificationToken = const Value.absent(),
          Value<String?> externalRef = const Value.absent()}) =>
      ConnectionOffer(
        id: id ?? this.id,
        offerName: offerName ?? this.offerName,
        offerLink: offerLink ?? this.offerLink,
        offerDescription: offerDescription.present
            ? offerDescription.value
            : this.offerDescription,
        oobInvitationMessage: oobInvitationMessage ?? this.oobInvitationMessage,
        mnemonic: mnemonic ?? this.mnemonic,
        expiresAt: expiresAt.present ? expiresAt.value : this.expiresAt,
        createdAt: createdAt ?? this.createdAt,
        publishOfferDid: publishOfferDid ?? this.publishOfferDid,
        type: type ?? this.type,
        status: status ?? this.status,
        maximumUsage:
            maximumUsage.present ? maximumUsage.value : this.maximumUsage,
        ownedByMe: ownedByMe ?? this.ownedByMe,
        mediatorDid: mediatorDid ?? this.mediatorDid,
        aliasId: aliasId.present ? aliasId.value : this.aliasId,
        outboundMessageId: outboundMessageId.present
            ? outboundMessageId.value
            : this.outboundMessageId,
        acceptOfferDid:
            acceptOfferDid.present ? acceptOfferDid.value : this.acceptOfferDid,
        permanentChannelDid: permanentChannelDid.present
            ? permanentChannelDid.value
            : this.permanentChannelDid,
        otherPartyPermanentChannelDid: otherPartyPermanentChannelDid.present
            ? otherPartyPermanentChannelDid.value
            : this.otherPartyPermanentChannelDid,
        notificationToken: notificationToken.present
            ? notificationToken.value
            : this.notificationToken,
        otherPartyNotificationToken: otherPartyNotificationToken.present
            ? otherPartyNotificationToken.value
            : this.otherPartyNotificationToken,
        externalRef: externalRef.present ? externalRef.value : this.externalRef,
      );
  ConnectionOffer copyWithCompanion(ConnectionOffersCompanion data) {
    return ConnectionOffer(
      id: data.id.present ? data.id.value : this.id,
      offerName: data.offerName.present ? data.offerName.value : this.offerName,
      offerLink: data.offerLink.present ? data.offerLink.value : this.offerLink,
      offerDescription: data.offerDescription.present
          ? data.offerDescription.value
          : this.offerDescription,
      oobInvitationMessage: data.oobInvitationMessage.present
          ? data.oobInvitationMessage.value
          : this.oobInvitationMessage,
      mnemonic: data.mnemonic.present ? data.mnemonic.value : this.mnemonic,
      expiresAt: data.expiresAt.present ? data.expiresAt.value : this.expiresAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      publishOfferDid: data.publishOfferDid.present
          ? data.publishOfferDid.value
          : this.publishOfferDid,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      maximumUsage: data.maximumUsage.present
          ? data.maximumUsage.value
          : this.maximumUsage,
      ownedByMe: data.ownedByMe.present ? data.ownedByMe.value : this.ownedByMe,
      mediatorDid:
          data.mediatorDid.present ? data.mediatorDid.value : this.mediatorDid,
      aliasId: data.aliasId.present ? data.aliasId.value : this.aliasId,
      outboundMessageId: data.outboundMessageId.present
          ? data.outboundMessageId.value
          : this.outboundMessageId,
      acceptOfferDid: data.acceptOfferDid.present
          ? data.acceptOfferDid.value
          : this.acceptOfferDid,
      permanentChannelDid: data.permanentChannelDid.present
          ? data.permanentChannelDid.value
          : this.permanentChannelDid,
      otherPartyPermanentChannelDid: data.otherPartyPermanentChannelDid.present
          ? data.otherPartyPermanentChannelDid.value
          : this.otherPartyPermanentChannelDid,
      notificationToken: data.notificationToken.present
          ? data.notificationToken.value
          : this.notificationToken,
      otherPartyNotificationToken: data.otherPartyNotificationToken.present
          ? data.otherPartyNotificationToken.value
          : this.otherPartyNotificationToken,
      externalRef:
          data.externalRef.present ? data.externalRef.value : this.externalRef,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionOffer(')
          ..write('id: $id, ')
          ..write('offerName: $offerName, ')
          ..write('offerLink: $offerLink, ')
          ..write('offerDescription: $offerDescription, ')
          ..write('oobInvitationMessage: $oobInvitationMessage, ')
          ..write('mnemonic: $mnemonic, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('publishOfferDid: $publishOfferDid, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('maximumUsage: $maximumUsage, ')
          ..write('ownedByMe: $ownedByMe, ')
          ..write('mediatorDid: $mediatorDid, ')
          ..write('aliasId: $aliasId, ')
          ..write('outboundMessageId: $outboundMessageId, ')
          ..write('acceptOfferDid: $acceptOfferDid, ')
          ..write('permanentChannelDid: $permanentChannelDid, ')
          ..write(
              'otherPartyPermanentChannelDid: $otherPartyPermanentChannelDid, ')
          ..write('notificationToken: $notificationToken, ')
          ..write('otherPartyNotificationToken: $otherPartyNotificationToken, ')
          ..write('externalRef: $externalRef')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
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
        externalRef
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectionOffer &&
          other.id == this.id &&
          other.offerName == this.offerName &&
          other.offerLink == this.offerLink &&
          other.offerDescription == this.offerDescription &&
          other.oobInvitationMessage == this.oobInvitationMessage &&
          other.mnemonic == this.mnemonic &&
          other.expiresAt == this.expiresAt &&
          other.createdAt == this.createdAt &&
          other.publishOfferDid == this.publishOfferDid &&
          other.type == this.type &&
          other.status == this.status &&
          other.maximumUsage == this.maximumUsage &&
          other.ownedByMe == this.ownedByMe &&
          other.mediatorDid == this.mediatorDid &&
          other.aliasId == this.aliasId &&
          other.outboundMessageId == this.outboundMessageId &&
          other.acceptOfferDid == this.acceptOfferDid &&
          other.permanentChannelDid == this.permanentChannelDid &&
          other.otherPartyPermanentChannelDid ==
              this.otherPartyPermanentChannelDid &&
          other.notificationToken == this.notificationToken &&
          other.otherPartyNotificationToken ==
              this.otherPartyNotificationToken &&
          other.externalRef == this.externalRef);
}

class ConnectionOffersCompanion extends UpdateCompanion<ConnectionOffer> {
  final Value<String> id;
  final Value<String> offerName;
  final Value<String> offerLink;
  final Value<String?> offerDescription;
  final Value<String> oobInvitationMessage;
  final Value<String> mnemonic;
  final Value<DateTime?> expiresAt;
  final Value<DateTime> createdAt;
  final Value<String> publishOfferDid;
  final Value<ConnectionOfferType> type;
  final Value<ConnectionOfferStatus> status;
  final Value<int?> maximumUsage;
  final Value<bool> ownedByMe;
  final Value<String> mediatorDid;
  final Value<String?> aliasId;
  final Value<String?> outboundMessageId;
  final Value<String?> acceptOfferDid;
  final Value<String?> permanentChannelDid;
  final Value<String?> otherPartyPermanentChannelDid;
  final Value<String?> notificationToken;
  final Value<String?> otherPartyNotificationToken;
  final Value<String?> externalRef;
  final Value<int> rowid;
  const ConnectionOffersCompanion({
    this.id = const Value.absent(),
    this.offerName = const Value.absent(),
    this.offerLink = const Value.absent(),
    this.offerDescription = const Value.absent(),
    this.oobInvitationMessage = const Value.absent(),
    this.mnemonic = const Value.absent(),
    this.expiresAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.publishOfferDid = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.maximumUsage = const Value.absent(),
    this.ownedByMe = const Value.absent(),
    this.mediatorDid = const Value.absent(),
    this.aliasId = const Value.absent(),
    this.outboundMessageId = const Value.absent(),
    this.acceptOfferDid = const Value.absent(),
    this.permanentChannelDid = const Value.absent(),
    this.otherPartyPermanentChannelDid = const Value.absent(),
    this.notificationToken = const Value.absent(),
    this.otherPartyNotificationToken = const Value.absent(),
    this.externalRef = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConnectionOffersCompanion.insert({
    this.id = const Value.absent(),
    required String offerName,
    required String offerLink,
    this.offerDescription = const Value.absent(),
    required String oobInvitationMessage,
    required String mnemonic,
    this.expiresAt = const Value.absent(),
    required DateTime createdAt,
    required String publishOfferDid,
    required ConnectionOfferType type,
    required ConnectionOfferStatus status,
    this.maximumUsage = const Value.absent(),
    this.ownedByMe = const Value.absent(),
    required String mediatorDid,
    this.aliasId = const Value.absent(),
    this.outboundMessageId = const Value.absent(),
    this.acceptOfferDid = const Value.absent(),
    this.permanentChannelDid = const Value.absent(),
    this.otherPartyPermanentChannelDid = const Value.absent(),
    this.notificationToken = const Value.absent(),
    this.otherPartyNotificationToken = const Value.absent(),
    this.externalRef = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : offerName = Value(offerName),
        offerLink = Value(offerLink),
        oobInvitationMessage = Value(oobInvitationMessage),
        mnemonic = Value(mnemonic),
        createdAt = Value(createdAt),
        publishOfferDid = Value(publishOfferDid),
        type = Value(type),
        status = Value(status),
        mediatorDid = Value(mediatorDid);
  static Insertable<ConnectionOffer> custom({
    Expression<String>? id,
    Expression<String>? offerName,
    Expression<String>? offerLink,
    Expression<String>? offerDescription,
    Expression<String>? oobInvitationMessage,
    Expression<String>? mnemonic,
    Expression<DateTime>? expiresAt,
    Expression<DateTime>? createdAt,
    Expression<String>? publishOfferDid,
    Expression<int>? type,
    Expression<int>? status,
    Expression<int>? maximumUsage,
    Expression<bool>? ownedByMe,
    Expression<String>? mediatorDid,
    Expression<String>? aliasId,
    Expression<String>? outboundMessageId,
    Expression<String>? acceptOfferDid,
    Expression<String>? permanentChannelDid,
    Expression<String>? otherPartyPermanentChannelDid,
    Expression<String>? notificationToken,
    Expression<String>? otherPartyNotificationToken,
    Expression<String>? externalRef,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (offerName != null) 'offer_name': offerName,
      if (offerLink != null) 'offer_link': offerLink,
      if (offerDescription != null) 'offer_description': offerDescription,
      if (oobInvitationMessage != null)
        'oob_invitation_message': oobInvitationMessage,
      if (mnemonic != null) 'mnemonic': mnemonic,
      if (expiresAt != null) 'expires_at': expiresAt,
      if (createdAt != null) 'created_at': createdAt,
      if (publishOfferDid != null) 'publish_offer_did': publishOfferDid,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (maximumUsage != null) 'maximum_usage': maximumUsage,
      if (ownedByMe != null) 'owned_by_me': ownedByMe,
      if (mediatorDid != null) 'mediator_did': mediatorDid,
      if (aliasId != null) 'alias_id': aliasId,
      if (outboundMessageId != null) 'outbound_message_id': outboundMessageId,
      if (acceptOfferDid != null) 'accept_offer_did': acceptOfferDid,
      if (permanentChannelDid != null)
        'permanent_channel_did': permanentChannelDid,
      if (otherPartyPermanentChannelDid != null)
        'other_party_permanent_channel_did': otherPartyPermanentChannelDid,
      if (notificationToken != null) 'notification_token': notificationToken,
      if (otherPartyNotificationToken != null)
        'other_party_notification_token': otherPartyNotificationToken,
      if (externalRef != null) 'external_ref': externalRef,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConnectionOffersCompanion copyWith(
      {Value<String>? id,
      Value<String>? offerName,
      Value<String>? offerLink,
      Value<String?>? offerDescription,
      Value<String>? oobInvitationMessage,
      Value<String>? mnemonic,
      Value<DateTime?>? expiresAt,
      Value<DateTime>? createdAt,
      Value<String>? publishOfferDid,
      Value<ConnectionOfferType>? type,
      Value<ConnectionOfferStatus>? status,
      Value<int?>? maximumUsage,
      Value<bool>? ownedByMe,
      Value<String>? mediatorDid,
      Value<String?>? aliasId,
      Value<String?>? outboundMessageId,
      Value<String?>? acceptOfferDid,
      Value<String?>? permanentChannelDid,
      Value<String?>? otherPartyPermanentChannelDid,
      Value<String?>? notificationToken,
      Value<String?>? otherPartyNotificationToken,
      Value<String?>? externalRef,
      Value<int>? rowid}) {
    return ConnectionOffersCompanion(
      id: id ?? this.id,
      offerName: offerName ?? this.offerName,
      offerLink: offerLink ?? this.offerLink,
      offerDescription: offerDescription ?? this.offerDescription,
      oobInvitationMessage: oobInvitationMessage ?? this.oobInvitationMessage,
      mnemonic: mnemonic ?? this.mnemonic,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      publishOfferDid: publishOfferDid ?? this.publishOfferDid,
      type: type ?? this.type,
      status: status ?? this.status,
      maximumUsage: maximumUsage ?? this.maximumUsage,
      ownedByMe: ownedByMe ?? this.ownedByMe,
      mediatorDid: mediatorDid ?? this.mediatorDid,
      aliasId: aliasId ?? this.aliasId,
      outboundMessageId: outboundMessageId ?? this.outboundMessageId,
      acceptOfferDid: acceptOfferDid ?? this.acceptOfferDid,
      permanentChannelDid: permanentChannelDid ?? this.permanentChannelDid,
      otherPartyPermanentChannelDid:
          otherPartyPermanentChannelDid ?? this.otherPartyPermanentChannelDid,
      notificationToken: notificationToken ?? this.notificationToken,
      otherPartyNotificationToken:
          otherPartyNotificationToken ?? this.otherPartyNotificationToken,
      externalRef: externalRef ?? this.externalRef,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (offerName.present) {
      map['offer_name'] = Variable<String>(offerName.value);
    }
    if (offerLink.present) {
      map['offer_link'] = Variable<String>(offerLink.value);
    }
    if (offerDescription.present) {
      map['offer_description'] = Variable<String>(offerDescription.value);
    }
    if (oobInvitationMessage.present) {
      map['oob_invitation_message'] =
          Variable<String>(oobInvitationMessage.value);
    }
    if (mnemonic.present) {
      map['mnemonic'] = Variable<String>(mnemonic.value);
    }
    if (expiresAt.present) {
      map['expires_at'] = Variable<DateTime>(expiresAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (publishOfferDid.present) {
      map['publish_offer_did'] = Variable<String>(publishOfferDid.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
          $ConnectionOffersTable.$convertertype.toSql(type.value));
    }
    if (status.present) {
      map['status'] = Variable<int>(
          $ConnectionOffersTable.$converterstatus.toSql(status.value));
    }
    if (maximumUsage.present) {
      map['maximum_usage'] = Variable<int>(maximumUsage.value);
    }
    if (ownedByMe.present) {
      map['owned_by_me'] = Variable<bool>(ownedByMe.value);
    }
    if (mediatorDid.present) {
      map['mediator_did'] = Variable<String>(mediatorDid.value);
    }
    if (aliasId.present) {
      map['alias_id'] = Variable<String>(aliasId.value);
    }
    if (outboundMessageId.present) {
      map['outbound_message_id'] = Variable<String>(outboundMessageId.value);
    }
    if (acceptOfferDid.present) {
      map['accept_offer_did'] = Variable<String>(acceptOfferDid.value);
    }
    if (permanentChannelDid.present) {
      map['permanent_channel_did'] =
          Variable<String>(permanentChannelDid.value);
    }
    if (otherPartyPermanentChannelDid.present) {
      map['other_party_permanent_channel_did'] =
          Variable<String>(otherPartyPermanentChannelDid.value);
    }
    if (notificationToken.present) {
      map['notification_token'] = Variable<String>(notificationToken.value);
    }
    if (otherPartyNotificationToken.present) {
      map['other_party_notification_token'] =
          Variable<String>(otherPartyNotificationToken.value);
    }
    if (externalRef.present) {
      map['external_ref'] = Variable<String>(externalRef.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionOffersCompanion(')
          ..write('id: $id, ')
          ..write('offerName: $offerName, ')
          ..write('offerLink: $offerLink, ')
          ..write('offerDescription: $offerDescription, ')
          ..write('oobInvitationMessage: $oobInvitationMessage, ')
          ..write('mnemonic: $mnemonic, ')
          ..write('expiresAt: $expiresAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('publishOfferDid: $publishOfferDid, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('maximumUsage: $maximumUsage, ')
          ..write('ownedByMe: $ownedByMe, ')
          ..write('mediatorDid: $mediatorDid, ')
          ..write('aliasId: $aliasId, ')
          ..write('outboundMessageId: $outboundMessageId, ')
          ..write('acceptOfferDid: $acceptOfferDid, ')
          ..write('permanentChannelDid: $permanentChannelDid, ')
          ..write(
              'otherPartyPermanentChannelDid: $otherPartyPermanentChannelDid, ')
          ..write('notificationToken: $notificationToken, ')
          ..write('otherPartyNotificationToken: $otherPartyNotificationToken, ')
          ..write('externalRef: $externalRef, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConnectionContactCardsTable extends ConnectionContactCards
    with TableInfo<$ConnectionContactCardsTable, ConnectionContactCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConnectionContactCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _connectionOfferIdMeta =
      const VerificationMeta('connectionOfferId');
  @override
  late final GeneratedColumn<String> connectionOfferId = GeneratedColumn<
          String>('connection_offer_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints:
          'REFERENCES connection_offers(id) ON DELETE CASCADE UNIQUE NOT NULL');
  static const VerificationMeta _didMeta = const VerificationMeta('did');
  @override
  late final GeneratedColumn<String> did = GeneratedColumn<String>(
      'did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _firstNameMeta =
      const VerificationMeta('firstName');
  @override
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
      'first_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lastNameMeta =
      const VerificationMeta('lastName');
  @override
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
      'last_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mobileMeta = const VerificationMeta('mobile');
  @override
  late final GeneratedColumn<String> mobile = GeneratedColumn<String>(
      'mobile', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _profilePicMeta =
      const VerificationMeta('profilePic');
  @override
  late final GeneratedColumn<String> profilePic = GeneratedColumn<String>(
      'profile_pic', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _meetingplaceIdentityCardColorMeta =
      const VerificationMeta('meetingplaceIdentityCardColor');
  @override
  late final GeneratedColumn<String> meetingplaceIdentityCardColor =
      GeneratedColumn<String>(
          'meetingplace_identity_card_color', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        connectionOfferId,
        did,
        type,
        firstName,
        lastName,
        email,
        mobile,
        profilePic,
        meetingplaceIdentityCardColor
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'connection_contact_cards';
  @override
  VerificationContext validateIntegrity(
      Insertable<ConnectionContactCard> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('connection_offer_id')) {
      context.handle(
          _connectionOfferIdMeta,
          connectionOfferId.isAcceptableOrUnknown(
              data['connection_offer_id']!, _connectionOfferIdMeta));
    } else if (isInserting) {
      context.missing(_connectionOfferIdMeta);
    }
    if (data.containsKey('did')) {
      context.handle(
          _didMeta, did.isAcceptableOrUnknown(data['did']!, _didMeta));
    } else if (isInserting) {
      context.missing(_didMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(_firstNameMeta,
          firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta));
    } else if (isInserting) {
      context.missing(_firstNameMeta);
    }
    if (data.containsKey('last_name')) {
      context.handle(_lastNameMeta,
          lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta));
    } else if (isInserting) {
      context.missing(_lastNameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('mobile')) {
      context.handle(_mobileMeta,
          mobile.isAcceptableOrUnknown(data['mobile']!, _mobileMeta));
    } else if (isInserting) {
      context.missing(_mobileMeta);
    }
    if (data.containsKey('profile_pic')) {
      context.handle(
          _profilePicMeta,
          profilePic.isAcceptableOrUnknown(
              data['profile_pic']!, _profilePicMeta));
    } else if (isInserting) {
      context.missing(_profilePicMeta);
    }
    if (data.containsKey('meetingplace_identity_card_color')) {
      context.handle(
          _meetingplaceIdentityCardColorMeta,
          meetingplaceIdentityCardColor.isAcceptableOrUnknown(
              data['meetingplace_identity_card_color']!,
              _meetingplaceIdentityCardColorMeta));
    } else if (isInserting) {
      context.missing(_meetingplaceIdentityCardColorMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConnectionContactCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConnectionContactCard(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      connectionOfferId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}connection_offer_id'])!,
      did: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}did'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      firstName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}first_name'])!,
      lastName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last_name'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      mobile: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mobile'])!,
      profilePic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_pic'])!,
      meetingplaceIdentityCardColor: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}meetingplace_identity_card_color'])!,
    );
  }

  @override
  $ConnectionContactCardsTable createAlias(String alias) {
    return $ConnectionContactCardsTable(attachedDatabase, alias);
  }
}

class ConnectionContactCard extends DataClass
    implements Insertable<ConnectionContactCard> {
  /// Auto-incrementing ID for the contact card.
  final int id;

  /// The connection offer ID this contact card is associated with.
  final String connectionOfferId;

  /// DID of the contact.
  final String did;

  /// Type of the contact.
  final String type;

  /// First name of the contact.
  final String firstName;

  /// Last name of the contact.
  final String lastName;

  /// Email address of the contact.
  final String email;

  /// Mobile number of the contact.
  final String mobile;

  /// Profile picture of the contact.
  final String profilePic;

  /// MeetingPlace identity card color of the contact.
  final String meetingplaceIdentityCardColor;
  const ConnectionContactCard(
      {required this.id,
      required this.connectionOfferId,
      required this.did,
      required this.type,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.mobile,
      required this.profilePic,
      required this.meetingplaceIdentityCardColor});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['connection_offer_id'] = Variable<String>(connectionOfferId);
    map['did'] = Variable<String>(did);
    map['type'] = Variable<String>(type);
    map['first_name'] = Variable<String>(firstName);
    map['last_name'] = Variable<String>(lastName);
    map['email'] = Variable<String>(email);
    map['mobile'] = Variable<String>(mobile);
    map['profile_pic'] = Variable<String>(profilePic);
    map['meetingplace_identity_card_color'] =
        Variable<String>(meetingplaceIdentityCardColor);
    return map;
  }

  ConnectionContactCardsCompanion toCompanion(bool nullToAbsent) {
    return ConnectionContactCardsCompanion(
      id: Value(id),
      connectionOfferId: Value(connectionOfferId),
      did: Value(did),
      type: Value(type),
      firstName: Value(firstName),
      lastName: Value(lastName),
      email: Value(email),
      mobile: Value(mobile),
      profilePic: Value(profilePic),
      meetingplaceIdentityCardColor: Value(meetingplaceIdentityCardColor),
    );
  }

  factory ConnectionContactCard.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConnectionContactCard(
      id: serializer.fromJson<int>(json['id']),
      connectionOfferId: serializer.fromJson<String>(json['connectionOfferId']),
      did: serializer.fromJson<String>(json['did']),
      type: serializer.fromJson<String>(json['type']),
      firstName: serializer.fromJson<String>(json['firstName']),
      lastName: serializer.fromJson<String>(json['lastName']),
      email: serializer.fromJson<String>(json['email']),
      mobile: serializer.fromJson<String>(json['mobile']),
      profilePic: serializer.fromJson<String>(json['profilePic']),
      meetingplaceIdentityCardColor:
          serializer.fromJson<String>(json['meetingplaceIdentityCardColor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'connectionOfferId': serializer.toJson<String>(connectionOfferId),
      'did': serializer.toJson<String>(did),
      'type': serializer.toJson<String>(type),
      'firstName': serializer.toJson<String>(firstName),
      'lastName': serializer.toJson<String>(lastName),
      'email': serializer.toJson<String>(email),
      'mobile': serializer.toJson<String>(mobile),
      'profilePic': serializer.toJson<String>(profilePic),
      'meetingplaceIdentityCardColor':
          serializer.toJson<String>(meetingplaceIdentityCardColor),
    };
  }

  ConnectionContactCard copyWith(
          {int? id,
          String? connectionOfferId,
          String? did,
          String? type,
          String? firstName,
          String? lastName,
          String? email,
          String? mobile,
          String? profilePic,
          String? meetingplaceIdentityCardColor}) =>
      ConnectionContactCard(
        id: id ?? this.id,
        connectionOfferId: connectionOfferId ?? this.connectionOfferId,
        did: did ?? this.did,
        type: type ?? this.type,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        email: email ?? this.email,
        mobile: mobile ?? this.mobile,
        profilePic: profilePic ?? this.profilePic,
        meetingplaceIdentityCardColor:
            meetingplaceIdentityCardColor ?? this.meetingplaceIdentityCardColor,
      );
  ConnectionContactCard copyWithCompanion(
      ConnectionContactCardsCompanion data) {
    return ConnectionContactCard(
      id: data.id.present ? data.id.value : this.id,
      connectionOfferId: data.connectionOfferId.present
          ? data.connectionOfferId.value
          : this.connectionOfferId,
      did: data.did.present ? data.did.value : this.did,
      type: data.type.present ? data.type.value : this.type,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      email: data.email.present ? data.email.value : this.email,
      mobile: data.mobile.present ? data.mobile.value : this.mobile,
      profilePic:
          data.profilePic.present ? data.profilePic.value : this.profilePic,
      meetingplaceIdentityCardColor: data.meetingplaceIdentityCardColor.present
          ? data.meetingplaceIdentityCardColor.value
          : this.meetingplaceIdentityCardColor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionContactCard(')
          ..write('id: $id, ')
          ..write('connectionOfferId: $connectionOfferId, ')
          ..write('did: $did, ')
          ..write('type: $type, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('email: $email, ')
          ..write('mobile: $mobile, ')
          ..write('profilePic: $profilePic, ')
          ..write(
              'meetingplaceIdentityCardColor: $meetingplaceIdentityCardColor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, connectionOfferId, did, type, firstName,
      lastName, email, mobile, profilePic, meetingplaceIdentityCardColor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConnectionContactCard &&
          other.id == this.id &&
          other.connectionOfferId == this.connectionOfferId &&
          other.did == this.did &&
          other.type == this.type &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.email == this.email &&
          other.mobile == this.mobile &&
          other.profilePic == this.profilePic &&
          other.meetingplaceIdentityCardColor ==
              this.meetingplaceIdentityCardColor);
}

class ConnectionContactCardsCompanion
    extends UpdateCompanion<ConnectionContactCard> {
  final Value<int> id;
  final Value<String> connectionOfferId;
  final Value<String> did;
  final Value<String> type;
  final Value<String> firstName;
  final Value<String> lastName;
  final Value<String> email;
  final Value<String> mobile;
  final Value<String> profilePic;
  final Value<String> meetingplaceIdentityCardColor;
  const ConnectionContactCardsCompanion({
    this.id = const Value.absent(),
    this.connectionOfferId = const Value.absent(),
    this.did = const Value.absent(),
    this.type = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.email = const Value.absent(),
    this.mobile = const Value.absent(),
    this.profilePic = const Value.absent(),
    this.meetingplaceIdentityCardColor = const Value.absent(),
  });
  ConnectionContactCardsCompanion.insert({
    this.id = const Value.absent(),
    required String connectionOfferId,
    required String did,
    required String type,
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String profilePic,
    required String meetingplaceIdentityCardColor,
  })  : connectionOfferId = Value(connectionOfferId),
        did = Value(did),
        type = Value(type),
        firstName = Value(firstName),
        lastName = Value(lastName),
        email = Value(email),
        mobile = Value(mobile),
        profilePic = Value(profilePic),
        meetingplaceIdentityCardColor = Value(meetingplaceIdentityCardColor);
  static Insertable<ConnectionContactCard> custom({
    Expression<int>? id,
    Expression<String>? connectionOfferId,
    Expression<String>? did,
    Expression<String>? type,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? email,
    Expression<String>? mobile,
    Expression<String>? profilePic,
    Expression<String>? meetingplaceIdentityCardColor,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (connectionOfferId != null) 'connection_offer_id': connectionOfferId,
      if (did != null) 'did': did,
      if (type != null) 'type': type,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (mobile != null) 'mobile': mobile,
      if (profilePic != null) 'profile_pic': profilePic,
      if (meetingplaceIdentityCardColor != null)
        'meetingplace_identity_card_color': meetingplaceIdentityCardColor,
    });
  }

  ConnectionContactCardsCompanion copyWith(
      {Value<int>? id,
      Value<String>? connectionOfferId,
      Value<String>? did,
      Value<String>? type,
      Value<String>? firstName,
      Value<String>? lastName,
      Value<String>? email,
      Value<String>? mobile,
      Value<String>? profilePic,
      Value<String>? meetingplaceIdentityCardColor}) {
    return ConnectionContactCardsCompanion(
      id: id ?? this.id,
      connectionOfferId: connectionOfferId ?? this.connectionOfferId,
      did: did ?? this.did,
      type: type ?? this.type,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      profilePic: profilePic ?? this.profilePic,
      meetingplaceIdentityCardColor:
          meetingplaceIdentityCardColor ?? this.meetingplaceIdentityCardColor,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (connectionOfferId.present) {
      map['connection_offer_id'] = Variable<String>(connectionOfferId.value);
    }
    if (did.present) {
      map['did'] = Variable<String>(did.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (mobile.present) {
      map['mobile'] = Variable<String>(mobile.value);
    }
    if (profilePic.present) {
      map['profile_pic'] = Variable<String>(profilePic.value);
    }
    if (meetingplaceIdentityCardColor.present) {
      map['meetingplace_identity_card_color'] =
          Variable<String>(meetingplaceIdentityCardColor.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConnectionContactCardsCompanion(')
          ..write('id: $id, ')
          ..write('connectionOfferId: $connectionOfferId, ')
          ..write('did: $did, ')
          ..write('type: $type, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('email: $email, ')
          ..write('mobile: $mobile, ')
          ..write('profilePic: $profilePic, ')
          ..write(
              'meetingplaceIdentityCardColor: $meetingplaceIdentityCardColor')
          ..write(')'))
        .toString();
  }
}

class $GroupConnectionOffersTable extends GroupConnectionOffers
    with TableInfo<$GroupConnectionOffersTable, GroupConnectionOffer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupConnectionOffersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _connectionOfferIdMeta =
      const VerificationMeta('connectionOfferId');
  @override
  late final GeneratedColumn<String> connectionOfferId = GeneratedColumn<
          String>('connection_offer_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints:
          'REFERENCES connection_offers(id) ON DELETE CASCADE UNIQUE NOT NULL');
  static const VerificationMeta _memberDidMeta =
      const VerificationMeta('memberDid');
  @override
  late final GeneratedColumn<String> memberDid = GeneratedColumn<String>(
      'member_did', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupIdMeta =
      const VerificationMeta('groupId');
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
      'group_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupOwnerDidMeta =
      const VerificationMeta('groupOwnerDid');
  @override
  late final GeneratedColumn<String> groupOwnerDid = GeneratedColumn<String>(
      'group_owner_did', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _groupDidMeta =
      const VerificationMeta('groupDid');
  @override
  late final GeneratedColumn<String> groupDid = GeneratedColumn<String>(
      'group_did', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _metadataMeta =
      const VerificationMeta('metadata');
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
      'metadata', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  VerificationContext validateIntegrity(
      Insertable<GroupConnectionOffer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('connection_offer_id')) {
      context.handle(
          _connectionOfferIdMeta,
          connectionOfferId.isAcceptableOrUnknown(
              data['connection_offer_id']!, _connectionOfferIdMeta));
    } else if (isInserting) {
      context.missing(_connectionOfferIdMeta);
    }
    if (data.containsKey('member_did')) {
      context.handle(_memberDidMeta,
          memberDid.isAcceptableOrUnknown(data['member_did']!, _memberDidMeta));
    }
    if (data.containsKey('group_id')) {
      context.handle(_groupIdMeta,
          groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta));
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('group_owner_did')) {
      context.handle(
          _groupOwnerDidMeta,
          groupOwnerDid.isAcceptableOrUnknown(
              data['group_owner_did']!, _groupOwnerDidMeta));
    }
    if (data.containsKey('group_did')) {
      context.handle(_groupDidMeta,
          groupDid.isAcceptableOrUnknown(data['group_did']!, _groupDidMeta));
    }
    if (data.containsKey('metadata')) {
      context.handle(_metadataMeta,
          metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  GroupConnectionOffer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupConnectionOffer(
      connectionOfferId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}connection_offer_id'])!,
      memberDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}member_did']),
      groupId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_id'])!,
      groupOwnerDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_owner_did']),
      groupDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_did']),
      metadata: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}metadata']),
    );
  }

  @override
  $GroupConnectionOffersTable createAlias(String alias) {
    return $GroupConnectionOffersTable(attachedDatabase, alias);
  }
}

class GroupConnectionOffer extends DataClass
    implements Insertable<GroupConnectionOffer> {
  ///The connection offer ID this group connection offer is associated with.
  final String connectionOfferId;

  /// The member DID associated with the group connection offer.
  final String? memberDid;

  /// The group ID associated with the group connection offer.
  final String groupId;

  ///The group's owner DID.
  final String? groupOwnerDid;

  /// The group's DID.
  final String? groupDid;

  /// Additional metadata for the group connection offer.
  final String? metadata;
  const GroupConnectionOffer(
      {required this.connectionOfferId,
      this.memberDid,
      required this.groupId,
      this.groupOwnerDid,
      this.groupDid,
      this.metadata});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['connection_offer_id'] = Variable<String>(connectionOfferId);
    if (!nullToAbsent || memberDid != null) {
      map['member_did'] = Variable<String>(memberDid);
    }
    map['group_id'] = Variable<String>(groupId);
    if (!nullToAbsent || groupOwnerDid != null) {
      map['group_owner_did'] = Variable<String>(groupOwnerDid);
    }
    if (!nullToAbsent || groupDid != null) {
      map['group_did'] = Variable<String>(groupDid);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  GroupConnectionOffersCompanion toCompanion(bool nullToAbsent) {
    return GroupConnectionOffersCompanion(
      connectionOfferId: Value(connectionOfferId),
      memberDid: memberDid == null && nullToAbsent
          ? const Value.absent()
          : Value(memberDid),
      groupId: Value(groupId),
      groupOwnerDid: groupOwnerDid == null && nullToAbsent
          ? const Value.absent()
          : Value(groupOwnerDid),
      groupDid: groupDid == null && nullToAbsent
          ? const Value.absent()
          : Value(groupDid),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory GroupConnectionOffer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupConnectionOffer(
      connectionOfferId: serializer.fromJson<String>(json['connectionOfferId']),
      memberDid: serializer.fromJson<String?>(json['memberDid']),
      groupId: serializer.fromJson<String>(json['groupId']),
      groupOwnerDid: serializer.fromJson<String?>(json['groupOwnerDid']),
      groupDid: serializer.fromJson<String?>(json['groupDid']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'connectionOfferId': serializer.toJson<String>(connectionOfferId),
      'memberDid': serializer.toJson<String?>(memberDid),
      'groupId': serializer.toJson<String>(groupId),
      'groupOwnerDid': serializer.toJson<String?>(groupOwnerDid),
      'groupDid': serializer.toJson<String?>(groupDid),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  GroupConnectionOffer copyWith(
          {String? connectionOfferId,
          Value<String?> memberDid = const Value.absent(),
          String? groupId,
          Value<String?> groupOwnerDid = const Value.absent(),
          Value<String?> groupDid = const Value.absent(),
          Value<String?> metadata = const Value.absent()}) =>
      GroupConnectionOffer(
        connectionOfferId: connectionOfferId ?? this.connectionOfferId,
        memberDid: memberDid.present ? memberDid.value : this.memberDid,
        groupId: groupId ?? this.groupId,
        groupOwnerDid:
            groupOwnerDid.present ? groupOwnerDid.value : this.groupOwnerDid,
        groupDid: groupDid.present ? groupDid.value : this.groupDid,
        metadata: metadata.present ? metadata.value : this.metadata,
      );
  GroupConnectionOffer copyWithCompanion(GroupConnectionOffersCompanion data) {
    return GroupConnectionOffer(
      connectionOfferId: data.connectionOfferId.present
          ? data.connectionOfferId.value
          : this.connectionOfferId,
      memberDid: data.memberDid.present ? data.memberDid.value : this.memberDid,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      groupOwnerDid: data.groupOwnerDid.present
          ? data.groupOwnerDid.value
          : this.groupOwnerDid,
      groupDid: data.groupDid.present ? data.groupDid.value : this.groupDid,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupConnectionOffer(')
          ..write('connectionOfferId: $connectionOfferId, ')
          ..write('memberDid: $memberDid, ')
          ..write('groupId: $groupId, ')
          ..write('groupOwnerDid: $groupOwnerDid, ')
          ..write('groupDid: $groupDid, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      connectionOfferId, memberDid, groupId, groupOwnerDid, groupDid, metadata);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupConnectionOffer &&
          other.connectionOfferId == this.connectionOfferId &&
          other.memberDid == this.memberDid &&
          other.groupId == this.groupId &&
          other.groupOwnerDid == this.groupOwnerDid &&
          other.groupDid == this.groupDid &&
          other.metadata == this.metadata);
}

class GroupConnectionOffersCompanion
    extends UpdateCompanion<GroupConnectionOffer> {
  final Value<String> connectionOfferId;
  final Value<String?> memberDid;
  final Value<String> groupId;
  final Value<String?> groupOwnerDid;
  final Value<String?> groupDid;
  final Value<String?> metadata;
  final Value<int> rowid;
  const GroupConnectionOffersCompanion({
    this.connectionOfferId = const Value.absent(),
    this.memberDid = const Value.absent(),
    this.groupId = const Value.absent(),
    this.groupOwnerDid = const Value.absent(),
    this.groupDid = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupConnectionOffersCompanion.insert({
    required String connectionOfferId,
    this.memberDid = const Value.absent(),
    required String groupId,
    this.groupOwnerDid = const Value.absent(),
    this.groupDid = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : connectionOfferId = Value(connectionOfferId),
        groupId = Value(groupId);
  static Insertable<GroupConnectionOffer> custom({
    Expression<String>? connectionOfferId,
    Expression<String>? memberDid,
    Expression<String>? groupId,
    Expression<String>? groupOwnerDid,
    Expression<String>? groupDid,
    Expression<String>? metadata,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (connectionOfferId != null) 'connection_offer_id': connectionOfferId,
      if (memberDid != null) 'member_did': memberDid,
      if (groupId != null) 'group_id': groupId,
      if (groupOwnerDid != null) 'group_owner_did': groupOwnerDid,
      if (groupDid != null) 'group_did': groupDid,
      if (metadata != null) 'metadata': metadata,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupConnectionOffersCompanion copyWith(
      {Value<String>? connectionOfferId,
      Value<String?>? memberDid,
      Value<String>? groupId,
      Value<String?>? groupOwnerDid,
      Value<String?>? groupDid,
      Value<String?>? metadata,
      Value<int>? rowid}) {
    return GroupConnectionOffersCompanion(
      connectionOfferId: connectionOfferId ?? this.connectionOfferId,
      memberDid: memberDid ?? this.memberDid,
      groupId: groupId ?? this.groupId,
      groupOwnerDid: groupOwnerDid ?? this.groupOwnerDid,
      groupDid: groupDid ?? this.groupDid,
      metadata: metadata ?? this.metadata,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (connectionOfferId.present) {
      map['connection_offer_id'] = Variable<String>(connectionOfferId.value);
    }
    if (memberDid.present) {
      map['member_did'] = Variable<String>(memberDid.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (groupOwnerDid.present) {
      map['group_owner_did'] = Variable<String>(groupOwnerDid.value);
    }
    if (groupDid.present) {
      map['group_did'] = Variable<String>(groupDid.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupConnectionOffersCompanion(')
          ..write('connectionOfferId: $connectionOfferId, ')
          ..write('memberDid: $memberDid, ')
          ..write('groupId: $groupId, ')
          ..write('groupOwnerDid: $groupOwnerDid, ')
          ..write('groupDid: $groupDid, ')
          ..write('metadata: $metadata, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ConnectionOfferDatabase extends GeneratedDatabase {
  _$ConnectionOfferDatabase(QueryExecutor e) : super(e);
  $ConnectionOfferDatabaseManager get managers =>
      $ConnectionOfferDatabaseManager(this);
  late final $ConnectionOffersTable connectionOffers =
      $ConnectionOffersTable(this);
  late final $ConnectionContactCardsTable connectionContactCards =
      $ConnectionContactCardsTable(this);
  late final $GroupConnectionOffersTable groupConnectionOffers =
      $GroupConnectionOffersTable(this);
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
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ConnectionOffersTableCreateCompanionBuilder
    = ConnectionOffersCompanion Function({
  Value<String> id,
  required String offerName,
  required String offerLink,
  Value<String?> offerDescription,
  required String oobInvitationMessage,
  required String mnemonic,
  Value<DateTime?> expiresAt,
  required DateTime createdAt,
  required String publishOfferDid,
  required ConnectionOfferType type,
  required ConnectionOfferStatus status,
  Value<int?> maximumUsage,
  Value<bool> ownedByMe,
  required String mediatorDid,
  Value<String?> aliasId,
  Value<String?> outboundMessageId,
  Value<String?> acceptOfferDid,
  Value<String?> permanentChannelDid,
  Value<String?> otherPartyPermanentChannelDid,
  Value<String?> notificationToken,
  Value<String?> otherPartyNotificationToken,
  Value<String?> externalRef,
  Value<int> rowid,
});
typedef $$ConnectionOffersTableUpdateCompanionBuilder
    = ConnectionOffersCompanion Function({
  Value<String> id,
  Value<String> offerName,
  Value<String> offerLink,
  Value<String?> offerDescription,
  Value<String> oobInvitationMessage,
  Value<String> mnemonic,
  Value<DateTime?> expiresAt,
  Value<DateTime> createdAt,
  Value<String> publishOfferDid,
  Value<ConnectionOfferType> type,
  Value<ConnectionOfferStatus> status,
  Value<int?> maximumUsage,
  Value<bool> ownedByMe,
  Value<String> mediatorDid,
  Value<String?> aliasId,
  Value<String?> outboundMessageId,
  Value<String?> acceptOfferDid,
  Value<String?> permanentChannelDid,
  Value<String?> otherPartyPermanentChannelDid,
  Value<String?> notificationToken,
  Value<String?> otherPartyNotificationToken,
  Value<String?> externalRef,
  Value<int> rowid,
});

final class $$ConnectionOffersTableReferences extends BaseReferences<
    _$ConnectionOfferDatabase, $ConnectionOffersTable, ConnectionOffer> {
  $$ConnectionOffersTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ConnectionContactCardsTable,
      List<ConnectionContactCard>> _connectionContactCardsRefsTable(
          _$ConnectionOfferDatabase db) =>
      MultiTypedResultKey.fromTable(db.connectionContactCards,
          aliasName: $_aliasNameGenerator(db.connectionOffers.id,
              db.connectionContactCards.connectionOfferId));

  $$ConnectionContactCardsTableProcessedTableManager
      get connectionContactCardsRefs {
    final manager = $$ConnectionContactCardsTableTableManager(
            $_db, $_db.connectionContactCards)
        .filter((f) =>
            f.connectionOfferId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_connectionContactCardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$GroupConnectionOffersTable,
      List<GroupConnectionOffer>> _groupConnectionOffersRefsTable(
          _$ConnectionOfferDatabase db) =>
      MultiTypedResultKey.fromTable(db.groupConnectionOffers,
          aliasName: $_aliasNameGenerator(db.connectionOffers.id,
              db.groupConnectionOffers.connectionOfferId));

  $$GroupConnectionOffersTableProcessedTableManager
      get groupConnectionOffersRefs {
    final manager = $$GroupConnectionOffersTableTableManager(
            $_db, $_db.groupConnectionOffers)
        .filter((f) =>
            f.connectionOfferId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_groupConnectionOffersRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ConnectionOffersTableFilterComposer
    extends Composer<_$ConnectionOfferDatabase, $ConnectionOffersTable> {
  $$ConnectionOffersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get offerName => $composableBuilder(
      column: $table.offerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get offerLink => $composableBuilder(
      column: $table.offerLink, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get offerDescription => $composableBuilder(
      column: $table.offerDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get oobInvitationMessage => $composableBuilder(
      column: $table.oobInvitationMessage,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mnemonic => $composableBuilder(
      column: $table.mnemonic, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publishOfferDid => $composableBuilder(
      column: $table.publishOfferDid,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ConnectionOfferType, ConnectionOfferType, int>
      get type => $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<ConnectionOfferStatus, ConnectionOfferStatus,
          int>
      get status => $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<int> get maximumUsage => $composableBuilder(
      column: $table.maximumUsage, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get ownedByMe => $composableBuilder(
      column: $table.ownedByMe, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediatorDid => $composableBuilder(
      column: $table.mediatorDid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aliasId => $composableBuilder(
      column: $table.aliasId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get outboundMessageId => $composableBuilder(
      column: $table.outboundMessageId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get acceptOfferDid => $composableBuilder(
      column: $table.acceptOfferDid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get permanentChannelDid => $composableBuilder(
      column: $table.permanentChannelDid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get otherPartyPermanentChannelDid => $composableBuilder(
      column: $table.otherPartyPermanentChannelDid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notificationToken => $composableBuilder(
      column: $table.notificationToken,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get otherPartyNotificationToken => $composableBuilder(
      column: $table.otherPartyNotificationToken,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get externalRef => $composableBuilder(
      column: $table.externalRef, builder: (column) => ColumnFilters(column));

  Expression<bool> connectionContactCardsRefs(
      Expression<bool> Function($$ConnectionContactCardsTableFilterComposer f)
          f) {
    final $$ConnectionContactCardsTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.connectionContactCards,
            getReferencedColumn: (t) => t.connectionOfferId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ConnectionContactCardsTableFilterComposer(
                  $db: $db,
                  $table: $db.connectionContactCards,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<bool> groupConnectionOffersRefs(
      Expression<bool> Function($$GroupConnectionOffersTableFilterComposer f)
          f) {
    final $$GroupConnectionOffersTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.groupConnectionOffers,
            getReferencedColumn: (t) => t.connectionOfferId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$GroupConnectionOffersTableFilterComposer(
                  $db: $db,
                  $table: $db.groupConnectionOffers,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ConnectionOffersTableOrderingComposer
    extends Composer<_$ConnectionOfferDatabase, $ConnectionOffersTable> {
  $$ConnectionOffersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get offerName => $composableBuilder(
      column: $table.offerName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get offerLink => $composableBuilder(
      column: $table.offerLink, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get offerDescription => $composableBuilder(
      column: $table.offerDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get oobInvitationMessage => $composableBuilder(
      column: $table.oobInvitationMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mnemonic => $composableBuilder(
      column: $table.mnemonic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get expiresAt => $composableBuilder(
      column: $table.expiresAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publishOfferDid => $composableBuilder(
      column: $table.publishOfferDid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get maximumUsage => $composableBuilder(
      column: $table.maximumUsage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get ownedByMe => $composableBuilder(
      column: $table.ownedByMe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediatorDid => $composableBuilder(
      column: $table.mediatorDid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aliasId => $composableBuilder(
      column: $table.aliasId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get outboundMessageId => $composableBuilder(
      column: $table.outboundMessageId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get acceptOfferDid => $composableBuilder(
      column: $table.acceptOfferDid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get permanentChannelDid => $composableBuilder(
      column: $table.permanentChannelDid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get otherPartyPermanentChannelDid =>
      $composableBuilder(
          column: $table.otherPartyPermanentChannelDid,
          builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notificationToken => $composableBuilder(
      column: $table.notificationToken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get otherPartyNotificationToken => $composableBuilder(
      column: $table.otherPartyNotificationToken,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get externalRef => $composableBuilder(
      column: $table.externalRef, builder: (column) => ColumnOrderings(column));
}

class $$ConnectionOffersTableAnnotationComposer
    extends Composer<_$ConnectionOfferDatabase, $ConnectionOffersTable> {
  $$ConnectionOffersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get offerName =>
      $composableBuilder(column: $table.offerName, builder: (column) => column);

  GeneratedColumn<String> get offerLink =>
      $composableBuilder(column: $table.offerLink, builder: (column) => column);

  GeneratedColumn<String> get offerDescription => $composableBuilder(
      column: $table.offerDescription, builder: (column) => column);

  GeneratedColumn<String> get oobInvitationMessage => $composableBuilder(
      column: $table.oobInvitationMessage, builder: (column) => column);

  GeneratedColumn<String> get mnemonic =>
      $composableBuilder(column: $table.mnemonic, builder: (column) => column);

  GeneratedColumn<DateTime> get expiresAt =>
      $composableBuilder(column: $table.expiresAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get publishOfferDid => $composableBuilder(
      column: $table.publishOfferDid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ConnectionOfferType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ConnectionOfferStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get maximumUsage => $composableBuilder(
      column: $table.maximumUsage, builder: (column) => column);

  GeneratedColumn<bool> get ownedByMe =>
      $composableBuilder(column: $table.ownedByMe, builder: (column) => column);

  GeneratedColumn<String> get mediatorDid => $composableBuilder(
      column: $table.mediatorDid, builder: (column) => column);

  GeneratedColumn<String> get aliasId =>
      $composableBuilder(column: $table.aliasId, builder: (column) => column);

  GeneratedColumn<String> get outboundMessageId => $composableBuilder(
      column: $table.outboundMessageId, builder: (column) => column);

  GeneratedColumn<String> get acceptOfferDid => $composableBuilder(
      column: $table.acceptOfferDid, builder: (column) => column);

  GeneratedColumn<String> get permanentChannelDid => $composableBuilder(
      column: $table.permanentChannelDid, builder: (column) => column);

  GeneratedColumn<String> get otherPartyPermanentChannelDid =>
      $composableBuilder(
          column: $table.otherPartyPermanentChannelDid,
          builder: (column) => column);

  GeneratedColumn<String> get notificationToken => $composableBuilder(
      column: $table.notificationToken, builder: (column) => column);

  GeneratedColumn<String> get otherPartyNotificationToken => $composableBuilder(
      column: $table.otherPartyNotificationToken, builder: (column) => column);

  GeneratedColumn<String> get externalRef => $composableBuilder(
      column: $table.externalRef, builder: (column) => column);

  Expression<T> connectionContactCardsRefs<T extends Object>(
      Expression<T> Function($$ConnectionContactCardsTableAnnotationComposer a)
          f) {
    final $$ConnectionContactCardsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.connectionContactCards,
            getReferencedColumn: (t) => t.connectionOfferId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ConnectionContactCardsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.connectionContactCards,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }

  Expression<T> groupConnectionOffersRefs<T extends Object>(
      Expression<T> Function($$GroupConnectionOffersTableAnnotationComposer a)
          f) {
    final $$GroupConnectionOffersTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.groupConnectionOffers,
            getReferencedColumn: (t) => t.connectionOfferId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$GroupConnectionOffersTableAnnotationComposer(
                  $db: $db,
                  $table: $db.groupConnectionOffers,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ConnectionOffersTableTableManager extends RootTableManager<
    _$ConnectionOfferDatabase,
    $ConnectionOffersTable,
    ConnectionOffer,
    $$ConnectionOffersTableFilterComposer,
    $$ConnectionOffersTableOrderingComposer,
    $$ConnectionOffersTableAnnotationComposer,
    $$ConnectionOffersTableCreateCompanionBuilder,
    $$ConnectionOffersTableUpdateCompanionBuilder,
    (ConnectionOffer, $$ConnectionOffersTableReferences),
    ConnectionOffer,
    PrefetchHooks Function(
        {bool connectionContactCardsRefs, bool groupConnectionOffersRefs})> {
  $$ConnectionOffersTableTableManager(
      _$ConnectionOfferDatabase db, $ConnectionOffersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionOffersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectionOffersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectionOffersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> offerName = const Value.absent(),
            Value<String> offerLink = const Value.absent(),
            Value<String?> offerDescription = const Value.absent(),
            Value<String> oobInvitationMessage = const Value.absent(),
            Value<String> mnemonic = const Value.absent(),
            Value<DateTime?> expiresAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> publishOfferDid = const Value.absent(),
            Value<ConnectionOfferType> type = const Value.absent(),
            Value<ConnectionOfferStatus> status = const Value.absent(),
            Value<int?> maximumUsage = const Value.absent(),
            Value<bool> ownedByMe = const Value.absent(),
            Value<String> mediatorDid = const Value.absent(),
            Value<String?> aliasId = const Value.absent(),
            Value<String?> outboundMessageId = const Value.absent(),
            Value<String?> acceptOfferDid = const Value.absent(),
            Value<String?> permanentChannelDid = const Value.absent(),
            Value<String?> otherPartyPermanentChannelDid = const Value.absent(),
            Value<String?> notificationToken = const Value.absent(),
            Value<String?> otherPartyNotificationToken = const Value.absent(),
            Value<String?> externalRef = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConnectionOffersCompanion(
            id: id,
            offerName: offerName,
            offerLink: offerLink,
            offerDescription: offerDescription,
            oobInvitationMessage: oobInvitationMessage,
            mnemonic: mnemonic,
            expiresAt: expiresAt,
            createdAt: createdAt,
            publishOfferDid: publishOfferDid,
            type: type,
            status: status,
            maximumUsage: maximumUsage,
            ownedByMe: ownedByMe,
            mediatorDid: mediatorDid,
            aliasId: aliasId,
            outboundMessageId: outboundMessageId,
            acceptOfferDid: acceptOfferDid,
            permanentChannelDid: permanentChannelDid,
            otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
            notificationToken: notificationToken,
            otherPartyNotificationToken: otherPartyNotificationToken,
            externalRef: externalRef,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String offerName,
            required String offerLink,
            Value<String?> offerDescription = const Value.absent(),
            required String oobInvitationMessage,
            required String mnemonic,
            Value<DateTime?> expiresAt = const Value.absent(),
            required DateTime createdAt,
            required String publishOfferDid,
            required ConnectionOfferType type,
            required ConnectionOfferStatus status,
            Value<int?> maximumUsage = const Value.absent(),
            Value<bool> ownedByMe = const Value.absent(),
            required String mediatorDid,
            Value<String?> aliasId = const Value.absent(),
            Value<String?> outboundMessageId = const Value.absent(),
            Value<String?> acceptOfferDid = const Value.absent(),
            Value<String?> permanentChannelDid = const Value.absent(),
            Value<String?> otherPartyPermanentChannelDid = const Value.absent(),
            Value<String?> notificationToken = const Value.absent(),
            Value<String?> otherPartyNotificationToken = const Value.absent(),
            Value<String?> externalRef = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ConnectionOffersCompanion.insert(
            id: id,
            offerName: offerName,
            offerLink: offerLink,
            offerDescription: offerDescription,
            oobInvitationMessage: oobInvitationMessage,
            mnemonic: mnemonic,
            expiresAt: expiresAt,
            createdAt: createdAt,
            publishOfferDid: publishOfferDid,
            type: type,
            status: status,
            maximumUsage: maximumUsage,
            ownedByMe: ownedByMe,
            mediatorDid: mediatorDid,
            aliasId: aliasId,
            outboundMessageId: outboundMessageId,
            acceptOfferDid: acceptOfferDid,
            permanentChannelDid: permanentChannelDid,
            otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
            notificationToken: notificationToken,
            otherPartyNotificationToken: otherPartyNotificationToken,
            externalRef: externalRef,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ConnectionOffersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {connectionContactCardsRefs = false,
              groupConnectionOffersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (connectionContactCardsRefs) db.connectionContactCards,
                if (groupConnectionOffersRefs) db.groupConnectionOffers
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (connectionContactCardsRefs)
                    await $_getPrefetchedData<ConnectionOffer,
                            $ConnectionOffersTable, ConnectionContactCard>(
                        currentTable: table,
                        referencedTable: $$ConnectionOffersTableReferences
                            ._connectionContactCardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ConnectionOffersTableReferences(db, table, p0)
                                .connectionContactCardsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.connectionOfferId == item.id),
                        typedResults: items),
                  if (groupConnectionOffersRefs)
                    await $_getPrefetchedData<ConnectionOffer,
                            $ConnectionOffersTable, GroupConnectionOffer>(
                        currentTable: table,
                        referencedTable: $$ConnectionOffersTableReferences
                            ._groupConnectionOffersRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ConnectionOffersTableReferences(db, table, p0)
                                .groupConnectionOffersRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.connectionOfferId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ConnectionOffersTableProcessedTableManager = ProcessedTableManager<
    _$ConnectionOfferDatabase,
    $ConnectionOffersTable,
    ConnectionOffer,
    $$ConnectionOffersTableFilterComposer,
    $$ConnectionOffersTableOrderingComposer,
    $$ConnectionOffersTableAnnotationComposer,
    $$ConnectionOffersTableCreateCompanionBuilder,
    $$ConnectionOffersTableUpdateCompanionBuilder,
    (ConnectionOffer, $$ConnectionOffersTableReferences),
    ConnectionOffer,
    PrefetchHooks Function(
        {bool connectionContactCardsRefs, bool groupConnectionOffersRefs})>;
typedef $$ConnectionContactCardsTableCreateCompanionBuilder
    = ConnectionContactCardsCompanion Function({
  Value<int> id,
  required String connectionOfferId,
  required String did,
  required String type,
  required String firstName,
  required String lastName,
  required String email,
  required String mobile,
  required String profilePic,
  required String meetingplaceIdentityCardColor,
});
typedef $$ConnectionContactCardsTableUpdateCompanionBuilder
    = ConnectionContactCardsCompanion Function({
  Value<int> id,
  Value<String> connectionOfferId,
  Value<String> did,
  Value<String> type,
  Value<String> firstName,
  Value<String> lastName,
  Value<String> email,
  Value<String> mobile,
  Value<String> profilePic,
  Value<String> meetingplaceIdentityCardColor,
});

final class $$ConnectionContactCardsTableReferences extends BaseReferences<
    _$ConnectionOfferDatabase,
    $ConnectionContactCardsTable,
    ConnectionContactCard> {
  $$ConnectionContactCardsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ConnectionOffersTable _connectionOfferIdTable(
          _$ConnectionOfferDatabase db) =>
      db.connectionOffers.createAlias($_aliasNameGenerator(
          db.connectionContactCards.connectionOfferId, db.connectionOffers.id));

  $$ConnectionOffersTableProcessedTableManager get connectionOfferId {
    final $_column = $_itemColumn<String>('connection_offer_id')!;

    final manager =
        $$ConnectionOffersTableTableManager($_db, $_db.connectionOffers)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionOfferIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ConnectionContactCardsTableFilterComposer
    extends Composer<_$ConnectionOfferDatabase, $ConnectionContactCardsTable> {
  $$ConnectionContactCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get did => $composableBuilder(
      column: $table.did, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get lastName => $composableBuilder(
      column: $table.lastName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mobile => $composableBuilder(
      column: $table.mobile, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profilePic => $composableBuilder(
      column: $table.profilePic, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get meetingplaceIdentityCardColor => $composableBuilder(
      column: $table.meetingplaceIdentityCardColor,
      builder: (column) => ColumnFilters(column));

  $$ConnectionOffersTableFilterComposer get connectionOfferId {
    final $$ConnectionOffersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.connectionOfferId,
        referencedTable: $db.connectionOffers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConnectionOffersTableFilterComposer(
              $db: $db,
              $table: $db.connectionOffers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ConnectionContactCardsTableOrderingComposer
    extends Composer<_$ConnectionOfferDatabase, $ConnectionContactCardsTable> {
  $$ConnectionContactCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get did => $composableBuilder(
      column: $table.did, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get firstName => $composableBuilder(
      column: $table.firstName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get lastName => $composableBuilder(
      column: $table.lastName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get email => $composableBuilder(
      column: $table.email, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mobile => $composableBuilder(
      column: $table.mobile, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profilePic => $composableBuilder(
      column: $table.profilePic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get meetingplaceIdentityCardColor =>
      $composableBuilder(
          column: $table.meetingplaceIdentityCardColor,
          builder: (column) => ColumnOrderings(column));

  $$ConnectionOffersTableOrderingComposer get connectionOfferId {
    final $$ConnectionOffersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.connectionOfferId,
        referencedTable: $db.connectionOffers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConnectionOffersTableOrderingComposer(
              $db: $db,
              $table: $db.connectionOffers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ConnectionContactCardsTableAnnotationComposer
    extends Composer<_$ConnectionOfferDatabase, $ConnectionContactCardsTable> {
  $$ConnectionContactCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get did =>
      $composableBuilder(column: $table.did, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get mobile =>
      $composableBuilder(column: $table.mobile, builder: (column) => column);

  GeneratedColumn<String> get profilePic => $composableBuilder(
      column: $table.profilePic, builder: (column) => column);

  GeneratedColumn<String> get meetingplaceIdentityCardColor =>
      $composableBuilder(
          column: $table.meetingplaceIdentityCardColor,
          builder: (column) => column);

  $$ConnectionOffersTableAnnotationComposer get connectionOfferId {
    final $$ConnectionOffersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.connectionOfferId,
        referencedTable: $db.connectionOffers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConnectionOffersTableAnnotationComposer(
              $db: $db,
              $table: $db.connectionOffers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ConnectionContactCardsTableTableManager extends RootTableManager<
    _$ConnectionOfferDatabase,
    $ConnectionContactCardsTable,
    ConnectionContactCard,
    $$ConnectionContactCardsTableFilterComposer,
    $$ConnectionContactCardsTableOrderingComposer,
    $$ConnectionContactCardsTableAnnotationComposer,
    $$ConnectionContactCardsTableCreateCompanionBuilder,
    $$ConnectionContactCardsTableUpdateCompanionBuilder,
    (ConnectionContactCard, $$ConnectionContactCardsTableReferences),
    ConnectionContactCard,
    PrefetchHooks Function({bool connectionOfferId})> {
  $$ConnectionContactCardsTableTableManager(
      _$ConnectionOfferDatabase db, $ConnectionContactCardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConnectionContactCardsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ConnectionContactCardsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConnectionContactCardsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> connectionOfferId = const Value.absent(),
            Value<String> did = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> firstName = const Value.absent(),
            Value<String> lastName = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> mobile = const Value.absent(),
            Value<String> profilePic = const Value.absent(),
            Value<String> meetingplaceIdentityCardColor = const Value.absent(),
          }) =>
              ConnectionContactCardsCompanion(
            id: id,
            connectionOfferId: connectionOfferId,
            did: did,
            type: type,
            firstName: firstName,
            lastName: lastName,
            email: email,
            mobile: mobile,
            profilePic: profilePic,
            meetingplaceIdentityCardColor: meetingplaceIdentityCardColor,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String connectionOfferId,
            required String did,
            required String type,
            required String firstName,
            required String lastName,
            required String email,
            required String mobile,
            required String profilePic,
            required String meetingplaceIdentityCardColor,
          }) =>
              ConnectionContactCardsCompanion.insert(
            id: id,
            connectionOfferId: connectionOfferId,
            did: did,
            type: type,
            firstName: firstName,
            lastName: lastName,
            email: email,
            mobile: mobile,
            profilePic: profilePic,
            meetingplaceIdentityCardColor: meetingplaceIdentityCardColor,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ConnectionContactCardsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({connectionOfferId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (connectionOfferId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.connectionOfferId,
                    referencedTable: $$ConnectionContactCardsTableReferences
                        ._connectionOfferIdTable(db),
                    referencedColumn: $$ConnectionContactCardsTableReferences
                        ._connectionOfferIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ConnectionContactCardsTableProcessedTableManager
    = ProcessedTableManager<
        _$ConnectionOfferDatabase,
        $ConnectionContactCardsTable,
        ConnectionContactCard,
        $$ConnectionContactCardsTableFilterComposer,
        $$ConnectionContactCardsTableOrderingComposer,
        $$ConnectionContactCardsTableAnnotationComposer,
        $$ConnectionContactCardsTableCreateCompanionBuilder,
        $$ConnectionContactCardsTableUpdateCompanionBuilder,
        (ConnectionContactCard, $$ConnectionContactCardsTableReferences),
        ConnectionContactCard,
        PrefetchHooks Function({bool connectionOfferId})>;
typedef $$GroupConnectionOffersTableCreateCompanionBuilder
    = GroupConnectionOffersCompanion Function({
  required String connectionOfferId,
  Value<String?> memberDid,
  required String groupId,
  Value<String?> groupOwnerDid,
  Value<String?> groupDid,
  Value<String?> metadata,
  Value<int> rowid,
});
typedef $$GroupConnectionOffersTableUpdateCompanionBuilder
    = GroupConnectionOffersCompanion Function({
  Value<String> connectionOfferId,
  Value<String?> memberDid,
  Value<String> groupId,
  Value<String?> groupOwnerDid,
  Value<String?> groupDid,
  Value<String?> metadata,
  Value<int> rowid,
});

final class $$GroupConnectionOffersTableReferences extends BaseReferences<
    _$ConnectionOfferDatabase,
    $GroupConnectionOffersTable,
    GroupConnectionOffer> {
  $$GroupConnectionOffersTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ConnectionOffersTable _connectionOfferIdTable(
          _$ConnectionOfferDatabase db) =>
      db.connectionOffers.createAlias($_aliasNameGenerator(
          db.groupConnectionOffers.connectionOfferId, db.connectionOffers.id));

  $$ConnectionOffersTableProcessedTableManager get connectionOfferId {
    final $_column = $_itemColumn<String>('connection_offer_id')!;

    final manager =
        $$ConnectionOffersTableTableManager($_db, $_db.connectionOffers)
            .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_connectionOfferIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$GroupConnectionOffersTableFilterComposer
    extends Composer<_$ConnectionOfferDatabase, $GroupConnectionOffersTable> {
  $$GroupConnectionOffersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get memberDid => $composableBuilder(
      column: $table.memberDid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupOwnerDid => $composableBuilder(
      column: $table.groupOwnerDid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupDid => $composableBuilder(
      column: $table.groupDid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnFilters(column));

  $$ConnectionOffersTableFilterComposer get connectionOfferId {
    final $$ConnectionOffersTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.connectionOfferId,
        referencedTable: $db.connectionOffers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConnectionOffersTableFilterComposer(
              $db: $db,
              $table: $db.connectionOffers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupConnectionOffersTableOrderingComposer
    extends Composer<_$ConnectionOfferDatabase, $GroupConnectionOffersTable> {
  $$GroupConnectionOffersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get memberDid => $composableBuilder(
      column: $table.memberDid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupId => $composableBuilder(
      column: $table.groupId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupOwnerDid => $composableBuilder(
      column: $table.groupOwnerDid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupDid => $composableBuilder(
      column: $table.groupDid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get metadata => $composableBuilder(
      column: $table.metadata, builder: (column) => ColumnOrderings(column));

  $$ConnectionOffersTableOrderingComposer get connectionOfferId {
    final $$ConnectionOffersTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.connectionOfferId,
        referencedTable: $db.connectionOffers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConnectionOffersTableOrderingComposer(
              $db: $db,
              $table: $db.connectionOffers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupConnectionOffersTableAnnotationComposer
    extends Composer<_$ConnectionOfferDatabase, $GroupConnectionOffersTable> {
  $$GroupConnectionOffersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get memberDid =>
      $composableBuilder(column: $table.memberDid, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get groupOwnerDid => $composableBuilder(
      column: $table.groupOwnerDid, builder: (column) => column);

  GeneratedColumn<String> get groupDid =>
      $composableBuilder(column: $table.groupDid, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  $$ConnectionOffersTableAnnotationComposer get connectionOfferId {
    final $$ConnectionOffersTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.connectionOfferId,
        referencedTable: $db.connectionOffers,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ConnectionOffersTableAnnotationComposer(
              $db: $db,
              $table: $db.connectionOffers,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$GroupConnectionOffersTableTableManager extends RootTableManager<
    _$ConnectionOfferDatabase,
    $GroupConnectionOffersTable,
    GroupConnectionOffer,
    $$GroupConnectionOffersTableFilterComposer,
    $$GroupConnectionOffersTableOrderingComposer,
    $$GroupConnectionOffersTableAnnotationComposer,
    $$GroupConnectionOffersTableCreateCompanionBuilder,
    $$GroupConnectionOffersTableUpdateCompanionBuilder,
    (GroupConnectionOffer, $$GroupConnectionOffersTableReferences),
    GroupConnectionOffer,
    PrefetchHooks Function({bool connectionOfferId})> {
  $$GroupConnectionOffersTableTableManager(
      _$ConnectionOfferDatabase db, $GroupConnectionOffersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupConnectionOffersTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupConnectionOffersTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupConnectionOffersTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> connectionOfferId = const Value.absent(),
            Value<String?> memberDid = const Value.absent(),
            Value<String> groupId = const Value.absent(),
            Value<String?> groupOwnerDid = const Value.absent(),
            Value<String?> groupDid = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupConnectionOffersCompanion(
            connectionOfferId: connectionOfferId,
            memberDid: memberDid,
            groupId: groupId,
            groupOwnerDid: groupOwnerDid,
            groupDid: groupDid,
            metadata: metadata,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String connectionOfferId,
            Value<String?> memberDid = const Value.absent(),
            required String groupId,
            Value<String?> groupOwnerDid = const Value.absent(),
            Value<String?> groupDid = const Value.absent(),
            Value<String?> metadata = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GroupConnectionOffersCompanion.insert(
            connectionOfferId: connectionOfferId,
            memberDid: memberDid,
            groupId: groupId,
            groupOwnerDid: groupOwnerDid,
            groupDid: groupDid,
            metadata: metadata,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$GroupConnectionOffersTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({connectionOfferId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (connectionOfferId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.connectionOfferId,
                    referencedTable: $$GroupConnectionOffersTableReferences
                        ._connectionOfferIdTable(db),
                    referencedColumn: $$GroupConnectionOffersTableReferences
                        ._connectionOfferIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$GroupConnectionOffersTableProcessedTableManager
    = ProcessedTableManager<
        _$ConnectionOfferDatabase,
        $GroupConnectionOffersTable,
        GroupConnectionOffer,
        $$GroupConnectionOffersTableFilterComposer,
        $$GroupConnectionOffersTableOrderingComposer,
        $$GroupConnectionOffersTableAnnotationComposer,
        $$GroupConnectionOffersTableCreateCompanionBuilder,
        $$GroupConnectionOffersTableUpdateCompanionBuilder,
        (GroupConnectionOffer, $$GroupConnectionOffersTableReferences),
        GroupConnectionOffer,
        PrefetchHooks Function({bool connectionOfferId})>;

class $ConnectionOfferDatabaseManager {
  final _$ConnectionOfferDatabase _db;
  $ConnectionOfferDatabaseManager(this._db);
  $$ConnectionOffersTableTableManager get connectionOffers =>
      $$ConnectionOffersTableTableManager(_db, _db.connectionOffers);
  $$ConnectionContactCardsTableTableManager get connectionContactCards =>
      $$ConnectionContactCardsTableTableManager(
          _db, _db.connectionContactCards);
  $$GroupConnectionOffersTableTableManager get groupConnectionOffers =>
      $$GroupConnectionOffersTableTableManager(_db, _db.groupConnectionOffers);
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_database.dart';

// ignore_for_file: type=lint
class $ChannelsTable extends Channels with TableInfo<$ChannelsTable, Channel> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      clientDefault: const Uuid().v4);
  static const VerificationMeta _publishOfferDidMeta =
      const VerificationMeta('publishOfferDid');
  @override
  late final GeneratedColumn<String> publishOfferDid = GeneratedColumn<String>(
      'publish_offer_did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediatorDidMeta =
      const VerificationMeta('mediatorDid');
  @override
  late final GeneratedColumn<String> mediatorDid = GeneratedColumn<String>(
      'mediator_did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _offerLinkMeta =
      const VerificationMeta('offerLink');
  @override
  late final GeneratedColumn<String> offerLink = GeneratedColumn<String>(
      'offer_link', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<ChannelStatus, int> status =
      GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ChannelStatus>($ChannelsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<ChannelType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ChannelType>($ChannelsTable.$convertertype);
  static const VerificationMeta _isConnectionInitiatorMeta =
      const VerificationMeta('isConnectionInitiator');
  @override
  late final GeneratedColumn<bool> isConnectionInitiator =
      GeneratedColumn<bool>('is_connection_initiator', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("is_connection_initiator" IN (0, 1))'),
          defaultValue: const Constant(false));
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
  static const VerificationMeta _seqNoMeta = const VerificationMeta('seqNo');
  @override
  late final GeneratedColumn<int> seqNo = GeneratedColumn<int>(
      'seq_no', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _messageSyncMarkerMeta =
      const VerificationMeta('messageSyncMarker');
  @override
  late final GeneratedColumn<DateTime> messageSyncMarker =
      GeneratedColumn<DateTime>('message_sync_marker', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        publishOfferDid,
        mediatorDid,
        offerLink,
        status,
        type,
        isConnectionInitiator,
        outboundMessageId,
        acceptOfferDid,
        permanentChannelDid,
        otherPartyPermanentChannelDid,
        notificationToken,
        otherPartyNotificationToken,
        externalRef,
        seqNo,
        messageSyncMarker
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(Insertable<Channel> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('publish_offer_did')) {
      context.handle(
          _publishOfferDidMeta,
          publishOfferDid.isAcceptableOrUnknown(
              data['publish_offer_did']!, _publishOfferDidMeta));
    } else if (isInserting) {
      context.missing(_publishOfferDidMeta);
    }
    if (data.containsKey('mediator_did')) {
      context.handle(
          _mediatorDidMeta,
          mediatorDid.isAcceptableOrUnknown(
              data['mediator_did']!, _mediatorDidMeta));
    } else if (isInserting) {
      context.missing(_mediatorDidMeta);
    }
    if (data.containsKey('offer_link')) {
      context.handle(_offerLinkMeta,
          offerLink.isAcceptableOrUnknown(data['offer_link']!, _offerLinkMeta));
    } else if (isInserting) {
      context.missing(_offerLinkMeta);
    }
    if (data.containsKey('is_connection_initiator')) {
      context.handle(
          _isConnectionInitiatorMeta,
          isConnectionInitiator.isAcceptableOrUnknown(
              data['is_connection_initiator']!, _isConnectionInitiatorMeta));
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
    if (data.containsKey('seq_no')) {
      context.handle(
          _seqNoMeta, seqNo.isAcceptableOrUnknown(data['seq_no']!, _seqNoMeta));
    } else if (isInserting) {
      context.missing(_seqNoMeta);
    }
    if (data.containsKey('message_sync_marker')) {
      context.handle(
          _messageSyncMarkerMeta,
          messageSyncMarker.isAcceptableOrUnknown(
              data['message_sync_marker']!, _messageSyncMarkerMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Channel map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Channel(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      publishOfferDid: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}publish_offer_did'])!,
      mediatorDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mediator_did'])!,
      offerLink: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}offer_link'])!,
      status: $ChannelsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      type: $ChannelsTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      isConnectionInitiator: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}is_connection_initiator'])!,
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
      seqNo: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seq_no'])!,
      messageSyncMarker: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}message_sync_marker']),
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }

  static TypeConverter<ChannelStatus, int> $converterstatus =
      const _ChannelStatusConverter();
  static TypeConverter<ChannelType, int> $convertertype =
      const _ChannelTypeConverter();
}

class Channel extends DataClass implements Insertable<Channel> {
  /// Unique identifier for the channel.
  final String id;

  /// DID of the channel creator used when publishing the offer.
  final String publishOfferDid;

  /// DID of the mediator.
  final String mediatorDid;

  /// Link to the offer.
  final String offerLink;

  /// Status of the channel.
  final ChannelStatus status;

  /// Type of the channel.
  final ChannelType type;

  /// Indicates whether the channel was initiated by the local party or the
  /// other party.
  final bool isConnectionInitiator;

  /// ID of the outbound message.
  final String? outboundMessageId;

  /// DID of the accepted offer.
  final String? acceptOfferDid;

  /// Permanent DID of the channel.
  final String? permanentChannelDid;

  /// Permanent DID of the other party in the channel.
  final String? otherPartyPermanentChannelDid;

  /// Notification token for the channel.
  final String? notificationToken;

  /// Notification token for the other party in the channel.
  final String? otherPartyNotificationToken;

  /// External reference for the channel.
  final String? externalRef;

  /// Sequence number for the channel that is used to order messages within the
  /// channel.
  final int seqNo;

  /// Message sync marker for the channel.
  final DateTime? messageSyncMarker;
  const Channel(
      {required this.id,
      required this.publishOfferDid,
      required this.mediatorDid,
      required this.offerLink,
      required this.status,
      required this.type,
      required this.isConnectionInitiator,
      this.outboundMessageId,
      this.acceptOfferDid,
      this.permanentChannelDid,
      this.otherPartyPermanentChannelDid,
      this.notificationToken,
      this.otherPartyNotificationToken,
      this.externalRef,
      required this.seqNo,
      this.messageSyncMarker});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['publish_offer_did'] = Variable<String>(publishOfferDid);
    map['mediator_did'] = Variable<String>(mediatorDid);
    map['offer_link'] = Variable<String>(offerLink);
    {
      map['status'] =
          Variable<int>($ChannelsTable.$converterstatus.toSql(status));
    }
    {
      map['type'] = Variable<int>($ChannelsTable.$convertertype.toSql(type));
    }
    map['is_connection_initiator'] = Variable<bool>(isConnectionInitiator);
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
    map['seq_no'] = Variable<int>(seqNo);
    if (!nullToAbsent || messageSyncMarker != null) {
      map['message_sync_marker'] = Variable<DateTime>(messageSyncMarker);
    }
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      id: Value(id),
      publishOfferDid: Value(publishOfferDid),
      mediatorDid: Value(mediatorDid),
      offerLink: Value(offerLink),
      status: Value(status),
      type: Value(type),
      isConnectionInitiator: Value(isConnectionInitiator),
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
      seqNo: Value(seqNo),
      messageSyncMarker: messageSyncMarker == null && nullToAbsent
          ? const Value.absent()
          : Value(messageSyncMarker),
    );
  }

  factory Channel.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Channel(
      id: serializer.fromJson<String>(json['id']),
      publishOfferDid: serializer.fromJson<String>(json['publishOfferDid']),
      mediatorDid: serializer.fromJson<String>(json['mediatorDid']),
      offerLink: serializer.fromJson<String>(json['offerLink']),
      status: serializer.fromJson<ChannelStatus>(json['status']),
      type: serializer.fromJson<ChannelType>(json['type']),
      isConnectionInitiator:
          serializer.fromJson<bool>(json['isConnectionInitiator']),
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
      seqNo: serializer.fromJson<int>(json['seqNo']),
      messageSyncMarker:
          serializer.fromJson<DateTime?>(json['messageSyncMarker']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'publishOfferDid': serializer.toJson<String>(publishOfferDid),
      'mediatorDid': serializer.toJson<String>(mediatorDid),
      'offerLink': serializer.toJson<String>(offerLink),
      'status': serializer.toJson<ChannelStatus>(status),
      'type': serializer.toJson<ChannelType>(type),
      'isConnectionInitiator': serializer.toJson<bool>(isConnectionInitiator),
      'outboundMessageId': serializer.toJson<String?>(outboundMessageId),
      'acceptOfferDid': serializer.toJson<String?>(acceptOfferDid),
      'permanentChannelDid': serializer.toJson<String?>(permanentChannelDid),
      'otherPartyPermanentChannelDid':
          serializer.toJson<String?>(otherPartyPermanentChannelDid),
      'notificationToken': serializer.toJson<String?>(notificationToken),
      'otherPartyNotificationToken':
          serializer.toJson<String?>(otherPartyNotificationToken),
      'externalRef': serializer.toJson<String?>(externalRef),
      'seqNo': serializer.toJson<int>(seqNo),
      'messageSyncMarker': serializer.toJson<DateTime?>(messageSyncMarker),
    };
  }

  Channel copyWith(
          {String? id,
          String? publishOfferDid,
          String? mediatorDid,
          String? offerLink,
          ChannelStatus? status,
          ChannelType? type,
          bool? isConnectionInitiator,
          Value<String?> outboundMessageId = const Value.absent(),
          Value<String?> acceptOfferDid = const Value.absent(),
          Value<String?> permanentChannelDid = const Value.absent(),
          Value<String?> otherPartyPermanentChannelDid = const Value.absent(),
          Value<String?> notificationToken = const Value.absent(),
          Value<String?> otherPartyNotificationToken = const Value.absent(),
          Value<String?> externalRef = const Value.absent(),
          int? seqNo,
          Value<DateTime?> messageSyncMarker = const Value.absent()}) =>
      Channel(
        id: id ?? this.id,
        publishOfferDid: publishOfferDid ?? this.publishOfferDid,
        mediatorDid: mediatorDid ?? this.mediatorDid,
        offerLink: offerLink ?? this.offerLink,
        status: status ?? this.status,
        type: type ?? this.type,
        isConnectionInitiator:
            isConnectionInitiator ?? this.isConnectionInitiator,
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
        seqNo: seqNo ?? this.seqNo,
        messageSyncMarker: messageSyncMarker.present
            ? messageSyncMarker.value
            : this.messageSyncMarker,
      );
  Channel copyWithCompanion(ChannelsCompanion data) {
    return Channel(
      id: data.id.present ? data.id.value : this.id,
      publishOfferDid: data.publishOfferDid.present
          ? data.publishOfferDid.value
          : this.publishOfferDid,
      mediatorDid:
          data.mediatorDid.present ? data.mediatorDid.value : this.mediatorDid,
      offerLink: data.offerLink.present ? data.offerLink.value : this.offerLink,
      status: data.status.present ? data.status.value : this.status,
      type: data.type.present ? data.type.value : this.type,
      isConnectionInitiator: data.isConnectionInitiator.present
          ? data.isConnectionInitiator.value
          : this.isConnectionInitiator,
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
      seqNo: data.seqNo.present ? data.seqNo.value : this.seqNo,
      messageSyncMarker: data.messageSyncMarker.present
          ? data.messageSyncMarker.value
          : this.messageSyncMarker,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Channel(')
          ..write('id: $id, ')
          ..write('publishOfferDid: $publishOfferDid, ')
          ..write('mediatorDid: $mediatorDid, ')
          ..write('offerLink: $offerLink, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('isConnectionInitiator: $isConnectionInitiator, ')
          ..write('outboundMessageId: $outboundMessageId, ')
          ..write('acceptOfferDid: $acceptOfferDid, ')
          ..write('permanentChannelDid: $permanentChannelDid, ')
          ..write(
              'otherPartyPermanentChannelDid: $otherPartyPermanentChannelDid, ')
          ..write('notificationToken: $notificationToken, ')
          ..write('otherPartyNotificationToken: $otherPartyNotificationToken, ')
          ..write('externalRef: $externalRef, ')
          ..write('seqNo: $seqNo, ')
          ..write('messageSyncMarker: $messageSyncMarker')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      publishOfferDid,
      mediatorDid,
      offerLink,
      status,
      type,
      isConnectionInitiator,
      outboundMessageId,
      acceptOfferDid,
      permanentChannelDid,
      otherPartyPermanentChannelDid,
      notificationToken,
      otherPartyNotificationToken,
      externalRef,
      seqNo,
      messageSyncMarker);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Channel &&
          other.id == this.id &&
          other.publishOfferDid == this.publishOfferDid &&
          other.mediatorDid == this.mediatorDid &&
          other.offerLink == this.offerLink &&
          other.status == this.status &&
          other.type == this.type &&
          other.isConnectionInitiator == this.isConnectionInitiator &&
          other.outboundMessageId == this.outboundMessageId &&
          other.acceptOfferDid == this.acceptOfferDid &&
          other.permanentChannelDid == this.permanentChannelDid &&
          other.otherPartyPermanentChannelDid ==
              this.otherPartyPermanentChannelDid &&
          other.notificationToken == this.notificationToken &&
          other.otherPartyNotificationToken ==
              this.otherPartyNotificationToken &&
          other.externalRef == this.externalRef &&
          other.seqNo == this.seqNo &&
          other.messageSyncMarker == this.messageSyncMarker);
}

class ChannelsCompanion extends UpdateCompanion<Channel> {
  final Value<String> id;
  final Value<String> publishOfferDid;
  final Value<String> mediatorDid;
  final Value<String> offerLink;
  final Value<ChannelStatus> status;
  final Value<ChannelType> type;
  final Value<bool> isConnectionInitiator;
  final Value<String?> outboundMessageId;
  final Value<String?> acceptOfferDid;
  final Value<String?> permanentChannelDid;
  final Value<String?> otherPartyPermanentChannelDid;
  final Value<String?> notificationToken;
  final Value<String?> otherPartyNotificationToken;
  final Value<String?> externalRef;
  final Value<int> seqNo;
  final Value<DateTime?> messageSyncMarker;
  final Value<int> rowid;
  const ChannelsCompanion({
    this.id = const Value.absent(),
    this.publishOfferDid = const Value.absent(),
    this.mediatorDid = const Value.absent(),
    this.offerLink = const Value.absent(),
    this.status = const Value.absent(),
    this.type = const Value.absent(),
    this.isConnectionInitiator = const Value.absent(),
    this.outboundMessageId = const Value.absent(),
    this.acceptOfferDid = const Value.absent(),
    this.permanentChannelDid = const Value.absent(),
    this.otherPartyPermanentChannelDid = const Value.absent(),
    this.notificationToken = const Value.absent(),
    this.otherPartyNotificationToken = const Value.absent(),
    this.externalRef = const Value.absent(),
    this.seqNo = const Value.absent(),
    this.messageSyncMarker = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelsCompanion.insert({
    this.id = const Value.absent(),
    required String publishOfferDid,
    required String mediatorDid,
    required String offerLink,
    required ChannelStatus status,
    required ChannelType type,
    this.isConnectionInitiator = const Value.absent(),
    this.outboundMessageId = const Value.absent(),
    this.acceptOfferDid = const Value.absent(),
    this.permanentChannelDid = const Value.absent(),
    this.otherPartyPermanentChannelDid = const Value.absent(),
    this.notificationToken = const Value.absent(),
    this.otherPartyNotificationToken = const Value.absent(),
    this.externalRef = const Value.absent(),
    required int seqNo,
    this.messageSyncMarker = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : publishOfferDid = Value(publishOfferDid),
        mediatorDid = Value(mediatorDid),
        offerLink = Value(offerLink),
        status = Value(status),
        type = Value(type),
        seqNo = Value(seqNo);
  static Insertable<Channel> custom({
    Expression<String>? id,
    Expression<String>? publishOfferDid,
    Expression<String>? mediatorDid,
    Expression<String>? offerLink,
    Expression<int>? status,
    Expression<int>? type,
    Expression<bool>? isConnectionInitiator,
    Expression<String>? outboundMessageId,
    Expression<String>? acceptOfferDid,
    Expression<String>? permanentChannelDid,
    Expression<String>? otherPartyPermanentChannelDid,
    Expression<String>? notificationToken,
    Expression<String>? otherPartyNotificationToken,
    Expression<String>? externalRef,
    Expression<int>? seqNo,
    Expression<DateTime>? messageSyncMarker,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (publishOfferDid != null) 'publish_offer_did': publishOfferDid,
      if (mediatorDid != null) 'mediator_did': mediatorDid,
      if (offerLink != null) 'offer_link': offerLink,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (isConnectionInitiator != null)
        'is_connection_initiator': isConnectionInitiator,
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
      if (seqNo != null) 'seq_no': seqNo,
      if (messageSyncMarker != null) 'message_sync_marker': messageSyncMarker,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelsCompanion copyWith(
      {Value<String>? id,
      Value<String>? publishOfferDid,
      Value<String>? mediatorDid,
      Value<String>? offerLink,
      Value<ChannelStatus>? status,
      Value<ChannelType>? type,
      Value<bool>? isConnectionInitiator,
      Value<String?>? outboundMessageId,
      Value<String?>? acceptOfferDid,
      Value<String?>? permanentChannelDid,
      Value<String?>? otherPartyPermanentChannelDid,
      Value<String?>? notificationToken,
      Value<String?>? otherPartyNotificationToken,
      Value<String?>? externalRef,
      Value<int>? seqNo,
      Value<DateTime?>? messageSyncMarker,
      Value<int>? rowid}) {
    return ChannelsCompanion(
      id: id ?? this.id,
      publishOfferDid: publishOfferDid ?? this.publishOfferDid,
      mediatorDid: mediatorDid ?? this.mediatorDid,
      offerLink: offerLink ?? this.offerLink,
      status: status ?? this.status,
      type: type ?? this.type,
      isConnectionInitiator:
          isConnectionInitiator ?? this.isConnectionInitiator,
      outboundMessageId: outboundMessageId ?? this.outboundMessageId,
      acceptOfferDid: acceptOfferDid ?? this.acceptOfferDid,
      permanentChannelDid: permanentChannelDid ?? this.permanentChannelDid,
      otherPartyPermanentChannelDid:
          otherPartyPermanentChannelDid ?? this.otherPartyPermanentChannelDid,
      notificationToken: notificationToken ?? this.notificationToken,
      otherPartyNotificationToken:
          otherPartyNotificationToken ?? this.otherPartyNotificationToken,
      externalRef: externalRef ?? this.externalRef,
      seqNo: seqNo ?? this.seqNo,
      messageSyncMarker: messageSyncMarker ?? this.messageSyncMarker,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (publishOfferDid.present) {
      map['publish_offer_did'] = Variable<String>(publishOfferDid.value);
    }
    if (mediatorDid.present) {
      map['mediator_did'] = Variable<String>(mediatorDid.value);
    }
    if (offerLink.present) {
      map['offer_link'] = Variable<String>(offerLink.value);
    }
    if (status.present) {
      map['status'] =
          Variable<int>($ChannelsTable.$converterstatus.toSql(status.value));
    }
    if (type.present) {
      map['type'] =
          Variable<int>($ChannelsTable.$convertertype.toSql(type.value));
    }
    if (isConnectionInitiator.present) {
      map['is_connection_initiator'] =
          Variable<bool>(isConnectionInitiator.value);
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
    if (seqNo.present) {
      map['seq_no'] = Variable<int>(seqNo.value);
    }
    if (messageSyncMarker.present) {
      map['message_sync_marker'] = Variable<DateTime>(messageSyncMarker.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('id: $id, ')
          ..write('publishOfferDid: $publishOfferDid, ')
          ..write('mediatorDid: $mediatorDid, ')
          ..write('offerLink: $offerLink, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('isConnectionInitiator: $isConnectionInitiator, ')
          ..write('outboundMessageId: $outboundMessageId, ')
          ..write('acceptOfferDid: $acceptOfferDid, ')
          ..write('permanentChannelDid: $permanentChannelDid, ')
          ..write(
              'otherPartyPermanentChannelDid: $otherPartyPermanentChannelDid, ')
          ..write('notificationToken: $notificationToken, ')
          ..write('otherPartyNotificationToken: $otherPartyNotificationToken, ')
          ..write('externalRef: $externalRef, ')
          ..write('seqNo: $seqNo, ')
          ..write('messageSyncMarker: $messageSyncMarker, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChannelContactCardsTable extends ChannelContactCards
    with TableInfo<$ChannelContactCardsTable, ChannelContactCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelContactCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _channelIdMeta =
      const VerificationMeta('channelId');
  @override
  late final GeneratedColumn<String> channelId = GeneratedColumn<String>(
      'channel_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints: 'REFERENCES channels(id) ON DELETE CASCADE NOT NULL');
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
  static const VerificationMeta _contactInfoJsonMeta =
      const VerificationMeta('contactInfoJson');
  @override
  late final GeneratedColumn<String> contactInfoJson = GeneratedColumn<String>(
      'contact_info_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _profilePicMeta =
      const VerificationMeta('profilePic');
  @override
  late final GeneratedColumn<String> profilePic = GeneratedColumn<String>(
      'profile_pic', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<ContactCardType, int> cardType =
      GeneratedColumn<int>('card_type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ContactCardType>(
              $ChannelContactCardsTable.$convertercardType);
  @override
  List<GeneratedColumn> get $columns =>
      [id, channelId, did, type, contactInfoJson, profilePic, cardType];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channel_contact_cards';
  @override
  VerificationContext validateIntegrity(Insertable<ChannelContactCard> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('channel_id')) {
      context.handle(_channelIdMeta,
          channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta));
    } else if (isInserting) {
      context.missing(_channelIdMeta);
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
    if (data.containsKey('contact_info_json')) {
      context.handle(
          _contactInfoJsonMeta,
          contactInfoJson.isAcceptableOrUnknown(
              data['contact_info_json']!, _contactInfoJsonMeta));
    }
    if (data.containsKey('profile_pic')) {
      context.handle(
          _profilePicMeta,
          profilePic.isAcceptableOrUnknown(
              data['profile_pic']!, _profilePicMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {channelId, cardType},
      ];
  @override
  ChannelContactCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelContactCard(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      channelId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}channel_id'])!,
      did: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}did'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      contactInfoJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}contact_info_json'])!,
      profilePic: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_pic']),
      cardType: $ChannelContactCardsTable.$convertercardType.fromSql(
          attachedDatabase.typeMapping
              .read(DriftSqlType.int, data['${effectivePrefix}card_type'])!),
    );
  }

  @override
  $ChannelContactCardsTable createAlias(String alias) {
    return $ChannelContactCardsTable(attachedDatabase, alias);
  }

  static TypeConverter<ContactCardType, int> $convertercardType =
      const _ContactCardTypeConverter();
}

class ChannelContactCard extends DataClass
    implements Insertable<ChannelContactCard> {
  /// Auto-incrementing ID for the contact card.
  final int id;

  /// ID of the associated channel.
  final String channelId;

  /// DID of the contact.
  final String did;

  /// Type of the contact.
  final String type;

  /// Flexible JSON payload for contact information.
  final String contactInfoJson;

  /// Profile picture of the contact.
  final String? profilePic;

  /// Type of the contact card.
  final ContactCardType cardType;
  const ChannelContactCard(
      {required this.id,
      required this.channelId,
      required this.did,
      required this.type,
      required this.contactInfoJson,
      this.profilePic,
      required this.cardType});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['channel_id'] = Variable<String>(channelId);
    map['did'] = Variable<String>(did);
    map['type'] = Variable<String>(type);
    map['contact_info_json'] = Variable<String>(contactInfoJson);
    if (!nullToAbsent || profilePic != null) {
      map['profile_pic'] = Variable<String>(profilePic);
    }
    {
      map['card_type'] = Variable<int>(
          $ChannelContactCardsTable.$convertercardType.toSql(cardType));
    }
    return map;
  }

  ChannelContactCardsCompanion toCompanion(bool nullToAbsent) {
    return ChannelContactCardsCompanion(
      id: Value(id),
      channelId: Value(channelId),
      did: Value(did),
      type: Value(type),
      contactInfoJson: Value(contactInfoJson),
      profilePic: profilePic == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePic),
      cardType: Value(cardType),
    );
  }

  factory ChannelContactCard.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelContactCard(
      id: serializer.fromJson<int>(json['id']),
      channelId: serializer.fromJson<String>(json['channelId']),
      did: serializer.fromJson<String>(json['did']),
      type: serializer.fromJson<String>(json['type']),
      contactInfoJson: serializer.fromJson<String>(json['contactInfoJson']),
      profilePic: serializer.fromJson<String?>(json['profilePic']),
      cardType: serializer.fromJson<ContactCardType>(json['cardType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'channelId': serializer.toJson<String>(channelId),
      'did': serializer.toJson<String>(did),
      'type': serializer.toJson<String>(type),
      'contactInfoJson': serializer.toJson<String>(contactInfoJson),
      'profilePic': serializer.toJson<String?>(profilePic),
      'cardType': serializer.toJson<ContactCardType>(cardType),
    };
  }

  ChannelContactCard copyWith(
          {int? id,
          String? channelId,
          String? did,
          String? type,
          String? contactInfoJson,
          Value<String?> profilePic = const Value.absent(),
          ContactCardType? cardType}) =>
      ChannelContactCard(
        id: id ?? this.id,
        channelId: channelId ?? this.channelId,
        did: did ?? this.did,
        type: type ?? this.type,
        contactInfoJson: contactInfoJson ?? this.contactInfoJson,
        profilePic: profilePic.present ? profilePic.value : this.profilePic,
        cardType: cardType ?? this.cardType,
      );
  ChannelContactCard copyWithCompanion(ChannelContactCardsCompanion data) {
    return ChannelContactCard(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      did: data.did.present ? data.did.value : this.did,
      type: data.type.present ? data.type.value : this.type,
      contactInfoJson: data.contactInfoJson.present
          ? data.contactInfoJson.value
          : this.contactInfoJson,
      profilePic:
          data.profilePic.present ? data.profilePic.value : this.profilePic,
      cardType: data.cardType.present ? data.cardType.value : this.cardType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelContactCard(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('did: $did, ')
          ..write('type: $type, ')
          ..write('contactInfoJson: $contactInfoJson, ')
          ..write('profilePic: $profilePic, ')
          ..write('cardType: $cardType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, channelId, did, type, contactInfoJson, profilePic, cardType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelContactCard &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.did == this.did &&
          other.type == this.type &&
          other.contactInfoJson == this.contactInfoJson &&
          other.profilePic == this.profilePic &&
          other.cardType == this.cardType);
}

class ChannelContactCardsCompanion extends UpdateCompanion<ChannelContactCard> {
  final Value<int> id;
  final Value<String> channelId;
  final Value<String> did;
  final Value<String> type;
  final Value<String> contactInfoJson;
  final Value<String?> profilePic;
  final Value<ContactCardType> cardType;
  const ChannelContactCardsCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.did = const Value.absent(),
    this.type = const Value.absent(),
    this.contactInfoJson = const Value.absent(),
    this.profilePic = const Value.absent(),
    this.cardType = const Value.absent(),
  });
  ChannelContactCardsCompanion.insert({
    this.id = const Value.absent(),
    required String channelId,
    required String did,
    required String type,
    this.contactInfoJson = const Value.absent(),
    this.profilePic = const Value.absent(),
    required ContactCardType cardType,
  })  : channelId = Value(channelId),
        did = Value(did),
        type = Value(type),
        cardType = Value(cardType);
  static Insertable<ChannelContactCard> custom({
    Expression<int>? id,
    Expression<String>? channelId,
    Expression<String>? did,
    Expression<String>? type,
    Expression<String>? contactInfoJson,
    Expression<String>? profilePic,
    Expression<int>? cardType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (did != null) 'did': did,
      if (type != null) 'type': type,
      if (contactInfoJson != null) 'contact_info_json': contactInfoJson,
      if (profilePic != null) 'profile_pic': profilePic,
      if (cardType != null) 'card_type': cardType,
    });
  }

  ChannelContactCardsCompanion copyWith(
      {Value<int>? id,
      Value<String>? channelId,
      Value<String>? did,
      Value<String>? type,
      Value<String>? contactInfoJson,
      Value<String?>? profilePic,
      Value<ContactCardType>? cardType}) {
    return ChannelContactCardsCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      did: did ?? this.did,
      type: type ?? this.type,
      contactInfoJson: contactInfoJson ?? this.contactInfoJson,
      profilePic: profilePic ?? this.profilePic,
      cardType: cardType ?? this.cardType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<String>(channelId.value);
    }
    if (did.present) {
      map['did'] = Variable<String>(did.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (contactInfoJson.present) {
      map['contact_info_json'] = Variable<String>(contactInfoJson.value);
    }
    if (profilePic.present) {
      map['profile_pic'] = Variable<String>(profilePic.value);
    }
    if (cardType.present) {
      map['card_type'] = Variable<int>(
          $ChannelContactCardsTable.$convertercardType.toSql(cardType.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelContactCardsCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('did: $did, ')
          ..write('type: $type, ')
          ..write('contactInfoJson: $contactInfoJson, ')
          ..write('profilePic: $profilePic, ')
          ..write('cardType: $cardType')
          ..write(')'))
        .toString();
  }
}

abstract class _$ChannelDatabase extends GeneratedDatabase {
  _$ChannelDatabase(QueryExecutor e) : super(e);
  $ChannelDatabaseManager get managers => $ChannelDatabaseManager(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $ChannelContactCardsTable channelContactCards =
      $ChannelContactCardsTable(this);
  late final Index offerLink =
      Index('offer_link', 'CREATE INDEX offer_link ON channels (offer_link)');
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [channels, channelContactCards, offerLink];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('channels',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('channel_contact_cards', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ChannelsTableCreateCompanionBuilder = ChannelsCompanion Function({
  Value<String> id,
  required String publishOfferDid,
  required String mediatorDid,
  required String offerLink,
  required ChannelStatus status,
  required ChannelType type,
  Value<bool> isConnectionInitiator,
  Value<String?> outboundMessageId,
  Value<String?> acceptOfferDid,
  Value<String?> permanentChannelDid,
  Value<String?> otherPartyPermanentChannelDid,
  Value<String?> notificationToken,
  Value<String?> otherPartyNotificationToken,
  Value<String?> externalRef,
  required int seqNo,
  Value<DateTime?> messageSyncMarker,
  Value<int> rowid,
});
typedef $$ChannelsTableUpdateCompanionBuilder = ChannelsCompanion Function({
  Value<String> id,
  Value<String> publishOfferDid,
  Value<String> mediatorDid,
  Value<String> offerLink,
  Value<ChannelStatus> status,
  Value<ChannelType> type,
  Value<bool> isConnectionInitiator,
  Value<String?> outboundMessageId,
  Value<String?> acceptOfferDid,
  Value<String?> permanentChannelDid,
  Value<String?> otherPartyPermanentChannelDid,
  Value<String?> notificationToken,
  Value<String?> otherPartyNotificationToken,
  Value<String?> externalRef,
  Value<int> seqNo,
  Value<DateTime?> messageSyncMarker,
  Value<int> rowid,
});

final class $$ChannelsTableReferences
    extends BaseReferences<_$ChannelDatabase, $ChannelsTable, Channel> {
  $$ChannelsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ChannelContactCardsTable,
      List<ChannelContactCard>> _channelContactCardsRefsTable(
          _$ChannelDatabase db) =>
      MultiTypedResultKey.fromTable(db.channelContactCards,
          aliasName: $_aliasNameGenerator(
              db.channels.id, db.channelContactCards.channelId));

  $$ChannelContactCardsTableProcessedTableManager get channelContactCardsRefs {
    final manager = $$ChannelContactCardsTableTableManager(
            $_db, $_db.channelContactCards)
        .filter((f) => f.channelId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_channelContactCardsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ChannelsTableFilterComposer
    extends Composer<_$ChannelDatabase, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get publishOfferDid => $composableBuilder(
      column: $table.publishOfferDid,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediatorDid => $composableBuilder(
      column: $table.mediatorDid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get offerLink => $composableBuilder(
      column: $table.offerLink, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ChannelStatus, ChannelStatus, int>
      get status => $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<ChannelType, ChannelType, int> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<bool> get isConnectionInitiator => $composableBuilder(
      column: $table.isConnectionInitiator,
      builder: (column) => ColumnFilters(column));

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

  ColumnFilters<int> get seqNo => $composableBuilder(
      column: $table.seqNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get messageSyncMarker => $composableBuilder(
      column: $table.messageSyncMarker,
      builder: (column) => ColumnFilters(column));

  Expression<bool> channelContactCardsRefs(
      Expression<bool> Function($$ChannelContactCardsTableFilterComposer f) f) {
    final $$ChannelContactCardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.channelContactCards,
        getReferencedColumn: (t) => t.channelId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelContactCardsTableFilterComposer(
              $db: $db,
              $table: $db.channelContactCards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$ChannelDatabase, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get publishOfferDid => $composableBuilder(
      column: $table.publishOfferDid,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediatorDid => $composableBuilder(
      column: $table.mediatorDid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get offerLink => $composableBuilder(
      column: $table.offerLink, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isConnectionInitiator => $composableBuilder(
      column: $table.isConnectionInitiator,
      builder: (column) => ColumnOrderings(column));

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

  ColumnOrderings<int> get seqNo => $composableBuilder(
      column: $table.seqNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get messageSyncMarker => $composableBuilder(
      column: $table.messageSyncMarker,
      builder: (column) => ColumnOrderings(column));
}

class $$ChannelsTableAnnotationComposer
    extends Composer<_$ChannelDatabase, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get publishOfferDid => $composableBuilder(
      column: $table.publishOfferDid, builder: (column) => column);

  GeneratedColumn<String> get mediatorDid => $composableBuilder(
      column: $table.mediatorDid, builder: (column) => column);

  GeneratedColumn<String> get offerLink =>
      $composableBuilder(column: $table.offerLink, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChannelStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChannelType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<bool> get isConnectionInitiator => $composableBuilder(
      column: $table.isConnectionInitiator, builder: (column) => column);

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

  GeneratedColumn<int> get seqNo =>
      $composableBuilder(column: $table.seqNo, builder: (column) => column);

  GeneratedColumn<DateTime> get messageSyncMarker => $composableBuilder(
      column: $table.messageSyncMarker, builder: (column) => column);

  Expression<T> channelContactCardsRefs<T extends Object>(
      Expression<T> Function($$ChannelContactCardsTableAnnotationComposer a)
          f) {
    final $$ChannelContactCardsTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.channelContactCards,
            getReferencedColumn: (t) => t.channelId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ChannelContactCardsTableAnnotationComposer(
                  $db: $db,
                  $table: $db.channelContactCards,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ChannelsTableTableManager extends RootTableManager<
    _$ChannelDatabase,
    $ChannelsTable,
    Channel,
    $$ChannelsTableFilterComposer,
    $$ChannelsTableOrderingComposer,
    $$ChannelsTableAnnotationComposer,
    $$ChannelsTableCreateCompanionBuilder,
    $$ChannelsTableUpdateCompanionBuilder,
    (Channel, $$ChannelsTableReferences),
    Channel,
    PrefetchHooks Function({bool channelContactCardsRefs})> {
  $$ChannelsTableTableManager(_$ChannelDatabase db, $ChannelsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> publishOfferDid = const Value.absent(),
            Value<String> mediatorDid = const Value.absent(),
            Value<String> offerLink = const Value.absent(),
            Value<ChannelStatus> status = const Value.absent(),
            Value<ChannelType> type = const Value.absent(),
            Value<bool> isConnectionInitiator = const Value.absent(),
            Value<String?> outboundMessageId = const Value.absent(),
            Value<String?> acceptOfferDid = const Value.absent(),
            Value<String?> permanentChannelDid = const Value.absent(),
            Value<String?> otherPartyPermanentChannelDid = const Value.absent(),
            Value<String?> notificationToken = const Value.absent(),
            Value<String?> otherPartyNotificationToken = const Value.absent(),
            Value<String?> externalRef = const Value.absent(),
            Value<int> seqNo = const Value.absent(),
            Value<DateTime?> messageSyncMarker = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChannelsCompanion(
            id: id,
            publishOfferDid: publishOfferDid,
            mediatorDid: mediatorDid,
            offerLink: offerLink,
            status: status,
            type: type,
            isConnectionInitiator: isConnectionInitiator,
            outboundMessageId: outboundMessageId,
            acceptOfferDid: acceptOfferDid,
            permanentChannelDid: permanentChannelDid,
            otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
            notificationToken: notificationToken,
            otherPartyNotificationToken: otherPartyNotificationToken,
            externalRef: externalRef,
            seqNo: seqNo,
            messageSyncMarker: messageSyncMarker,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            Value<String> id = const Value.absent(),
            required String publishOfferDid,
            required String mediatorDid,
            required String offerLink,
            required ChannelStatus status,
            required ChannelType type,
            Value<bool> isConnectionInitiator = const Value.absent(),
            Value<String?> outboundMessageId = const Value.absent(),
            Value<String?> acceptOfferDid = const Value.absent(),
            Value<String?> permanentChannelDid = const Value.absent(),
            Value<String?> otherPartyPermanentChannelDid = const Value.absent(),
            Value<String?> notificationToken = const Value.absent(),
            Value<String?> otherPartyNotificationToken = const Value.absent(),
            Value<String?> externalRef = const Value.absent(),
            required int seqNo,
            Value<DateTime?> messageSyncMarker = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChannelsCompanion.insert(
            id: id,
            publishOfferDid: publishOfferDid,
            mediatorDid: mediatorDid,
            offerLink: offerLink,
            status: status,
            type: type,
            isConnectionInitiator: isConnectionInitiator,
            outboundMessageId: outboundMessageId,
            acceptOfferDid: acceptOfferDid,
            permanentChannelDid: permanentChannelDid,
            otherPartyPermanentChannelDid: otherPartyPermanentChannelDid,
            notificationToken: notificationToken,
            otherPartyNotificationToken: otherPartyNotificationToken,
            externalRef: externalRef,
            seqNo: seqNo,
            messageSyncMarker: messageSyncMarker,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ChannelsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({channelContactCardsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (channelContactCardsRefs) db.channelContactCards
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (channelContactCardsRefs)
                    await $_getPrefetchedData<Channel, $ChannelsTable,
                            ChannelContactCard>(
                        currentTable: table,
                        referencedTable: $$ChannelsTableReferences
                            ._channelContactCardsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChannelsTableReferences(db, table, p0)
                                .channelContactCardsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.channelId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ChannelsTableProcessedTableManager = ProcessedTableManager<
    _$ChannelDatabase,
    $ChannelsTable,
    Channel,
    $$ChannelsTableFilterComposer,
    $$ChannelsTableOrderingComposer,
    $$ChannelsTableAnnotationComposer,
    $$ChannelsTableCreateCompanionBuilder,
    $$ChannelsTableUpdateCompanionBuilder,
    (Channel, $$ChannelsTableReferences),
    Channel,
    PrefetchHooks Function({bool channelContactCardsRefs})>;
typedef $$ChannelContactCardsTableCreateCompanionBuilder
    = ChannelContactCardsCompanion Function({
  Value<int> id,
  required String channelId,
  required String did,
  required String type,
  Value<String> contactInfoJson,
  Value<String?> profilePic,
  required ContactCardType cardType,
});
typedef $$ChannelContactCardsTableUpdateCompanionBuilder
    = ChannelContactCardsCompanion Function({
  Value<int> id,
  Value<String> channelId,
  Value<String> did,
  Value<String> type,
  Value<String> contactInfoJson,
  Value<String?> profilePic,
  Value<ContactCardType> cardType,
});

final class $$ChannelContactCardsTableReferences extends BaseReferences<
    _$ChannelDatabase, $ChannelContactCardsTable, ChannelContactCard> {
  $$ChannelContactCardsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ChannelsTable _channelIdTable(_$ChannelDatabase db) =>
      db.channels.createAlias($_aliasNameGenerator(
          db.channelContactCards.channelId, db.channels.id));

  $$ChannelsTableProcessedTableManager get channelId {
    final $_column = $_itemColumn<String>('channel_id')!;

    final manager = $$ChannelsTableTableManager($_db, $_db.channels)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_channelIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ChannelContactCardsTableFilterComposer
    extends Composer<_$ChannelDatabase, $ChannelContactCardsTable> {
  $$ChannelContactCardsTableFilterComposer({
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

  ColumnFilters<String> get contactInfoJson => $composableBuilder(
      column: $table.contactInfoJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profilePic => $composableBuilder(
      column: $table.profilePic, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ContactCardType, ContactCardType, int>
      get cardType => $composableBuilder(
          column: $table.cardType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$ChannelsTableFilterComposer get channelId {
    final $$ChannelsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.channelId,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableFilterComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChannelContactCardsTableOrderingComposer
    extends Composer<_$ChannelDatabase, $ChannelContactCardsTable> {
  $$ChannelContactCardsTableOrderingComposer({
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

  ColumnOrderings<String> get contactInfoJson => $composableBuilder(
      column: $table.contactInfoJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profilePic => $composableBuilder(
      column: $table.profilePic, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get cardType => $composableBuilder(
      column: $table.cardType, builder: (column) => ColumnOrderings(column));

  $$ChannelsTableOrderingComposer get channelId {
    final $$ChannelsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.channelId,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableOrderingComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChannelContactCardsTableAnnotationComposer
    extends Composer<_$ChannelDatabase, $ChannelContactCardsTable> {
  $$ChannelContactCardsTableAnnotationComposer({
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

  GeneratedColumn<String> get contactInfoJson => $composableBuilder(
      column: $table.contactInfoJson, builder: (column) => column);

  GeneratedColumn<String> get profilePic => $composableBuilder(
      column: $table.profilePic, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ContactCardType, int> get cardType =>
      $composableBuilder(column: $table.cardType, builder: (column) => column);

  $$ChannelsTableAnnotationComposer get channelId {
    final $$ChannelsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.channelId,
        referencedTable: $db.channels,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChannelsTableAnnotationComposer(
              $db: $db,
              $table: $db.channels,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ChannelContactCardsTableTableManager extends RootTableManager<
    _$ChannelDatabase,
    $ChannelContactCardsTable,
    ChannelContactCard,
    $$ChannelContactCardsTableFilterComposer,
    $$ChannelContactCardsTableOrderingComposer,
    $$ChannelContactCardsTableAnnotationComposer,
    $$ChannelContactCardsTableCreateCompanionBuilder,
    $$ChannelContactCardsTableUpdateCompanionBuilder,
    (ChannelContactCard, $$ChannelContactCardsTableReferences),
    ChannelContactCard,
    PrefetchHooks Function({bool channelId})> {
  $$ChannelContactCardsTableTableManager(
      _$ChannelDatabase db, $ChannelContactCardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelContactCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelContactCardsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelContactCardsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> channelId = const Value.absent(),
            Value<String> did = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> contactInfoJson = const Value.absent(),
            Value<String?> profilePic = const Value.absent(),
            Value<ContactCardType> cardType = const Value.absent(),
          }) =>
              ChannelContactCardsCompanion(
            id: id,
            channelId: channelId,
            did: did,
            type: type,
            contactInfoJson: contactInfoJson,
            profilePic: profilePic,
            cardType: cardType,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String channelId,
            required String did,
            required String type,
            Value<String> contactInfoJson = const Value.absent(),
            Value<String?> profilePic = const Value.absent(),
            required ContactCardType cardType,
          }) =>
              ChannelContactCardsCompanion.insert(
            id: id,
            channelId: channelId,
            did: did,
            type: type,
            contactInfoJson: contactInfoJson,
            profilePic: profilePic,
            cardType: cardType,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChannelContactCardsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({channelId = false}) {
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
                if (channelId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.channelId,
                    referencedTable: $$ChannelContactCardsTableReferences
                        ._channelIdTable(db),
                    referencedColumn: $$ChannelContactCardsTableReferences
                        ._channelIdTable(db)
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

typedef $$ChannelContactCardsTableProcessedTableManager = ProcessedTableManager<
    _$ChannelDatabase,
    $ChannelContactCardsTable,
    ChannelContactCard,
    $$ChannelContactCardsTableFilterComposer,
    $$ChannelContactCardsTableOrderingComposer,
    $$ChannelContactCardsTableAnnotationComposer,
    $$ChannelContactCardsTableCreateCompanionBuilder,
    $$ChannelContactCardsTableUpdateCompanionBuilder,
    (ChannelContactCard, $$ChannelContactCardsTableReferences),
    ChannelContactCard,
    PrefetchHooks Function({bool channelId})>;

class $ChannelDatabaseManager {
  final _$ChannelDatabase _db;
  $ChannelDatabaseManager(this._db);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$ChannelContactCardsTableTableManager get channelContactCards =>
      $$ChannelContactCardsTableTableManager(_db, _db.channelContactCards);
}

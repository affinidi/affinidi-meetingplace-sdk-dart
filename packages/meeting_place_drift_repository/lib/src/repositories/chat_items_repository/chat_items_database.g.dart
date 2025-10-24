// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_items_database.dart';

// ignore_for_file: type=lint
class $ChatItemsTable extends ChatItems
    with TableInfo<$ChatItemsTable, ChatItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChatItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _chatIdMeta = const VerificationMeta('chatId');
  @override
  late final GeneratedColumn<String> chatId = GeneratedColumn<String>(
      'chat_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isFromMeMeta =
      const VerificationMeta('isFromMe');
  @override
  late final GeneratedColumn<bool> isFromMe = GeneratedColumn<bool>(
      'is_from_me', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_from_me" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _dateCreatedMeta =
      const VerificationMeta('dateCreated');
  @override
  late final GeneratedColumn<DateTime> dateCreated = GeneratedColumn<DateTime>(
      'date_created', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      clientDefault: clock.now);
  @override
  late final GeneratedColumnWithTypeConverter<ChatItemStatus, int> status =
      GeneratedColumn<int>('status', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ChatItemStatus>($ChatItemsTable.$converterstatus);
  @override
  late final GeneratedColumnWithTypeConverter<ChatItemType, int> type =
      GeneratedColumn<int>('type', aliasedName, false,
              type: DriftSqlType.int, requiredDuringInsert: true)
          .withConverter<ChatItemType>($ChatItemsTable.$convertertype);
  @override
  late final GeneratedColumnWithTypeConverter<EventMessageType?, int>
      eventType = GeneratedColumn<int>('event_type', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<EventMessageType?>(
              $ChatItemsTable.$convertereventTypen);
  @override
  late final GeneratedColumnWithTypeConverter<ConciergeMessageType?, int>
      conciergeType = GeneratedColumn<int>('concierge_type', aliasedName, true,
              type: DriftSqlType.int, requiredDuringInsert: false)
          .withConverter<ConciergeMessageType?>(
              $ChatItemsTable.$converterconciergeTypen);
  @override
  late final GeneratedColumnWithTypeConverter<Map<String, dynamic>?, String>
      data = GeneratedColumn<String>('data', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<Map<String, dynamic>?>(
              $ChatItemsTable.$converterdatan);
  static const VerificationMeta _senderDidMeta =
      const VerificationMeta('senderDid');
  @override
  late final GeneratedColumn<String> senderDid = GeneratedColumn<String>(
      'sender_did', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        chatId,
        messageId,
        value,
        isFromMe,
        dateCreated,
        status,
        type,
        eventType,
        conciergeType,
        data,
        senderDid
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chat_items';
  @override
  VerificationContext validateIntegrity(Insertable<ChatItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('chat_id')) {
      context.handle(_chatIdMeta,
          chatId.isAcceptableOrUnknown(data['chat_id']!, _chatIdMeta));
    } else if (isInserting) {
      context.missing(_chatIdMeta);
    }
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('is_from_me')) {
      context.handle(_isFromMeMeta,
          isFromMe.isAcceptableOrUnknown(data['is_from_me']!, _isFromMeMeta));
    }
    if (data.containsKey('date_created')) {
      context.handle(
          _dateCreatedMeta,
          dateCreated.isAcceptableOrUnknown(
              data['date_created']!, _dateCreatedMeta));
    }
    if (data.containsKey('sender_did')) {
      context.handle(_senderDidMeta,
          senderDid.isAcceptableOrUnknown(data['sender_did']!, _senderDidMeta));
    } else if (isInserting) {
      context.missing(_senderDidMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  ChatItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChatItem(
      chatId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chat_id'])!,
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
      isFromMe: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_from_me'])!,
      dateCreated: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date_created'])!,
      status: $ChatItemsTable.$converterstatus.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}status'])!),
      type: $ChatItemsTable.$convertertype.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}type'])!),
      eventType: $ChatItemsTable.$convertereventTypen.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}event_type'])),
      conciergeType: $ChatItemsTable.$converterconciergeTypen.fromSql(
          attachedDatabase.typeMapping.read(
              DriftSqlType.int, data['${effectivePrefix}concierge_type'])),
      data: $ChatItemsTable.$converterdatan.fromSql(attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])),
      senderDid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender_did'])!,
    );
  }

  @override
  $ChatItemsTable createAlias(String alias) {
    return $ChatItemsTable(attachedDatabase, alias);
  }

  static TypeConverter<ChatItemStatus, int> $converterstatus =
      const _ChatItemStatusConverter();
  static TypeConverter<ChatItemType, int> $convertertype =
      const _ChatItemTypeConverter();
  static TypeConverter<EventMessageType, int> $convertereventType =
      const _EventMessageTypeConverter();
  static TypeConverter<EventMessageType?, int?> $convertereventTypen =
      NullAwareTypeConverter.wrap($convertereventType);
  static TypeConverter<ConciergeMessageType, int> $converterconciergeType =
      const _ConciergeMessageTypeConverter();
  static TypeConverter<ConciergeMessageType?, int?> $converterconciergeTypen =
      NullAwareTypeConverter.wrap($converterconciergeType);
  static TypeConverter<Map<String, dynamic>, String> $converterdata =
      const _ConciergeDataConverter();
  static TypeConverter<Map<String, dynamic>?, String?> $converterdatan =
      NullAwareTypeConverter.wrap($converterdata);
}

class ChatItem extends DataClass implements Insertable<ChatItem> {
  /// The chat ID this item belongs to.
  final String chatId;

  /// Unique identifier for the chat item.
  final String messageId;

  /// The main content of the chat item.
  final String? value;

  /// Indicates if the item was sent by the local user.
  final bool isFromMe;

  /// Timestamp when the item was created.
  final DateTime dateCreated;

  /// Status of the chat item.
  final ChatItemStatus status;

  /// Type of the chat item.
  final ChatItemType type;

  /// Event message type, if applicable.
  final EventMessageType? eventType;

  /// Concierge message type, if applicable.
  final ConciergeMessageType? conciergeType;

  /// Additional data for concierge messages.
  final Map<String, dynamic>? data;

  /// DID of the sender.
  final String senderDid;
  const ChatItem(
      {required this.chatId,
      required this.messageId,
      this.value,
      required this.isFromMe,
      required this.dateCreated,
      required this.status,
      required this.type,
      this.eventType,
      this.conciergeType,
      this.data,
      required this.senderDid});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['chat_id'] = Variable<String>(chatId);
    map['message_id'] = Variable<String>(messageId);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['is_from_me'] = Variable<bool>(isFromMe);
    map['date_created'] = Variable<DateTime>(dateCreated);
    {
      map['status'] =
          Variable<int>($ChatItemsTable.$converterstatus.toSql(status));
    }
    {
      map['type'] = Variable<int>($ChatItemsTable.$convertertype.toSql(type));
    }
    if (!nullToAbsent || eventType != null) {
      map['event_type'] =
          Variable<int>($ChatItemsTable.$convertereventTypen.toSql(eventType));
    }
    if (!nullToAbsent || conciergeType != null) {
      map['concierge_type'] = Variable<int>(
          $ChatItemsTable.$converterconciergeTypen.toSql(conciergeType));
    }
    if (!nullToAbsent || data != null) {
      map['data'] =
          Variable<String>($ChatItemsTable.$converterdatan.toSql(data));
    }
    map['sender_did'] = Variable<String>(senderDid);
    return map;
  }

  ChatItemsCompanion toCompanion(bool nullToAbsent) {
    return ChatItemsCompanion(
      chatId: Value(chatId),
      messageId: Value(messageId),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      isFromMe: Value(isFromMe),
      dateCreated: Value(dateCreated),
      status: Value(status),
      type: Value(type),
      eventType: eventType == null && nullToAbsent
          ? const Value.absent()
          : Value(eventType),
      conciergeType: conciergeType == null && nullToAbsent
          ? const Value.absent()
          : Value(conciergeType),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
      senderDid: Value(senderDid),
    );
  }

  factory ChatItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChatItem(
      chatId: serializer.fromJson<String>(json['chatId']),
      messageId: serializer.fromJson<String>(json['messageId']),
      value: serializer.fromJson<String?>(json['value']),
      isFromMe: serializer.fromJson<bool>(json['isFromMe']),
      dateCreated: serializer.fromJson<DateTime>(json['dateCreated']),
      status: serializer.fromJson<ChatItemStatus>(json['status']),
      type: serializer.fromJson<ChatItemType>(json['type']),
      eventType: serializer.fromJson<EventMessageType?>(json['eventType']),
      conciergeType:
          serializer.fromJson<ConciergeMessageType?>(json['conciergeType']),
      data: serializer.fromJson<Map<String, dynamic>?>(json['data']),
      senderDid: serializer.fromJson<String>(json['senderDid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'chatId': serializer.toJson<String>(chatId),
      'messageId': serializer.toJson<String>(messageId),
      'value': serializer.toJson<String?>(value),
      'isFromMe': serializer.toJson<bool>(isFromMe),
      'dateCreated': serializer.toJson<DateTime>(dateCreated),
      'status': serializer.toJson<ChatItemStatus>(status),
      'type': serializer.toJson<ChatItemType>(type),
      'eventType': serializer.toJson<EventMessageType?>(eventType),
      'conciergeType': serializer.toJson<ConciergeMessageType?>(conciergeType),
      'data': serializer.toJson<Map<String, dynamic>?>(data),
      'senderDid': serializer.toJson<String>(senderDid),
    };
  }

  ChatItem copyWith(
          {String? chatId,
          String? messageId,
          Value<String?> value = const Value.absent(),
          bool? isFromMe,
          DateTime? dateCreated,
          ChatItemStatus? status,
          ChatItemType? type,
          Value<EventMessageType?> eventType = const Value.absent(),
          Value<ConciergeMessageType?> conciergeType = const Value.absent(),
          Value<Map<String, dynamic>?> data = const Value.absent(),
          String? senderDid}) =>
      ChatItem(
        chatId: chatId ?? this.chatId,
        messageId: messageId ?? this.messageId,
        value: value.present ? value.value : this.value,
        isFromMe: isFromMe ?? this.isFromMe,
        dateCreated: dateCreated ?? this.dateCreated,
        status: status ?? this.status,
        type: type ?? this.type,
        eventType: eventType.present ? eventType.value : this.eventType,
        conciergeType:
            conciergeType.present ? conciergeType.value : this.conciergeType,
        data: data.present ? data.value : this.data,
        senderDid: senderDid ?? this.senderDid,
      );
  ChatItem copyWithCompanion(ChatItemsCompanion data) {
    return ChatItem(
      chatId: data.chatId.present ? data.chatId.value : this.chatId,
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      value: data.value.present ? data.value.value : this.value,
      isFromMe: data.isFromMe.present ? data.isFromMe.value : this.isFromMe,
      dateCreated:
          data.dateCreated.present ? data.dateCreated.value : this.dateCreated,
      status: data.status.present ? data.status.value : this.status,
      type: data.type.present ? data.type.value : this.type,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      conciergeType: data.conciergeType.present
          ? data.conciergeType.value
          : this.conciergeType,
      data: data.data.present ? data.data.value : this.data,
      senderDid: data.senderDid.present ? data.senderDid.value : this.senderDid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChatItem(')
          ..write('chatId: $chatId, ')
          ..write('messageId: $messageId, ')
          ..write('value: $value, ')
          ..write('isFromMe: $isFromMe, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('eventType: $eventType, ')
          ..write('conciergeType: $conciergeType, ')
          ..write('data: $data, ')
          ..write('senderDid: $senderDid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(chatId, messageId, value, isFromMe,
      dateCreated, status, type, eventType, conciergeType, data, senderDid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChatItem &&
          other.chatId == this.chatId &&
          other.messageId == this.messageId &&
          other.value == this.value &&
          other.isFromMe == this.isFromMe &&
          other.dateCreated == this.dateCreated &&
          other.status == this.status &&
          other.type == this.type &&
          other.eventType == this.eventType &&
          other.conciergeType == this.conciergeType &&
          other.data == this.data &&
          other.senderDid == this.senderDid);
}

class ChatItemsCompanion extends UpdateCompanion<ChatItem> {
  final Value<String> chatId;
  final Value<String> messageId;
  final Value<String?> value;
  final Value<bool> isFromMe;
  final Value<DateTime> dateCreated;
  final Value<ChatItemStatus> status;
  final Value<ChatItemType> type;
  final Value<EventMessageType?> eventType;
  final Value<ConciergeMessageType?> conciergeType;
  final Value<Map<String, dynamic>?> data;
  final Value<String> senderDid;
  final Value<int> rowid;
  const ChatItemsCompanion({
    this.chatId = const Value.absent(),
    this.messageId = const Value.absent(),
    this.value = const Value.absent(),
    this.isFromMe = const Value.absent(),
    this.dateCreated = const Value.absent(),
    this.status = const Value.absent(),
    this.type = const Value.absent(),
    this.eventType = const Value.absent(),
    this.conciergeType = const Value.absent(),
    this.data = const Value.absent(),
    this.senderDid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChatItemsCompanion.insert({
    required String chatId,
    required String messageId,
    this.value = const Value.absent(),
    this.isFromMe = const Value.absent(),
    this.dateCreated = const Value.absent(),
    required ChatItemStatus status,
    required ChatItemType type,
    this.eventType = const Value.absent(),
    this.conciergeType = const Value.absent(),
    this.data = const Value.absent(),
    required String senderDid,
    this.rowid = const Value.absent(),
  })  : chatId = Value(chatId),
        messageId = Value(messageId),
        status = Value(status),
        type = Value(type),
        senderDid = Value(senderDid);
  static Insertable<ChatItem> custom({
    Expression<String>? chatId,
    Expression<String>? messageId,
    Expression<String>? value,
    Expression<bool>? isFromMe,
    Expression<DateTime>? dateCreated,
    Expression<int>? status,
    Expression<int>? type,
    Expression<int>? eventType,
    Expression<int>? conciergeType,
    Expression<String>? data,
    Expression<String>? senderDid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (chatId != null) 'chat_id': chatId,
      if (messageId != null) 'message_id': messageId,
      if (value != null) 'value': value,
      if (isFromMe != null) 'is_from_me': isFromMe,
      if (dateCreated != null) 'date_created': dateCreated,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (eventType != null) 'event_type': eventType,
      if (conciergeType != null) 'concierge_type': conciergeType,
      if (data != null) 'data': data,
      if (senderDid != null) 'sender_did': senderDid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChatItemsCompanion copyWith(
      {Value<String>? chatId,
      Value<String>? messageId,
      Value<String?>? value,
      Value<bool>? isFromMe,
      Value<DateTime>? dateCreated,
      Value<ChatItemStatus>? status,
      Value<ChatItemType>? type,
      Value<EventMessageType?>? eventType,
      Value<ConciergeMessageType?>? conciergeType,
      Value<Map<String, dynamic>?>? data,
      Value<String>? senderDid,
      Value<int>? rowid}) {
    return ChatItemsCompanion(
      chatId: chatId ?? this.chatId,
      messageId: messageId ?? this.messageId,
      value: value ?? this.value,
      isFromMe: isFromMe ?? this.isFromMe,
      dateCreated: dateCreated ?? this.dateCreated,
      status: status ?? this.status,
      type: type ?? this.type,
      eventType: eventType ?? this.eventType,
      conciergeType: conciergeType ?? this.conciergeType,
      data: data ?? this.data,
      senderDid: senderDid ?? this.senderDid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (chatId.present) {
      map['chat_id'] = Variable<String>(chatId.value);
    }
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (isFromMe.present) {
      map['is_from_me'] = Variable<bool>(isFromMe.value);
    }
    if (dateCreated.present) {
      map['date_created'] = Variable<DateTime>(dateCreated.value);
    }
    if (status.present) {
      map['status'] =
          Variable<int>($ChatItemsTable.$converterstatus.toSql(status.value));
    }
    if (type.present) {
      map['type'] =
          Variable<int>($ChatItemsTable.$convertertype.toSql(type.value));
    }
    if (eventType.present) {
      map['event_type'] = Variable<int>(
          $ChatItemsTable.$convertereventTypen.toSql(eventType.value));
    }
    if (conciergeType.present) {
      map['concierge_type'] = Variable<int>(
          $ChatItemsTable.$converterconciergeTypen.toSql(conciergeType.value));
    }
    if (data.present) {
      map['data'] =
          Variable<String>($ChatItemsTable.$converterdatan.toSql(data.value));
    }
    if (senderDid.present) {
      map['sender_did'] = Variable<String>(senderDid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChatItemsCompanion(')
          ..write('chatId: $chatId, ')
          ..write('messageId: $messageId, ')
          ..write('value: $value, ')
          ..write('isFromMe: $isFromMe, ')
          ..write('dateCreated: $dateCreated, ')
          ..write('status: $status, ')
          ..write('type: $type, ')
          ..write('eventType: $eventType, ')
          ..write('conciergeType: $conciergeType, ')
          ..write('data: $data, ')
          ..write('senderDid: $senderDid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReactionsTable extends Reactions
    with TableInfo<$ReactionsTable, Reaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints:
          'REFERENCES chat_items(message_id) ON DELETE CASCADE NOT NULL');
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [messageId, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reactions';
  @override
  VerificationContext validateIntegrity(Insertable<Reaction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  Reaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reaction(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $ReactionsTable createAlias(String alias) {
    return $ReactionsTable(attachedDatabase, alias);
  }
}

class Reaction extends DataClass implements Insertable<Reaction> {
  /// The message ID this reaction is associated with.
  final String messageId;

  /// The reaction value (e.g., emoji).
  final String value;
  const Reaction({required this.messageId, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['value'] = Variable<String>(value);
    return map;
  }

  ReactionsCompanion toCompanion(bool nullToAbsent) {
    return ReactionsCompanion(
      messageId: Value(messageId),
      value: Value(value),
    );
  }

  factory Reaction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reaction(
      messageId: serializer.fromJson<String>(json['messageId']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'value': serializer.toJson<String>(value),
    };
  }

  Reaction copyWith({String? messageId, String? value}) => Reaction(
        messageId: messageId ?? this.messageId,
        value: value ?? this.value,
      );
  Reaction copyWithCompanion(ReactionsCompanion data) {
    return Reaction(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reaction(')
          ..write('messageId: $messageId, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(messageId, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reaction &&
          other.messageId == this.messageId &&
          other.value == this.value);
}

class ReactionsCompanion extends UpdateCompanion<Reaction> {
  final Value<String> messageId;
  final Value<String> value;
  final Value<int> rowid;
  const ReactionsCompanion({
    this.messageId = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReactionsCompanion.insert({
    required String messageId,
    required String value,
    this.rowid = const Value.absent(),
  })  : messageId = Value(messageId),
        value = Value(value);
  static Insertable<Reaction> custom({
    Expression<String>? messageId,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReactionsCompanion copyWith(
      {Value<String>? messageId, Value<String>? value, Value<int>? rowid}) {
    return ReactionsCompanion(
      messageId: messageId ?? this.messageId,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReactionsCompanion(')
          ..write('messageId: $messageId, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta =
      const VerificationMeta('messageId');
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
      'message_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      $customConstraints:
          'REFERENCES chat_items(message_id) ON DELETE CASCADE NOT NULL');
  static const VerificationMeta _attachmentIdMeta =
      const VerificationMeta('attachmentId');
  @override
  late final GeneratedColumn<int> attachmentId = GeneratedColumn<int>(
      'attachment_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _descriptionMeta =
      const VerificationMeta('description');
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
      'description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _filenameMeta =
      const VerificationMeta('filename');
  @override
  late final GeneratedColumn<String> filename = GeneratedColumn<String>(
      'filename', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _mediaTypeMeta =
      const VerificationMeta('mediaType');
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
      'media_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
      'format', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _lastModifiedTimeMeta =
      const VerificationMeta('lastModifiedTime');
  @override
  late final GeneratedColumn<DateTime> lastModifiedTime =
      GeneratedColumn<DateTime>('last_modified_time', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _jwsMeta = const VerificationMeta('jws');
  @override
  late final GeneratedColumn<String> jws = GeneratedColumn<String>(
      'jws', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _byteCountMeta =
      const VerificationMeta('byteCount');
  @override
  late final GeneratedColumn<int> byteCount = GeneratedColumn<int>(
      'byte_count', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _hashMeta = const VerificationMeta('hash');
  @override
  late final GeneratedColumn<String> hash = GeneratedColumn<String>(
      'hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _base64Meta = const VerificationMeta('base64');
  @override
  late final GeneratedColumn<String> base64 = GeneratedColumn<String>(
      'base64', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
      'json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        messageId,
        attachmentId,
        id,
        description,
        filename,
        mediaType,
        format,
        lastModifiedTime,
        jws,
        byteCount,
        hash,
        base64,
        json
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(Insertable<Attachment> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(_messageIdMeta,
          messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta));
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('attachment_id')) {
      context.handle(
          _attachmentIdMeta,
          attachmentId.isAcceptableOrUnknown(
              data['attachment_id']!, _attachmentIdMeta));
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
          _descriptionMeta,
          description.isAcceptableOrUnknown(
              data['description']!, _descriptionMeta));
    }
    if (data.containsKey('filename')) {
      context.handle(_filenameMeta,
          filename.isAcceptableOrUnknown(data['filename']!, _filenameMeta));
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta,
          mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    }
    if (data.containsKey('format')) {
      context.handle(_formatMeta,
          format.isAcceptableOrUnknown(data['format']!, _formatMeta));
    }
    if (data.containsKey('last_modified_time')) {
      context.handle(
          _lastModifiedTimeMeta,
          lastModifiedTime.isAcceptableOrUnknown(
              data['last_modified_time']!, _lastModifiedTimeMeta));
    }
    if (data.containsKey('jws')) {
      context.handle(
          _jwsMeta, jws.isAcceptableOrUnknown(data['jws']!, _jwsMeta));
    }
    if (data.containsKey('byte_count')) {
      context.handle(_byteCountMeta,
          byteCount.isAcceptableOrUnknown(data['byte_count']!, _byteCountMeta));
    }
    if (data.containsKey('hash')) {
      context.handle(
          _hashMeta, hash.isAcceptableOrUnknown(data['hash']!, _hashMeta));
    }
    if (data.containsKey('base64')) {
      context.handle(_base64Meta,
          base64.isAcceptableOrUnknown(data['base64']!, _base64Meta));
    }
    if (data.containsKey('json')) {
      context.handle(
          _jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attachmentId};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      messageId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}message_id'])!,
      attachmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attachment_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id']),
      description: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}description']),
      filename: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}filename']),
      mediaType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_type']),
      format: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}format']),
      lastModifiedTime: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_modified_time']),
      jws: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}jws']),
      byteCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}byte_count']),
      hash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}hash']),
      base64: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}base64']),
      json: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json']),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  /// The message ID this attachment is associated with.
  final String messageId;

  /// Auto-incrementing unique identifier for the attachment.
  final int attachmentId;

  /// Unique identifier for the attachment.
  final String? id;

  /// Description of the attachment.
  final String? description;

  /// Filename of the attachment.
  final String? filename;

  /// MIME type of the attachment.
  final String? mediaType;

  /// Format of the attachment.
  final String? format;

  /// Last modified time of the attachment.
  final DateTime? lastModifiedTime;

  /// jws of the attachment.
  final String? jws;

  /// Size in bytes of the attachment.
  final int? byteCount;

  /// Hash of the attachment.
  final String? hash;

  /// Base64 representation of the attachment.
  final String? base64;

  /// JSON metadata of the attachment.
  final String? json;
  const Attachment(
      {required this.messageId,
      required this.attachmentId,
      this.id,
      this.description,
      this.filename,
      this.mediaType,
      this.format,
      this.lastModifiedTime,
      this.jws,
      this.byteCount,
      this.hash,
      this.base64,
      this.json});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['attachment_id'] = Variable<int>(attachmentId);
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || filename != null) {
      map['filename'] = Variable<String>(filename);
    }
    if (!nullToAbsent || mediaType != null) {
      map['media_type'] = Variable<String>(mediaType);
    }
    if (!nullToAbsent || format != null) {
      map['format'] = Variable<String>(format);
    }
    if (!nullToAbsent || lastModifiedTime != null) {
      map['last_modified_time'] = Variable<DateTime>(lastModifiedTime);
    }
    if (!nullToAbsent || jws != null) {
      map['jws'] = Variable<String>(jws);
    }
    if (!nullToAbsent || byteCount != null) {
      map['byte_count'] = Variable<int>(byteCount);
    }
    if (!nullToAbsent || hash != null) {
      map['hash'] = Variable<String>(hash);
    }
    if (!nullToAbsent || base64 != null) {
      map['base64'] = Variable<String>(base64);
    }
    if (!nullToAbsent || json != null) {
      map['json'] = Variable<String>(json);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      messageId: Value(messageId),
      attachmentId: Value(attachmentId),
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      filename: filename == null && nullToAbsent
          ? const Value.absent()
          : Value(filename),
      mediaType: mediaType == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaType),
      format:
          format == null && nullToAbsent ? const Value.absent() : Value(format),
      lastModifiedTime: lastModifiedTime == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedTime),
      jws: jws == null && nullToAbsent ? const Value.absent() : Value(jws),
      byteCount: byteCount == null && nullToAbsent
          ? const Value.absent()
          : Value(byteCount),
      hash: hash == null && nullToAbsent ? const Value.absent() : Value(hash),
      base64:
          base64 == null && nullToAbsent ? const Value.absent() : Value(base64),
      json: json == null && nullToAbsent ? const Value.absent() : Value(json),
    );
  }

  factory Attachment.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      messageId: serializer.fromJson<String>(json['messageId']),
      attachmentId: serializer.fromJson<int>(json['attachmentId']),
      id: serializer.fromJson<String?>(json['id']),
      description: serializer.fromJson<String?>(json['description']),
      filename: serializer.fromJson<String?>(json['filename']),
      mediaType: serializer.fromJson<String?>(json['mediaType']),
      format: serializer.fromJson<String?>(json['format']),
      lastModifiedTime:
          serializer.fromJson<DateTime?>(json['lastModifiedTime']),
      jws: serializer.fromJson<String?>(json['jws']),
      byteCount: serializer.fromJson<int?>(json['byteCount']),
      hash: serializer.fromJson<String?>(json['hash']),
      base64: serializer.fromJson<String?>(json['base64']),
      json: serializer.fromJson<String?>(json['json']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'attachmentId': serializer.toJson<int>(attachmentId),
      'id': serializer.toJson<String?>(id),
      'description': serializer.toJson<String?>(description),
      'filename': serializer.toJson<String?>(filename),
      'mediaType': serializer.toJson<String?>(mediaType),
      'format': serializer.toJson<String?>(format),
      'lastModifiedTime': serializer.toJson<DateTime?>(lastModifiedTime),
      'jws': serializer.toJson<String?>(jws),
      'byteCount': serializer.toJson<int?>(byteCount),
      'hash': serializer.toJson<String?>(hash),
      'base64': serializer.toJson<String?>(base64),
      'json': serializer.toJson<String?>(json),
    };
  }

  Attachment copyWith(
          {String? messageId,
          int? attachmentId,
          Value<String?> id = const Value.absent(),
          Value<String?> description = const Value.absent(),
          Value<String?> filename = const Value.absent(),
          Value<String?> mediaType = const Value.absent(),
          Value<String?> format = const Value.absent(),
          Value<DateTime?> lastModifiedTime = const Value.absent(),
          Value<String?> jws = const Value.absent(),
          Value<int?> byteCount = const Value.absent(),
          Value<String?> hash = const Value.absent(),
          Value<String?> base64 = const Value.absent(),
          Value<String?> json = const Value.absent()}) =>
      Attachment(
        messageId: messageId ?? this.messageId,
        attachmentId: attachmentId ?? this.attachmentId,
        id: id.present ? id.value : this.id,
        description: description.present ? description.value : this.description,
        filename: filename.present ? filename.value : this.filename,
        mediaType: mediaType.present ? mediaType.value : this.mediaType,
        format: format.present ? format.value : this.format,
        lastModifiedTime: lastModifiedTime.present
            ? lastModifiedTime.value
            : this.lastModifiedTime,
        jws: jws.present ? jws.value : this.jws,
        byteCount: byteCount.present ? byteCount.value : this.byteCount,
        hash: hash.present ? hash.value : this.hash,
        base64: base64.present ? base64.value : this.base64,
        json: json.present ? json.value : this.json,
      );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      id: data.id.present ? data.id.value : this.id,
      description:
          data.description.present ? data.description.value : this.description,
      filename: data.filename.present ? data.filename.value : this.filename,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      format: data.format.present ? data.format.value : this.format,
      lastModifiedTime: data.lastModifiedTime.present
          ? data.lastModifiedTime.value
          : this.lastModifiedTime,
      jws: data.jws.present ? data.jws.value : this.jws,
      byteCount: data.byteCount.present ? data.byteCount.value : this.byteCount,
      hash: data.hash.present ? data.hash.value : this.hash,
      base64: data.base64.present ? data.base64.value : this.base64,
      json: data.json.present ? data.json.value : this.json,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('messageId: $messageId, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('filename: $filename, ')
          ..write('mediaType: $mediaType, ')
          ..write('format: $format, ')
          ..write('lastModifiedTime: $lastModifiedTime, ')
          ..write('jws: $jws, ')
          ..write('byteCount: $byteCount, ')
          ..write('hash: $hash, ')
          ..write('base64: $base64, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      messageId,
      attachmentId,
      id,
      description,
      filename,
      mediaType,
      format,
      lastModifiedTime,
      jws,
      byteCount,
      hash,
      base64,
      json);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.messageId == this.messageId &&
          other.attachmentId == this.attachmentId &&
          other.id == this.id &&
          other.description == this.description &&
          other.filename == this.filename &&
          other.mediaType == this.mediaType &&
          other.format == this.format &&
          other.lastModifiedTime == this.lastModifiedTime &&
          other.jws == this.jws &&
          other.byteCount == this.byteCount &&
          other.hash == this.hash &&
          other.base64 == this.base64 &&
          other.json == this.json);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> messageId;
  final Value<int> attachmentId;
  final Value<String?> id;
  final Value<String?> description;
  final Value<String?> filename;
  final Value<String?> mediaType;
  final Value<String?> format;
  final Value<DateTime?> lastModifiedTime;
  final Value<String?> jws;
  final Value<int?> byteCount;
  final Value<String?> hash;
  final Value<String?> base64;
  final Value<String?> json;
  const AttachmentsCompanion({
    this.messageId = const Value.absent(),
    this.attachmentId = const Value.absent(),
    this.id = const Value.absent(),
    this.description = const Value.absent(),
    this.filename = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.format = const Value.absent(),
    this.lastModifiedTime = const Value.absent(),
    this.jws = const Value.absent(),
    this.byteCount = const Value.absent(),
    this.hash = const Value.absent(),
    this.base64 = const Value.absent(),
    this.json = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String messageId,
    this.attachmentId = const Value.absent(),
    this.id = const Value.absent(),
    this.description = const Value.absent(),
    this.filename = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.format = const Value.absent(),
    this.lastModifiedTime = const Value.absent(),
    this.jws = const Value.absent(),
    this.byteCount = const Value.absent(),
    this.hash = const Value.absent(),
    this.base64 = const Value.absent(),
    this.json = const Value.absent(),
  }) : messageId = Value(messageId);
  static Insertable<Attachment> custom({
    Expression<String>? messageId,
    Expression<int>? attachmentId,
    Expression<String>? id,
    Expression<String>? description,
    Expression<String>? filename,
    Expression<String>? mediaType,
    Expression<String>? format,
    Expression<DateTime>? lastModifiedTime,
    Expression<String>? jws,
    Expression<int>? byteCount,
    Expression<String>? hash,
    Expression<String>? base64,
    Expression<String>? json,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (id != null) 'id': id,
      if (description != null) 'description': description,
      if (filename != null) 'filename': filename,
      if (mediaType != null) 'media_type': mediaType,
      if (format != null) 'format': format,
      if (lastModifiedTime != null) 'last_modified_time': lastModifiedTime,
      if (jws != null) 'jws': jws,
      if (byteCount != null) 'byte_count': byteCount,
      if (hash != null) 'hash': hash,
      if (base64 != null) 'base64': base64,
      if (json != null) 'json': json,
    });
  }

  AttachmentsCompanion copyWith(
      {Value<String>? messageId,
      Value<int>? attachmentId,
      Value<String?>? id,
      Value<String?>? description,
      Value<String?>? filename,
      Value<String?>? mediaType,
      Value<String?>? format,
      Value<DateTime?>? lastModifiedTime,
      Value<String?>? jws,
      Value<int?>? byteCount,
      Value<String?>? hash,
      Value<String?>? base64,
      Value<String?>? json}) {
    return AttachmentsCompanion(
      messageId: messageId ?? this.messageId,
      attachmentId: attachmentId ?? this.attachmentId,
      id: id ?? this.id,
      description: description ?? this.description,
      filename: filename ?? this.filename,
      mediaType: mediaType ?? this.mediaType,
      format: format ?? this.format,
      lastModifiedTime: lastModifiedTime ?? this.lastModifiedTime,
      jws: jws ?? this.jws,
      byteCount: byteCount ?? this.byteCount,
      hash: hash ?? this.hash,
      base64: base64 ?? this.base64,
      json: json ?? this.json,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (attachmentId.present) {
      map['attachment_id'] = Variable<int>(attachmentId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (filename.present) {
      map['filename'] = Variable<String>(filename.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (lastModifiedTime.present) {
      map['last_modified_time'] = Variable<DateTime>(lastModifiedTime.value);
    }
    if (jws.present) {
      map['jws'] = Variable<String>(jws.value);
    }
    if (byteCount.present) {
      map['byte_count'] = Variable<int>(byteCount.value);
    }
    if (hash.present) {
      map['hash'] = Variable<String>(hash.value);
    }
    if (base64.present) {
      map['base64'] = Variable<String>(base64.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('messageId: $messageId, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('filename: $filename, ')
          ..write('mediaType: $mediaType, ')
          ..write('format: $format, ')
          ..write('lastModifiedTime: $lastModifiedTime, ')
          ..write('jws: $jws, ')
          ..write('byteCount: $byteCount, ')
          ..write('hash: $hash, ')
          ..write('base64: $base64, ')
          ..write('json: $json')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsLinksTable extends AttachmentsLinks
    with TableInfo<$AttachmentsLinksTable, AttachmentLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attachmentIdMeta =
      const VerificationMeta('attachmentId');
  @override
  late final GeneratedColumn<int> attachmentId = GeneratedColumn<int>(
      'attachment_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      $customConstraints:
          'REFERENCES attachments(attachment_id) ON DELETE CASCADE NOT NULL');
  @override
  late final GeneratedColumnWithTypeConverter<Uri, String> url =
      GeneratedColumn<String>('url', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<Uri>($AttachmentsLinksTable.$converterurl);
  @override
  List<GeneratedColumn> get $columns => [attachmentId, url];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments_links';
  @override
  VerificationContext validateIntegrity(Insertable<AttachmentLink> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attachment_id')) {
      context.handle(
          _attachmentIdMeta,
          attachmentId.isAcceptableOrUnknown(
              data['attachment_id']!, _attachmentIdMeta));
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  AttachmentLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentLink(
      attachmentId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attachment_id'])!,
      url: $AttachmentsLinksTable.$converterurl.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}url'])!),
    );
  }

  @override
  $AttachmentsLinksTable createAlias(String alias) {
    return $AttachmentsLinksTable(attachedDatabase, alias);
  }

  static TypeConverter<Uri, String> $converterurl = const _UriConverter();
}

class AttachmentLink extends DataClass implements Insertable<AttachmentLink> {
  /// The attachment ID this link is associated with.
  final int attachmentId;

  /// The URL of the attachment link.
  final Uri url;
  const AttachmentLink({required this.attachmentId, required this.url});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attachment_id'] = Variable<int>(attachmentId);
    {
      map['url'] =
          Variable<String>($AttachmentsLinksTable.$converterurl.toSql(url));
    }
    return map;
  }

  AttachmentsLinksCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsLinksCompanion(
      attachmentId: Value(attachmentId),
      url: Value(url),
    );
  }

  factory AttachmentLink.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentLink(
      attachmentId: serializer.fromJson<int>(json['attachmentId']),
      url: serializer.fromJson<Uri>(json['url']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attachmentId': serializer.toJson<int>(attachmentId),
      'url': serializer.toJson<Uri>(url),
    };
  }

  AttachmentLink copyWith({int? attachmentId, Uri? url}) => AttachmentLink(
        attachmentId: attachmentId ?? this.attachmentId,
        url: url ?? this.url,
      );
  AttachmentLink copyWithCompanion(AttachmentsLinksCompanion data) {
    return AttachmentLink(
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      url: data.url.present ? data.url.value : this.url,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentLink(')
          ..write('attachmentId: $attachmentId, ')
          ..write('url: $url')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(attachmentId, url);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentLink &&
          other.attachmentId == this.attachmentId &&
          other.url == this.url);
}

class AttachmentsLinksCompanion extends UpdateCompanion<AttachmentLink> {
  final Value<int> attachmentId;
  final Value<Uri> url;
  final Value<int> rowid;
  const AttachmentsLinksCompanion({
    this.attachmentId = const Value.absent(),
    this.url = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsLinksCompanion.insert({
    required int attachmentId,
    required Uri url,
    this.rowid = const Value.absent(),
  })  : attachmentId = Value(attachmentId),
        url = Value(url);
  static Insertable<AttachmentLink> custom({
    Expression<int>? attachmentId,
    Expression<String>? url,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (url != null) 'url': url,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsLinksCompanion copyWith(
      {Value<int>? attachmentId, Value<Uri>? url, Value<int>? rowid}) {
    return AttachmentsLinksCompanion(
      attachmentId: attachmentId ?? this.attachmentId,
      url: url ?? this.url,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attachmentId.present) {
      map['attachment_id'] = Variable<int>(attachmentId.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(
          $AttachmentsLinksTable.$converterurl.toSql(url.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsLinksCompanion(')
          ..write('attachmentId: $attachmentId, ')
          ..write('url: $url, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$ChatItemsDatabase extends GeneratedDatabase {
  _$ChatItemsDatabase(QueryExecutor e) : super(e);
  $ChatItemsDatabaseManager get managers => $ChatItemsDatabaseManager(this);
  late final $ChatItemsTable chatItems = $ChatItemsTable(this);
  late final $ReactionsTable reactions = $ReactionsTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $AttachmentsLinksTable attachmentsLinks =
      $AttachmentsLinksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [chatItems, reactions, attachments, attachmentsLinks];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('chat_items',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('reactions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('chat_items',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('attachments', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('attachments',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('attachments_links', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$ChatItemsTableCreateCompanionBuilder = ChatItemsCompanion Function({
  required String chatId,
  required String messageId,
  Value<String?> value,
  Value<bool> isFromMe,
  Value<DateTime> dateCreated,
  required ChatItemStatus status,
  required ChatItemType type,
  Value<EventMessageType?> eventType,
  Value<ConciergeMessageType?> conciergeType,
  Value<Map<String, dynamic>?> data,
  required String senderDid,
  Value<int> rowid,
});
typedef $$ChatItemsTableUpdateCompanionBuilder = ChatItemsCompanion Function({
  Value<String> chatId,
  Value<String> messageId,
  Value<String?> value,
  Value<bool> isFromMe,
  Value<DateTime> dateCreated,
  Value<ChatItemStatus> status,
  Value<ChatItemType> type,
  Value<EventMessageType?> eventType,
  Value<ConciergeMessageType?> conciergeType,
  Value<Map<String, dynamic>?> data,
  Value<String> senderDid,
  Value<int> rowid,
});

final class $$ChatItemsTableReferences
    extends BaseReferences<_$ChatItemsDatabase, $ChatItemsTable, ChatItem> {
  $$ChatItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReactionsTable, List<Reaction>>
      _reactionsRefsTable(_$ChatItemsDatabase db) =>
          MultiTypedResultKey.fromTable(db.reactions,
              aliasName: $_aliasNameGenerator(
                  db.chatItems.messageId, db.reactions.messageId));

  $$ReactionsTableProcessedTableManager get reactionsRefs {
    final manager = $$ReactionsTableTableManager($_db, $_db.reactions).filter(
        (f) => f.messageId.messageId
            .sqlEquals($_itemColumn<String>('message_id')!));

    final cache = $_typedResult.readTableOrNull(_reactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$AttachmentsTable, List<Attachment>>
      _attachmentsRefsTable(_$ChatItemsDatabase db) =>
          MultiTypedResultKey.fromTable(db.attachments,
              aliasName: $_aliasNameGenerator(
                  db.chatItems.messageId, db.attachments.messageId));

  $$AttachmentsTableProcessedTableManager get attachmentsRefs {
    final manager = $$AttachmentsTableTableManager($_db, $_db.attachments)
        .filter((f) => f.messageId.messageId
            .sqlEquals($_itemColumn<String>('message_id')!));

    final cache = $_typedResult.readTableOrNull(_attachmentsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ChatItemsTableFilterComposer
    extends Composer<_$ChatItemsDatabase, $ChatItemsTable> {
  $$ChatItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isFromMe => $composableBuilder(
      column: $table.isFromMe, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dateCreated => $composableBuilder(
      column: $table.dateCreated, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ChatItemStatus, ChatItemStatus, int>
      get status => $composableBuilder(
          column: $table.status,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<ChatItemType, ChatItemType, int> get type =>
      $composableBuilder(
          column: $table.type,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<EventMessageType?, EventMessageType, int>
      get eventType => $composableBuilder(
          column: $table.eventType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<ConciergeMessageType?, ConciergeMessageType,
          int>
      get conciergeType => $composableBuilder(
          column: $table.conciergeType,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<Map<String, dynamic>?, Map<String, dynamic>,
          String>
      get data => $composableBuilder(
          column: $table.data,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get senderDid => $composableBuilder(
      column: $table.senderDid, builder: (column) => ColumnFilters(column));

  Expression<bool> reactionsRefs(
      Expression<bool> Function($$ReactionsTableFilterComposer f) f) {
    final $$ReactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.reactions,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReactionsTableFilterComposer(
              $db: $db,
              $table: $db.reactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> attachmentsRefs(
      Expression<bool> Function($$AttachmentsTableFilterComposer f) f) {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.attachments,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttachmentsTableFilterComposer(
              $db: $db,
              $table: $db.attachments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChatItemsTableOrderingComposer
    extends Composer<_$ChatItemsDatabase, $ChatItemsTable> {
  $$ChatItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get chatId => $composableBuilder(
      column: $table.chatId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get messageId => $composableBuilder(
      column: $table.messageId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isFromMe => $composableBuilder(
      column: $table.isFromMe, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dateCreated => $composableBuilder(
      column: $table.dateCreated, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get eventType => $composableBuilder(
      column: $table.eventType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get conciergeType => $composableBuilder(
      column: $table.conciergeType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get data => $composableBuilder(
      column: $table.data, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get senderDid => $composableBuilder(
      column: $table.senderDid, builder: (column) => ColumnOrderings(column));
}

class $$ChatItemsTableAnnotationComposer
    extends Composer<_$ChatItemsDatabase, $ChatItemsTable> {
  $$ChatItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get chatId =>
      $composableBuilder(column: $table.chatId, builder: (column) => column);

  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<bool> get isFromMe =>
      $composableBuilder(column: $table.isFromMe, builder: (column) => column);

  GeneratedColumn<DateTime> get dateCreated => $composableBuilder(
      column: $table.dateCreated, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChatItemStatus, int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ChatItemType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumnWithTypeConverter<EventMessageType?, int> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ConciergeMessageType?, int>
      get conciergeType => $composableBuilder(
          column: $table.conciergeType, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Map<String, dynamic>?, String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<String> get senderDid =>
      $composableBuilder(column: $table.senderDid, builder: (column) => column);

  Expression<T> reactionsRefs<T extends Object>(
      Expression<T> Function($$ReactionsTableAnnotationComposer a) f) {
    final $$ReactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.reactions,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.reactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> attachmentsRefs<T extends Object>(
      Expression<T> Function($$AttachmentsTableAnnotationComposer a) f) {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.attachments,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttachmentsTableAnnotationComposer(
              $db: $db,
              $table: $db.attachments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ChatItemsTableTableManager extends RootTableManager<
    _$ChatItemsDatabase,
    $ChatItemsTable,
    ChatItem,
    $$ChatItemsTableFilterComposer,
    $$ChatItemsTableOrderingComposer,
    $$ChatItemsTableAnnotationComposer,
    $$ChatItemsTableCreateCompanionBuilder,
    $$ChatItemsTableUpdateCompanionBuilder,
    (ChatItem, $$ChatItemsTableReferences),
    ChatItem,
    PrefetchHooks Function({bool reactionsRefs, bool attachmentsRefs})> {
  $$ChatItemsTableTableManager(_$ChatItemsDatabase db, $ChatItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChatItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChatItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChatItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> chatId = const Value.absent(),
            Value<String> messageId = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<bool> isFromMe = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            Value<ChatItemStatus> status = const Value.absent(),
            Value<ChatItemType> type = const Value.absent(),
            Value<EventMessageType?> eventType = const Value.absent(),
            Value<ConciergeMessageType?> conciergeType = const Value.absent(),
            Value<Map<String, dynamic>?> data = const Value.absent(),
            Value<String> senderDid = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatItemsCompanion(
            chatId: chatId,
            messageId: messageId,
            value: value,
            isFromMe: isFromMe,
            dateCreated: dateCreated,
            status: status,
            type: type,
            eventType: eventType,
            conciergeType: conciergeType,
            data: data,
            senderDid: senderDid,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String chatId,
            required String messageId,
            Value<String?> value = const Value.absent(),
            Value<bool> isFromMe = const Value.absent(),
            Value<DateTime> dateCreated = const Value.absent(),
            required ChatItemStatus status,
            required ChatItemType type,
            Value<EventMessageType?> eventType = const Value.absent(),
            Value<ConciergeMessageType?> conciergeType = const Value.absent(),
            Value<Map<String, dynamic>?> data = const Value.absent(),
            required String senderDid,
            Value<int> rowid = const Value.absent(),
          }) =>
              ChatItemsCompanion.insert(
            chatId: chatId,
            messageId: messageId,
            value: value,
            isFromMe: isFromMe,
            dateCreated: dateCreated,
            status: status,
            type: type,
            eventType: eventType,
            conciergeType: conciergeType,
            data: data,
            senderDid: senderDid,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ChatItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {reactionsRefs = false, attachmentsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (reactionsRefs) db.reactions,
                if (attachmentsRefs) db.attachments
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (reactionsRefs)
                    await $_getPrefetchedData<ChatItem, $ChatItemsTable,
                            Reaction>(
                        currentTable: table,
                        referencedTable:
                            $$ChatItemsTableReferences._reactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChatItemsTableReferences(db, table, p0)
                                .reactionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.messageId == item.messageId),
                        typedResults: items),
                  if (attachmentsRefs)
                    await $_getPrefetchedData<ChatItem, $ChatItemsTable,
                            Attachment>(
                        currentTable: table,
                        referencedTable: $$ChatItemsTableReferences
                            ._attachmentsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ChatItemsTableReferences(db, table, p0)
                                .attachmentsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.messageId == item.messageId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ChatItemsTableProcessedTableManager = ProcessedTableManager<
    _$ChatItemsDatabase,
    $ChatItemsTable,
    ChatItem,
    $$ChatItemsTableFilterComposer,
    $$ChatItemsTableOrderingComposer,
    $$ChatItemsTableAnnotationComposer,
    $$ChatItemsTableCreateCompanionBuilder,
    $$ChatItemsTableUpdateCompanionBuilder,
    (ChatItem, $$ChatItemsTableReferences),
    ChatItem,
    PrefetchHooks Function({bool reactionsRefs, bool attachmentsRefs})>;
typedef $$ReactionsTableCreateCompanionBuilder = ReactionsCompanion Function({
  required String messageId,
  required String value,
  Value<int> rowid,
});
typedef $$ReactionsTableUpdateCompanionBuilder = ReactionsCompanion Function({
  Value<String> messageId,
  Value<String> value,
  Value<int> rowid,
});

final class $$ReactionsTableReferences
    extends BaseReferences<_$ChatItemsDatabase, $ReactionsTable, Reaction> {
  $$ReactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChatItemsTable _messageIdTable(_$ChatItemsDatabase db) =>
      db.chatItems.createAlias(
          $_aliasNameGenerator(db.reactions.messageId, db.chatItems.messageId));

  $$ChatItemsTableProcessedTableManager get messageId {
    final $_column = $_itemColumn<String>('message_id')!;

    final manager = $$ChatItemsTableTableManager($_db, $_db.chatItems)
        .filter((f) => f.messageId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReactionsTableFilterComposer
    extends Composer<_$ChatItemsDatabase, $ReactionsTable> {
  $$ReactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  $$ChatItemsTableFilterComposer get messageId {
    final $$ChatItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.chatItems,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatItemsTableFilterComposer(
              $db: $db,
              $table: $db.chatItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReactionsTableOrderingComposer
    extends Composer<_$ChatItemsDatabase, $ReactionsTable> {
  $$ReactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  $$ChatItemsTableOrderingComposer get messageId {
    final $$ChatItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.chatItems,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatItemsTableOrderingComposer(
              $db: $db,
              $table: $db.chatItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReactionsTableAnnotationComposer
    extends Composer<_$ChatItemsDatabase, $ReactionsTable> {
  $$ReactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$ChatItemsTableAnnotationComposer get messageId {
    final $$ChatItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.chatItems,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.chatItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReactionsTableTableManager extends RootTableManager<
    _$ChatItemsDatabase,
    $ReactionsTable,
    Reaction,
    $$ReactionsTableFilterComposer,
    $$ReactionsTableOrderingComposer,
    $$ReactionsTableAnnotationComposer,
    $$ReactionsTableCreateCompanionBuilder,
    $$ReactionsTableUpdateCompanionBuilder,
    (Reaction, $$ReactionsTableReferences),
    Reaction,
    PrefetchHooks Function({bool messageId})> {
  $$ReactionsTableTableManager(_$ChatItemsDatabase db, $ReactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> messageId = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReactionsCompanion(
            messageId: messageId,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String messageId,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReactionsCompanion.insert(
            messageId: messageId,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ReactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({messageId = false}) {
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
                if (messageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.messageId,
                    referencedTable:
                        $$ReactionsTableReferences._messageIdTable(db),
                    referencedColumn: $$ReactionsTableReferences
                        ._messageIdTable(db)
                        .messageId,
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

typedef $$ReactionsTableProcessedTableManager = ProcessedTableManager<
    _$ChatItemsDatabase,
    $ReactionsTable,
    Reaction,
    $$ReactionsTableFilterComposer,
    $$ReactionsTableOrderingComposer,
    $$ReactionsTableAnnotationComposer,
    $$ReactionsTableCreateCompanionBuilder,
    $$ReactionsTableUpdateCompanionBuilder,
    (Reaction, $$ReactionsTableReferences),
    Reaction,
    PrefetchHooks Function({bool messageId})>;
typedef $$AttachmentsTableCreateCompanionBuilder = AttachmentsCompanion
    Function({
  required String messageId,
  Value<int> attachmentId,
  Value<String?> id,
  Value<String?> description,
  Value<String?> filename,
  Value<String?> mediaType,
  Value<String?> format,
  Value<DateTime?> lastModifiedTime,
  Value<String?> jws,
  Value<int?> byteCount,
  Value<String?> hash,
  Value<String?> base64,
  Value<String?> json,
});
typedef $$AttachmentsTableUpdateCompanionBuilder = AttachmentsCompanion
    Function({
  Value<String> messageId,
  Value<int> attachmentId,
  Value<String?> id,
  Value<String?> description,
  Value<String?> filename,
  Value<String?> mediaType,
  Value<String?> format,
  Value<DateTime?> lastModifiedTime,
  Value<String?> jws,
  Value<int?> byteCount,
  Value<String?> hash,
  Value<String?> base64,
  Value<String?> json,
});

final class $$AttachmentsTableReferences
    extends BaseReferences<_$ChatItemsDatabase, $AttachmentsTable, Attachment> {
  $$AttachmentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ChatItemsTable _messageIdTable(_$ChatItemsDatabase db) =>
      db.chatItems.createAlias($_aliasNameGenerator(
          db.attachments.messageId, db.chatItems.messageId));

  $$ChatItemsTableProcessedTableManager get messageId {
    final $_column = $_itemColumn<String>('message_id')!;

    final manager = $$ChatItemsTableTableManager($_db, $_db.chatItems)
        .filter((f) => f.messageId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_messageIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$AttachmentsLinksTable, List<AttachmentLink>>
      _attachmentsLinksRefsTable(_$ChatItemsDatabase db) =>
          MultiTypedResultKey.fromTable(db.attachmentsLinks,
              aliasName: $_aliasNameGenerator(db.attachments.attachmentId,
                  db.attachmentsLinks.attachmentId));

  $$AttachmentsLinksTableProcessedTableManager get attachmentsLinksRefs {
    final manager =
        $$AttachmentsLinksTableTableManager($_db, $_db.attachmentsLinks).filter(
            (f) => f.attachmentId.attachmentId
                .sqlEquals($_itemColumn<int>('attachment_id')!));

    final cache =
        $_typedResult.readTableOrNull(_attachmentsLinksRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AttachmentsTableFilterComposer
    extends Composer<_$ChatItemsDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get attachmentId => $composableBuilder(
      column: $table.attachmentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastModifiedTime => $composableBuilder(
      column: $table.lastModifiedTime,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jws => $composableBuilder(
      column: $table.jws, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get byteCount => $composableBuilder(
      column: $table.byteCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get base64 => $composableBuilder(
      column: $table.base64, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnFilters(column));

  $$ChatItemsTableFilterComposer get messageId {
    final $$ChatItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.chatItems,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatItemsTableFilterComposer(
              $db: $db,
              $table: $db.chatItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> attachmentsLinksRefs(
      Expression<bool> Function($$AttachmentsLinksTableFilterComposer f) f) {
    final $$AttachmentsLinksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attachmentId,
        referencedTable: $db.attachmentsLinks,
        getReferencedColumn: (t) => t.attachmentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttachmentsLinksTableFilterComposer(
              $db: $db,
              $table: $db.attachmentsLinks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$ChatItemsDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get attachmentId => $composableBuilder(
      column: $table.attachmentId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filename => $composableBuilder(
      column: $table.filename, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastModifiedTime => $composableBuilder(
      column: $table.lastModifiedTime,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jws => $composableBuilder(
      column: $table.jws, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get byteCount => $composableBuilder(
      column: $table.byteCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get hash => $composableBuilder(
      column: $table.hash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get base64 => $composableBuilder(
      column: $table.base64, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json => $composableBuilder(
      column: $table.json, builder: (column) => ColumnOrderings(column));

  $$ChatItemsTableOrderingComposer get messageId {
    final $$ChatItemsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.chatItems,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatItemsTableOrderingComposer(
              $db: $db,
              $table: $db.chatItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$ChatItemsDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get attachmentId => $composableBuilder(
      column: $table.attachmentId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
      column: $table.description, builder: (column) => column);

  GeneratedColumn<String> get filename =>
      $composableBuilder(column: $table.filename, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<DateTime> get lastModifiedTime => $composableBuilder(
      column: $table.lastModifiedTime, builder: (column) => column);

  GeneratedColumn<String> get jws =>
      $composableBuilder(column: $table.jws, builder: (column) => column);

  GeneratedColumn<int> get byteCount =>
      $composableBuilder(column: $table.byteCount, builder: (column) => column);

  GeneratedColumn<String> get hash =>
      $composableBuilder(column: $table.hash, builder: (column) => column);

  GeneratedColumn<String> get base64 =>
      $composableBuilder(column: $table.base64, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  $$ChatItemsTableAnnotationComposer get messageId {
    final $$ChatItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.messageId,
        referencedTable: $db.chatItems,
        getReferencedColumn: (t) => t.messageId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ChatItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.chatItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> attachmentsLinksRefs<T extends Object>(
      Expression<T> Function($$AttachmentsLinksTableAnnotationComposer a) f) {
    final $$AttachmentsLinksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attachmentId,
        referencedTable: $db.attachmentsLinks,
        getReferencedColumn: (t) => t.attachmentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttachmentsLinksTableAnnotationComposer(
              $db: $db,
              $table: $db.attachmentsLinks,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AttachmentsTableTableManager extends RootTableManager<
    _$ChatItemsDatabase,
    $AttachmentsTable,
    Attachment,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableAnnotationComposer,
    $$AttachmentsTableCreateCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder,
    (Attachment, $$AttachmentsTableReferences),
    Attachment,
    PrefetchHooks Function({bool messageId, bool attachmentsLinksRefs})> {
  $$AttachmentsTableTableManager(
      _$ChatItemsDatabase db, $AttachmentsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> messageId = const Value.absent(),
            Value<int> attachmentId = const Value.absent(),
            Value<String?> id = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> filename = const Value.absent(),
            Value<String?> mediaType = const Value.absent(),
            Value<String?> format = const Value.absent(),
            Value<DateTime?> lastModifiedTime = const Value.absent(),
            Value<String?> jws = const Value.absent(),
            Value<int?> byteCount = const Value.absent(),
            Value<String?> hash = const Value.absent(),
            Value<String?> base64 = const Value.absent(),
            Value<String?> json = const Value.absent(),
          }) =>
              AttachmentsCompanion(
            messageId: messageId,
            attachmentId: attachmentId,
            id: id,
            description: description,
            filename: filename,
            mediaType: mediaType,
            format: format,
            lastModifiedTime: lastModifiedTime,
            jws: jws,
            byteCount: byteCount,
            hash: hash,
            base64: base64,
            json: json,
          ),
          createCompanionCallback: ({
            required String messageId,
            Value<int> attachmentId = const Value.absent(),
            Value<String?> id = const Value.absent(),
            Value<String?> description = const Value.absent(),
            Value<String?> filename = const Value.absent(),
            Value<String?> mediaType = const Value.absent(),
            Value<String?> format = const Value.absent(),
            Value<DateTime?> lastModifiedTime = const Value.absent(),
            Value<String?> jws = const Value.absent(),
            Value<int?> byteCount = const Value.absent(),
            Value<String?> hash = const Value.absent(),
            Value<String?> base64 = const Value.absent(),
            Value<String?> json = const Value.absent(),
          }) =>
              AttachmentsCompanion.insert(
            messageId: messageId,
            attachmentId: attachmentId,
            id: id,
            description: description,
            filename: filename,
            mediaType: mediaType,
            format: format,
            lastModifiedTime: lastModifiedTime,
            jws: jws,
            byteCount: byteCount,
            hash: hash,
            base64: base64,
            json: json,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AttachmentsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {messageId = false, attachmentsLinksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (attachmentsLinksRefs) db.attachmentsLinks
              ],
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
                if (messageId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.messageId,
                    referencedTable:
                        $$AttachmentsTableReferences._messageIdTable(db),
                    referencedColumn: $$AttachmentsTableReferences
                        ._messageIdTable(db)
                        .messageId,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (attachmentsLinksRefs)
                    await $_getPrefetchedData<Attachment, $AttachmentsTable,
                            AttachmentLink>(
                        currentTable: table,
                        referencedTable: $$AttachmentsTableReferences
                            ._attachmentsLinksRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AttachmentsTableReferences(db, table, p0)
                                .attachmentsLinksRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems.where(
                                (e) => e.attachmentId == item.attachmentId),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AttachmentsTableProcessedTableManager = ProcessedTableManager<
    _$ChatItemsDatabase,
    $AttachmentsTable,
    Attachment,
    $$AttachmentsTableFilterComposer,
    $$AttachmentsTableOrderingComposer,
    $$AttachmentsTableAnnotationComposer,
    $$AttachmentsTableCreateCompanionBuilder,
    $$AttachmentsTableUpdateCompanionBuilder,
    (Attachment, $$AttachmentsTableReferences),
    Attachment,
    PrefetchHooks Function({bool messageId, bool attachmentsLinksRefs})>;
typedef $$AttachmentsLinksTableCreateCompanionBuilder
    = AttachmentsLinksCompanion Function({
  required int attachmentId,
  required Uri url,
  Value<int> rowid,
});
typedef $$AttachmentsLinksTableUpdateCompanionBuilder
    = AttachmentsLinksCompanion Function({
  Value<int> attachmentId,
  Value<Uri> url,
  Value<int> rowid,
});

final class $$AttachmentsLinksTableReferences extends BaseReferences<
    _$ChatItemsDatabase, $AttachmentsLinksTable, AttachmentLink> {
  $$AttachmentsLinksTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AttachmentsTable _attachmentIdTable(_$ChatItemsDatabase db) =>
      db.attachments.createAlias($_aliasNameGenerator(
          db.attachmentsLinks.attachmentId, db.attachments.attachmentId));

  $$AttachmentsTableProcessedTableManager get attachmentId {
    final $_column = $_itemColumn<int>('attachment_id')!;

    final manager = $$AttachmentsTableTableManager($_db, $_db.attachments)
        .filter((f) => f.attachmentId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_attachmentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$AttachmentsLinksTableFilterComposer
    extends Composer<_$ChatItemsDatabase, $AttachmentsLinksTable> {
  $$AttachmentsLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uri, Uri, String> get url =>
      $composableBuilder(
          column: $table.url,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  $$AttachmentsTableFilterComposer get attachmentId {
    final $$AttachmentsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attachmentId,
        referencedTable: $db.attachments,
        getReferencedColumn: (t) => t.attachmentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttachmentsTableFilterComposer(
              $db: $db,
              $table: $db.attachments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttachmentsLinksTableOrderingComposer
    extends Composer<_$ChatItemsDatabase, $AttachmentsLinksTable> {
  $$AttachmentsLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get url => $composableBuilder(
      column: $table.url, builder: (column) => ColumnOrderings(column));

  $$AttachmentsTableOrderingComposer get attachmentId {
    final $$AttachmentsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attachmentId,
        referencedTable: $db.attachments,
        getReferencedColumn: (t) => t.attachmentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttachmentsTableOrderingComposer(
              $db: $db,
              $table: $db.attachments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttachmentsLinksTableAnnotationComposer
    extends Composer<_$ChatItemsDatabase, $AttachmentsLinksTable> {
  $$AttachmentsLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uri, String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  $$AttachmentsTableAnnotationComposer get attachmentId {
    final $$AttachmentsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.attachmentId,
        referencedTable: $db.attachments,
        getReferencedColumn: (t) => t.attachmentId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$AttachmentsTableAnnotationComposer(
              $db: $db,
              $table: $db.attachments,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AttachmentsLinksTableTableManager extends RootTableManager<
    _$ChatItemsDatabase,
    $AttachmentsLinksTable,
    AttachmentLink,
    $$AttachmentsLinksTableFilterComposer,
    $$AttachmentsLinksTableOrderingComposer,
    $$AttachmentsLinksTableAnnotationComposer,
    $$AttachmentsLinksTableCreateCompanionBuilder,
    $$AttachmentsLinksTableUpdateCompanionBuilder,
    (AttachmentLink, $$AttachmentsLinksTableReferences),
    AttachmentLink,
    PrefetchHooks Function({bool attachmentId})> {
  $$AttachmentsLinksTableTableManager(
      _$ChatItemsDatabase db, $AttachmentsLinksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> attachmentId = const Value.absent(),
            Value<Uri> url = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsLinksCompanion(
            attachmentId: attachmentId,
            url: url,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int attachmentId,
            required Uri url,
            Value<int> rowid = const Value.absent(),
          }) =>
              AttachmentsLinksCompanion.insert(
            attachmentId: attachmentId,
            url: url,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AttachmentsLinksTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({attachmentId = false}) {
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
                if (attachmentId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.attachmentId,
                    referencedTable: $$AttachmentsLinksTableReferences
                        ._attachmentIdTable(db),
                    referencedColumn: $$AttachmentsLinksTableReferences
                        ._attachmentIdTable(db)
                        .attachmentId,
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

typedef $$AttachmentsLinksTableProcessedTableManager = ProcessedTableManager<
    _$ChatItemsDatabase,
    $AttachmentsLinksTable,
    AttachmentLink,
    $$AttachmentsLinksTableFilterComposer,
    $$AttachmentsLinksTableOrderingComposer,
    $$AttachmentsLinksTableAnnotationComposer,
    $$AttachmentsLinksTableCreateCompanionBuilder,
    $$AttachmentsLinksTableUpdateCompanionBuilder,
    (AttachmentLink, $$AttachmentsLinksTableReferences),
    AttachmentLink,
    PrefetchHooks Function({bool attachmentId})>;

class $ChatItemsDatabaseManager {
  final _$ChatItemsDatabase _db;
  $ChatItemsDatabaseManager(this._db);
  $$ChatItemsTableTableManager get chatItems =>
      $$ChatItemsTableTableManager(_db, _db.chatItems);
  $$ReactionsTableTableManager get reactions =>
      $$ReactionsTableTableManager(_db, _db.reactions);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$AttachmentsLinksTableTableManager get attachmentsLinks =>
      $$AttachmentsLinksTableTableManager(_db, _db.attachmentsLinks);
}

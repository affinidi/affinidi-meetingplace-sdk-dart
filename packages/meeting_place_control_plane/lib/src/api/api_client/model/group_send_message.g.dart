// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_send_message.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupSendMessage extends GroupSendMessage {
  @override
  final String offerLink;
  @override
  final String fromDid;
  @override
  final String groupDid;
  @override
  final String payload;
  @override
  final bool? ephemeral;
  @override
  final String? expiresTime;
  @override
  final bool? notify;
  @override
  final bool? incSeqNo;

  factory _$GroupSendMessage([
    void Function(GroupSendMessageBuilder)? updates,
  ]) => (GroupSendMessageBuilder()..update(updates))._build();

  _$GroupSendMessage._({
    required this.offerLink,
    required this.fromDid,
    required this.groupDid,
    required this.payload,
    this.ephemeral,
    this.expiresTime,
    this.notify,
    this.incSeqNo,
  }) : super._();
  @override
  GroupSendMessage rebuild(void Function(GroupSendMessageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GroupSendMessageBuilder toBuilder() =>
      GroupSendMessageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupSendMessage &&
        offerLink == other.offerLink &&
        fromDid == other.fromDid &&
        groupDid == other.groupDid &&
        payload == other.payload &&
        ephemeral == other.ephemeral &&
        expiresTime == other.expiresTime &&
        notify == other.notify &&
        incSeqNo == other.incSeqNo;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, offerLink.hashCode);
    _$hash = $jc(_$hash, fromDid.hashCode);
    _$hash = $jc(_$hash, groupDid.hashCode);
    _$hash = $jc(_$hash, payload.hashCode);
    _$hash = $jc(_$hash, ephemeral.hashCode);
    _$hash = $jc(_$hash, expiresTime.hashCode);
    _$hash = $jc(_$hash, notify.hashCode);
    _$hash = $jc(_$hash, incSeqNo.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GroupSendMessage')
          ..add('offerLink', offerLink)
          ..add('fromDid', fromDid)
          ..add('groupDid', groupDid)
          ..add('payload', payload)
          ..add('ephemeral', ephemeral)
          ..add('expiresTime', expiresTime)
          ..add('notify', notify)
          ..add('incSeqNo', incSeqNo))
        .toString();
  }
}

class GroupSendMessageBuilder
    implements Builder<GroupSendMessage, GroupSendMessageBuilder> {
  _$GroupSendMessage? _$v;

  String? _offerLink;
  String? get offerLink => _$this._offerLink;
  set offerLink(String? offerLink) => _$this._offerLink = offerLink;

  String? _fromDid;
  String? get fromDid => _$this._fromDid;
  set fromDid(String? fromDid) => _$this._fromDid = fromDid;

  String? _groupDid;
  String? get groupDid => _$this._groupDid;
  set groupDid(String? groupDid) => _$this._groupDid = groupDid;

  String? _payload;
  String? get payload => _$this._payload;
  set payload(String? payload) => _$this._payload = payload;

  bool? _ephemeral;
  bool? get ephemeral => _$this._ephemeral;
  set ephemeral(bool? ephemeral) => _$this._ephemeral = ephemeral;

  String? _expiresTime;
  String? get expiresTime => _$this._expiresTime;
  set expiresTime(String? expiresTime) => _$this._expiresTime = expiresTime;

  bool? _notify;
  bool? get notify => _$this._notify;
  set notify(bool? notify) => _$this._notify = notify;

  bool? _incSeqNo;
  bool? get incSeqNo => _$this._incSeqNo;
  set incSeqNo(bool? incSeqNo) => _$this._incSeqNo = incSeqNo;

  GroupSendMessageBuilder() {
    GroupSendMessage._defaults(this);
  }

  GroupSendMessageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _offerLink = $v.offerLink;
      _fromDid = $v.fromDid;
      _groupDid = $v.groupDid;
      _payload = $v.payload;
      _ephemeral = $v.ephemeral;
      _expiresTime = $v.expiresTime;
      _notify = $v.notify;
      _incSeqNo = $v.incSeqNo;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupSendMessage other) {
    _$v = other as _$GroupSendMessage;
  }

  @override
  void update(void Function(GroupSendMessageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupSendMessage build() => _build();

  _$GroupSendMessage _build() {
    final _$result =
        _$v ??
        _$GroupSendMessage._(
          offerLink: BuiltValueNullFieldError.checkNotNull(
            offerLink,
            r'GroupSendMessage',
            'offerLink',
          ),
          fromDid: BuiltValueNullFieldError.checkNotNull(
            fromDid,
            r'GroupSendMessage',
            'fromDid',
          ),
          groupDid: BuiltValueNullFieldError.checkNotNull(
            groupDid,
            r'GroupSendMessage',
            'groupDid',
          ),
          payload: BuiltValueNullFieldError.checkNotNull(
            payload,
            r'GroupSendMessage',
            'payload',
          ),
          ephemeral: ephemeral,
          expiresTime: expiresTime,
          notify: notify,
          incSeqNo: incSeqNo,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

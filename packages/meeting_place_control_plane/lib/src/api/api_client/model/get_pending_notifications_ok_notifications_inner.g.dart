// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'get_pending_notifications_ok_notifications_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GetPendingNotificationsOKNotificationsInner
    extends GetPendingNotificationsOKNotificationsInner {
  @override
  final String? id;
  @override
  final String? type;
  @override
  final String? payload;
  @override
  final String? notificationDate;

  factory _$GetPendingNotificationsOKNotificationsInner(
          [void Function(GetPendingNotificationsOKNotificationsInnerBuilder)?
              updates]) =>
      (GetPendingNotificationsOKNotificationsInnerBuilder()..update(updates))
          ._build();

  _$GetPendingNotificationsOKNotificationsInner._(
      {this.id, this.type, this.payload, this.notificationDate})
      : super._();
  @override
  GetPendingNotificationsOKNotificationsInner rebuild(
          void Function(GetPendingNotificationsOKNotificationsInnerBuilder)
              updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GetPendingNotificationsOKNotificationsInnerBuilder toBuilder() =>
      GetPendingNotificationsOKNotificationsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GetPendingNotificationsOKNotificationsInner &&
        id == other.id &&
        type == other.type &&
        payload == other.payload &&
        notificationDate == other.notificationDate;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jc(_$hash, payload.hashCode);
    _$hash = $jc(_$hash, notificationDate.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'GetPendingNotificationsOKNotificationsInner')
          ..add('id', id)
          ..add('type', type)
          ..add('payload', payload)
          ..add('notificationDate', notificationDate))
        .toString();
  }
}

class GetPendingNotificationsOKNotificationsInnerBuilder
    implements
        Builder<GetPendingNotificationsOKNotificationsInner,
            GetPendingNotificationsOKNotificationsInnerBuilder> {
  _$GetPendingNotificationsOKNotificationsInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  String? _payload;
  String? get payload => _$this._payload;
  set payload(String? payload) => _$this._payload = payload;

  String? _notificationDate;
  String? get notificationDate => _$this._notificationDate;
  set notificationDate(String? notificationDate) =>
      _$this._notificationDate = notificationDate;

  GetPendingNotificationsOKNotificationsInnerBuilder() {
    GetPendingNotificationsOKNotificationsInner._defaults(this);
  }

  GetPendingNotificationsOKNotificationsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _type = $v.type;
      _payload = $v.payload;
      _notificationDate = $v.notificationDate;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GetPendingNotificationsOKNotificationsInner other) {
    _$v = other as _$GetPendingNotificationsOKNotificationsInner;
  }

  @override
  void update(
      void Function(GetPendingNotificationsOKNotificationsInnerBuilder)?
          updates) {
    if (updates != null) updates(this);
  }

  @override
  GetPendingNotificationsOKNotificationsInner build() => _build();

  _$GetPendingNotificationsOKNotificationsInner _build() {
    final _$result = _$v ??
        _$GetPendingNotificationsOKNotificationsInner._(
          id: id,
          type: type,
          payload: payload,
          notificationDate: notificationDate,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

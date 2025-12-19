// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_pending_notifications_ok_notifications_inner.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeletePendingNotificationsOKNotificationsInner
    extends DeletePendingNotificationsOKNotificationsInner {
  @override
  final String? id;
  @override
  final String? offerLink;
  @override
  final String? deviceHash;
  @override
  final String? did;
  @override
  final String? payload;

  factory _$DeletePendingNotificationsOKNotificationsInner([
    void Function(DeletePendingNotificationsOKNotificationsInnerBuilder)?
    updates,
  ]) =>
      (DeletePendingNotificationsOKNotificationsInnerBuilder()..update(updates))
          ._build();

  _$DeletePendingNotificationsOKNotificationsInner._({
    this.id,
    this.offerLink,
    this.deviceHash,
    this.did,
    this.payload,
  }) : super._();
  @override
  DeletePendingNotificationsOKNotificationsInner rebuild(
    void Function(DeletePendingNotificationsOKNotificationsInnerBuilder)
    updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DeletePendingNotificationsOKNotificationsInnerBuilder toBuilder() =>
      DeletePendingNotificationsOKNotificationsInnerBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeletePendingNotificationsOKNotificationsInner &&
        id == other.id &&
        offerLink == other.offerLink &&
        deviceHash == other.deviceHash &&
        did == other.did &&
        payload == other.payload;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, offerLink.hashCode);
    _$hash = $jc(_$hash, deviceHash.hashCode);
    _$hash = $jc(_$hash, did.hashCode);
    _$hash = $jc(_$hash, payload.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
            r'DeletePendingNotificationsOKNotificationsInner',
          )
          ..add('id', id)
          ..add('offerLink', offerLink)
          ..add('deviceHash', deviceHash)
          ..add('did', did)
          ..add('payload', payload))
        .toString();
  }
}

class DeletePendingNotificationsOKNotificationsInnerBuilder
    implements
        Builder<
          DeletePendingNotificationsOKNotificationsInner,
          DeletePendingNotificationsOKNotificationsInnerBuilder
        > {
  _$DeletePendingNotificationsOKNotificationsInner? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _offerLink;
  String? get offerLink => _$this._offerLink;
  set offerLink(String? offerLink) => _$this._offerLink = offerLink;

  String? _deviceHash;
  String? get deviceHash => _$this._deviceHash;
  set deviceHash(String? deviceHash) => _$this._deviceHash = deviceHash;

  String? _did;
  String? get did => _$this._did;
  set did(String? did) => _$this._did = did;

  String? _payload;
  String? get payload => _$this._payload;
  set payload(String? payload) => _$this._payload = payload;

  DeletePendingNotificationsOKNotificationsInnerBuilder() {
    DeletePendingNotificationsOKNotificationsInner._defaults(this);
  }

  DeletePendingNotificationsOKNotificationsInnerBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _offerLink = $v.offerLink;
      _deviceHash = $v.deviceHash;
      _did = $v.did;
      _payload = $v.payload;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeletePendingNotificationsOKNotificationsInner other) {
    _$v = other as _$DeletePendingNotificationsOKNotificationsInner;
  }

  @override
  void update(
    void Function(DeletePendingNotificationsOKNotificationsInnerBuilder)?
    updates,
  ) {
    if (updates != null) updates(this);
  }

  @override
  DeletePendingNotificationsOKNotificationsInner build() => _build();

  _$DeletePendingNotificationsOKNotificationsInner _build() {
    final _$result =
        _$v ??
        _$DeletePendingNotificationsOKNotificationsInner._(
          id: id,
          offerLink: offerLink,
          deviceHash: deviceHash,
          did: did,
          payload: payload,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

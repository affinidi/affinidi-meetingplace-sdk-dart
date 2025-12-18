// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delete_pending_notifications_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeletePendingNotificationsOK extends DeletePendingNotificationsOK {
  @override
  final BuiltList<String>? deletedIds;
  @override
  final BuiltList<DeletePendingNotificationsOKNotificationsInner>?
  notifications;
  @override
  final JsonObject? examples;

  factory _$DeletePendingNotificationsOK([
    void Function(DeletePendingNotificationsOKBuilder)? updates,
  ]) => (DeletePendingNotificationsOKBuilder()..update(updates))._build();

  _$DeletePendingNotificationsOK._({
    this.deletedIds,
    this.notifications,
    this.examples,
  }) : super._();
  @override
  DeletePendingNotificationsOK rebuild(
    void Function(DeletePendingNotificationsOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  DeletePendingNotificationsOKBuilder toBuilder() =>
      DeletePendingNotificationsOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeletePendingNotificationsOK &&
        deletedIds == other.deletedIds &&
        notifications == other.notifications &&
        examples == other.examples;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, deletedIds.hashCode);
    _$hash = $jc(_$hash, notifications.hashCode);
    _$hash = $jc(_$hash, examples.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeletePendingNotificationsOK')
          ..add('deletedIds', deletedIds)
          ..add('notifications', notifications)
          ..add('examples', examples))
        .toString();
  }
}

class DeletePendingNotificationsOKBuilder
    implements
        Builder<
          DeletePendingNotificationsOK,
          DeletePendingNotificationsOKBuilder
        > {
  _$DeletePendingNotificationsOK? _$v;

  ListBuilder<String>? _deletedIds;
  ListBuilder<String> get deletedIds =>
      _$this._deletedIds ??= ListBuilder<String>();
  set deletedIds(ListBuilder<String>? deletedIds) =>
      _$this._deletedIds = deletedIds;

  ListBuilder<DeletePendingNotificationsOKNotificationsInner>? _notifications;
  ListBuilder<DeletePendingNotificationsOKNotificationsInner>
  get notifications => _$this._notifications ??=
      ListBuilder<DeletePendingNotificationsOKNotificationsInner>();
  set notifications(
    ListBuilder<DeletePendingNotificationsOKNotificationsInner>? notifications,
  ) => _$this._notifications = notifications;

  JsonObject? _examples;
  JsonObject? get examples => _$this._examples;
  set examples(JsonObject? examples) => _$this._examples = examples;

  DeletePendingNotificationsOKBuilder() {
    DeletePendingNotificationsOK._defaults(this);
  }

  DeletePendingNotificationsOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _deletedIds = $v.deletedIds?.toBuilder();
      _notifications = $v.notifications?.toBuilder();
      _examples = $v.examples;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeletePendingNotificationsOK other) {
    _$v = other as _$DeletePendingNotificationsOK;
  }

  @override
  void update(void Function(DeletePendingNotificationsOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeletePendingNotificationsOK build() => _build();

  _$DeletePendingNotificationsOK _build() {
    _$DeletePendingNotificationsOK _$result;
    try {
      _$result =
          _$v ??
          _$DeletePendingNotificationsOK._(
            deletedIds: _deletedIds?.build(),
            notifications: _notifications?.build(),
            examples: examples,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'deletedIds';
        _deletedIds?.build();
        _$failedField = 'notifications';
        _notifications?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'DeletePendingNotificationsOK',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

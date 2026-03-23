// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notify_channel_group_ok.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$NotifyChannelGroupOK extends NotifyChannelGroupOK {
  @override
  final int notifiedCount;

  factory _$NotifyChannelGroupOK([
    void Function(NotifyChannelGroupOKBuilder)? updates,
  ]) => (NotifyChannelGroupOKBuilder()..update(updates))._build();

  _$NotifyChannelGroupOK._({required this.notifiedCount}) : super._();
  @override
  NotifyChannelGroupOK rebuild(
    void Function(NotifyChannelGroupOKBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  NotifyChannelGroupOKBuilder toBuilder() =>
      NotifyChannelGroupOKBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is NotifyChannelGroupOK &&
        notifiedCount == other.notifiedCount;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, notifiedCount.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(
      r'NotifyChannelGroupOK',
    )..add('notifiedCount', notifiedCount)).toString();
  }
}

class NotifyChannelGroupOKBuilder
    implements Builder<NotifyChannelGroupOK, NotifyChannelGroupOKBuilder> {
  _$NotifyChannelGroupOK? _$v;

  int? _notifiedCount;
  int? get notifiedCount => _$this._notifiedCount;
  set notifiedCount(int? notifiedCount) =>
      _$this._notifiedCount = notifiedCount;

  NotifyChannelGroupOKBuilder() {
    NotifyChannelGroupOK._defaults(this);
  }

  NotifyChannelGroupOKBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _notifiedCount = $v.notifiedCount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(NotifyChannelGroupOK other) {
    _$v = other as _$NotifyChannelGroupOK;
  }

  @override
  void update(void Function(NotifyChannelGroupOKBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  NotifyChannelGroupOK build() => _build();

  _$NotifyChannelGroupOK _build() {
    final _$result =
        _$v ??
        _$NotifyChannelGroupOK._(
          notifiedCount: BuiltValueNullFieldError.checkNotNull(
            notifiedCount,
            r'NotifyChannelGroupOK',
            'notifiedCount',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint

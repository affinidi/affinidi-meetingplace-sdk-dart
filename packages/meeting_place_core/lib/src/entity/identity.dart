import 'package:freezed_annotation/freezed_annotation.dart';
import 'contact_card.dart';

part 'identity.freezed.dart';

@freezed
abstract class Identity with _$Identity {
  const factory Identity({
    required String id,
    required String did,
    required ContactCard card,
    @Default(false) bool isPrimary,
  }) = _Identity;
}

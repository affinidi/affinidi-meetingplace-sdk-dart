import 'dart:math';

class SDKFixture {
  static String generateRandomDeviceToken({
    int groupCount = 8,
    int groupLength = 8,
  }) {
    const chars = '0123456789abcdefghijklmnopqrstuvwxyz';
    final rand = Random.secure();

    final groups = List.generate(groupCount, (_) {
      return List.generate(
        groupLength,
        (_) => chars[rand.nextInt(chars.length)],
      ).join();
    });

    return groups.join(' ');
  }
}

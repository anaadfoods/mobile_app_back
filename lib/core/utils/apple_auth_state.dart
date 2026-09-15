import 'dart:math';

class AppleAuthState {
  static String build(String platform) {
    final nonce = _randomString(16);
    return '${platform}__$nonce';
  }

  static String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    return List.generate(
      length,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
  }
}

import 'package:flutter/foundation.dart';

@Deprecated('Use GoRouter for deep linking. This service is no longer used.')
class DeepLinkService {
  Future<void> initialize() async {
    debugPrint('DeepLinkService is deprecated and should not be used.');
  }
}

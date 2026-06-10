import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:grocery_app/service_locator.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() => getIt<ConnectivityService>();

  ConnectivityService._internal();
  static ConnectivityService create() => ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  // Stream of connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  // Check current connection status
  Future<bool> get hasConnection async {
    final result = await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  bool _isConnected(List<ConnectivityResult> result) {
    return !result.contains(ConnectivityResult.none);
  }
}

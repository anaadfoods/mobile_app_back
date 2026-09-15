import 'package:flutter/material.dart';
import 'package:grocery_app/services/connectivity_service.dart';
import 'package:grocery_app/common_widgets/no_internet_widget.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;

  const ConnectivityWrapper({super.key, required this.child});

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _hasConnection = true;

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final hasConnection = await _connectivityService.hasConnection;
    if (mounted) {
      setState(() {
        _hasConnection = hasConnection;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: _connectivityService.onConnectivityChanged,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final result = snapshot.data!;
          // result is a list in newer versions
          final isConnected = !result.contains(ConnectivityResult.none);
          if (_hasConnection != isConnected) {
            // Avoid unnecessary rebuilds if possible, or just use variable
            // But setState inside builder is bad.
            // Actually, StreamBuilder handles rebuilding.
            _hasConnection = isConnected;
          }
          if (!isConnected) {
            return Scaffold(
              body: NoInternetWidget(
                onRetry: () async {
                  final hasConn = await _connectivityService.hasConnection;
                  if (hasConn && mounted) {
                    setState(() {
                      _hasConnection = true;
                    });
                  }
                },
              ),
            );
          }
        }

        // If snapshot has no data yet, rely on initial check or default true
        // If _hasConnection is false (from initial check), show error.
        if (!_hasConnection) {
          return Scaffold(
            body: NoInternetWidget(onRetry: _checkInitialConnection),
          );
        }

        return widget.child;
      },
    );
  }
}

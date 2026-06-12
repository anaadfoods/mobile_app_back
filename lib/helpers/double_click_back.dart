import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';

class DoubleBackToExitApp extends StatefulWidget {
  const DoubleBackToExitApp({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  _DoubleBackToExitAppState createState() => _DoubleBackToExitAppState();
}

class _DoubleBackToExitAppState extends State<DoubleBackToExitApp> {
  DateTime? _lastTimeBackButtonWasTapped;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        final hasRecentPress = _lastTimeBackButtonWasTapped != null &&
            now.difference(_lastTimeBackButtonWasTapped!) < const Duration(seconds: 2);

        if (hasRecentPress) {
          SystemNavigator.pop(); // Graceful programmatic exit
        } else {
          _lastTimeBackButtonWasTapped = now;
          SnackBarHelper.showInfo(context, 'Press back again to exit');
        }
      },
      child: widget.child,
    );
  }
}

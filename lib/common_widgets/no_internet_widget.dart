import 'package:flutter/material.dart';

class NoInternetWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetWidget({Key? key, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Friendly wifi icon with warm color
            Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: const Color(0xFF6B7B8A), // Cool slate grey - friendly
            ),
            const SizedBox(height: 24),
            Text(
              "Oops! You're Offline 📶",
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B7B8A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Your internet took a coffee break ☕\nCheck your connection and try again.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "🐄 A single desi cow can support an entire family's farming needs sustainably!",
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:grocery_app/common_widgets/global_import.dart';

class FavoriteErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const FavoriteErrorState({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isLoginError = errorMessage.toLowerCase().contains('login') ||
        errorMessage.toLowerCase().contains('unauthorized');

    if (isLoginError) {
      return const GuestEmptyStateWidget(
        title: 'Login to View Favorites',
        subtitle: 'Log in to see and manage your saved items.',
        icon: Icons.favorite_border_rounded,
      );
    }

    return ErrorStateWidget(
      title: 'Failed to Load Favorites',
      subtitle: errorMessage,
      errorType: ErrorType.server,
      onRetry: onRetry,
    );
  }
}

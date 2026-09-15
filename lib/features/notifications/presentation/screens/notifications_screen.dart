import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/common_widgets/empty_state_widget.dart';
import 'package:grocery_app/common_widgets/loading_state_widget.dart';
import 'package:grocery_app/helpers/snackbar_helper.dart';
import 'package:grocery_app/styles/colors.dart';
import 'package:grocery_app/features/notifications/domain/entities/notification_entity.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/routes/app_routes.dart';
import 'package:grocery_app/services/notification_service.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationCubit>().loadNotifications();
        context.read<NotificationCubit>().resetNotificationBadgeCount();
        context.read<NotificationCubit>().syncNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoute.home.path);
            }
          },
        ),
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            buildWhen: (previous, current) =>
                previous.notifications.length != current.notifications.length,
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear all notifications',
              onPressed: state.notifications.isEmpty
                  ? null
                  : () => _confirmClearAll(context),
            ),
          ),
        ],
      ),
      body: BlocConsumer<NotificationCubit, NotificationState>(
        listener: (context, state) {
          if (state is NotificationError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading && state.notifications.isEmpty) {
            return const LoadingStateWidget(itemCount: 5, itemHeight: 88);
          }

          if (state.notifications.isEmpty) {
            return EmptyStatePresets.notifications(
              onRefresh: () => context
                  .read<NotificationCubit>()
                  .syncNotifications(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await context.read<NotificationCubit>().syncNotifications();
            },
            child: ListView.separated(
              itemCount: state.notifications.length,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = state.notifications[index];
                return _NotificationTile(
                  notification: item,
                  isDark: isDark,
                  onDismiss: () {
                    context.read<NotificationCubit>().dismiss([item.id]);
                  },
                  onTap: () {
                    if (!item.isRead) {
                      context.read<NotificationCubit>().markAsRead([item.id]);
                    }
                    final target = item.metadata['deep_link'] ??
                        item.metadata['screen'] ??
                        item.metadata['target'] ??
                        item.action;
                    final targetStr = target?.toString().toLowerCase().trim();
                    final typeStr = item.type.toLowerCase().trim();
                    // If notification doesn't target another screen, avoid redundant navigation
                    final isSelfNotification = (targetStr == null ||
                            targetStr.isEmpty ||
                            targetStr == 'notifications' ||
                            targetStr == 'notification') &&
                        (typeStr == 'notifications' ||
                            typeStr == 'notification' ||
                            typeStr == 'general' ||
                            typeStr == 'system' ||
                            typeStr == 'promotional');
                    if (isSelfNotification) {
                      return;
                    }
                    final payload = <String, dynamic>{
                      'id': item.id,
                      'type': item.type,
                      'action': item.action,
                      'deep_link': target,
                      'screen': item.metadata['screen'],
                      ...item.metadata,
                    };
                    NotificationService().handleRedirection(payload);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This removes all notifications from this device. New updates will still arrive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (shouldClear == true && context.mounted) {
      context.read<NotificationCubit>().clearAllNotifications();
    }
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final bool isDark;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.isDark,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: Semantics(
        button: !notification.isRead,
        label: notification.isRead
            ? notification.title
            : '${notification.title}, unread. Double tap to mark as read.',
        child: Material(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: notification.isRead
                      ? Colors.transparent
                      : AppColors.deepSoilGreen.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.deepSoilGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

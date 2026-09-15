import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import '../../domain/entities/token_quota_info.dart';

class ChatHeaderWidget extends StatelessWidget {
  final String title;
  final bool isGenerating;
  final String? stageLabel;
  final TokenQuotaInfo? quotaInfo;
  final String? activeSessionId;
  final VoidCallback onBack;
  final VoidCallback onOpenDrawer;
  final VoidCallback onNewChat;
  final VoidCallback onHealthProfile;
  final VoidCallback? onDeleteSession;

  const ChatHeaderWidget({
    super.key,
    required this.title,
    required this.isGenerating,
    this.stageLabel,
    this.quotaInfo,
    this.activeSessionId,
    required this.onBack,
    required this.onOpenDrawer,
    required this.onNewChat,
    required this.onHealthProfile,
    this.onDeleteSession,
  });

  Widget _buildModernIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
    String? tooltip,
  }) {
    final button = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.2 * value),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Transform.rotate(
            angle: math.sin(value * math.pi * 2) * 0.08,
            child: Icon(icon, color: theme.colorScheme.onPrimary, size: 20),
          ),
        );
      },
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: tooltip != null
          ? Tooltip(message: tooltip, child: button)
          : button,
    );
  }

  Widget _buildGroupedActionButtons({
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // New Chat Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onNewChat();
            },
            child: Tooltip(
              message: 'New Chat',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Icon(
                  Icons.add_comment_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 19,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 18,
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.25),
          ),
          // History Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onOpenDrawer();
            },
            child: Tooltip(
              message: 'Chat History',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Icon(
                  Icons.history_rounded,
                  color: theme.colorScheme.onPrimary,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.deepSoilGreen, Color(0xFF3D6B28)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: 16,
          ),
          child: Row(
            children: [
              // Back Button
              _buildModernIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: onBack,
                theme: theme,
                tooltip: 'Back',
              ),
              const SizedBox(width: 8),

              // Grouped New Chat & History on Left Side
              _buildGroupedActionButtons(theme: theme),
              const SizedBox(width: 12),

              // Title and Subtitle Status (Expanded)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                        fontSize: 15.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (isGenerating)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.harvestAmber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              stageLabel ?? 'Thinking...',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.harvestAmber,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Ayurvedic AI Guide',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Trailing Action Buttons (Quota & Health Profile & Delete)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quota Badge
                  if (quotaInfo != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (quotaInfo!.tokensRemaining > 0
                                ? AppColors.harvestAmber
                                : AppColors.softRed)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (quotaInfo!.tokensRemaining > 0
                                  ? AppColors.harvestAmber
                                  : AppColors.softRed)
                              .withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            size: 13,
                            color: quotaInfo!.tokensRemaining > 0
                                ? AppColors.harvestAmber
                                : AppColors.softRed,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "${quotaInfo!.tokensRemaining}/${quotaInfo!.dailyLimit}",
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: quotaInfo!.tokensRemaining > 0
                                  ? AppColors.harvestAmber
                                  : AppColors.softRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],

                  // Health Profile Shield
                  _buildModernIconButton(
                    icon: Icons.shield_outlined,
                    onTap: onHealthProfile,
                    theme: theme,
                    tooltip: 'Health Profile & Privacy',
                  ),

                  // Delete Session if active
                  if (activeSessionId != null && onDeleteSession != null) ...[
                    const SizedBox(width: 6),
                    _buildModernIconButton(
                      icon: Icons.delete_outline_rounded,
                      onTap: onDeleteSession!,
                      theme: theme,
                      tooltip: 'Delete Chat Session',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

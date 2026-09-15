import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

import '../../../domain/entities/health_observation.dart';
import '../../cubit/chat_cubit.dart';
import '../../cubit/chat_state.dart';
import '../warning_signs_bottom_sheet.dart';

/// Renders a non-alarming health observation consent card.
class HealthObservationCardWidget extends StatelessWidget {
  final HealthObservation observation;
  final bool isSaved;
  final int messageIndex;

  const HealthObservationCardWidget({
    Key? key,
    required this.observation,
    required this.isSaved,
    required this.messageIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final isSaving = state.isSavingObservation;

        return Container(
          margin: const EdgeInsets.only(top: 10.0, bottom: 4.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceElevated : AppColors.parchment,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isDark
                      ? AppColors.harvestAmber.withValues(alpha: 0.5)
                      : AppColors.deepSoilGreen.withValues(alpha: 0.3),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.monitor_heart_outlined,
                    color:
                        isDark
                            ? AppColors.darkSoftGold
                            : AppColors.deepSoilGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Health observation",
                      style: TextStyle(
                        color:
                            isDark
                                ? AppColors.darkSoftGold
                                : AppColors.deepSoilGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    label: Text(observation.food),
                    backgroundColor:
                        isDark ? AppColors.darkSurface : Colors.white,
                    side: BorderSide(
                      color: AppColors.harvestAmber.withValues(alpha: 0.5),
                    ),
                  ),
                  Chip(
                    label: Text(observation.symptom),
                    backgroundColor:
                        isDark ? AppColors.darkSurface : Colors.white,
                    side: BorderSide(
                      color: AppColors.harvestAmber.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.harvestAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.harvestAmber.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 14,
                      color: AppColors.harvestAmber,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "User-reported, not medically confirmed",
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : AppColors.charcoal54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You reported ${observation.symptom} after eating ${observation.food}. This does not confirm that ${observation.food} caused the ${observation.symptom}.",
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.charcoal,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              if (observation.message.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.darkSurface
                            : Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    observation.message,
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white70 : AppColors.charcoal54,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                "What to do now:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 8),
              _buildActionItem(
                Icons.thermostat_outlined,
                "Check temperature",
                isDark,
              ),
              _buildActionItem(
                Icons.access_time_outlined,
                "Note when symptoms began",
                isDark,
              ),
              _buildActionItem(
                Icons.visibility_outlined,
                "Watch for worsening symptoms",
                isDark,
              ),
              const SizedBox(height: 16),

              if (isSaved)
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color:
                          isDark
                              ? AppColors.darkSuccessGreen
                              : AppColors.deepSoilGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Observation saved as user-reported and unconfirmed",
                        style: TextStyle(
                          color:
                              isDark
                                  ? AppColors.darkSuccessGreen
                                  : AppColors.deepSoilGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.harvestAmber,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed:
                          isSaving
                              ? null
                              : () {
                                final cubit = context.read<ChatCubit>();
                                final messages = cubit.state.messages;
                                String originalMsg = '';
                                for (int i = messageIndex - 1; i >= 0; i--) {
                                  if (messages[i].isUser) {
                                    originalMsg = messages[i].content;
                                    break;
                                  }
                                }
                                cubit.saveHealthObservation(
                                  originalMessage: originalMsg,
                                );
                              },
                      child:
                          isSaving
                              ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : const Text(
                                "Save observation",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white : AppColors.charcoal,
                        side: BorderSide(
                          color:
                              isDark
                                  ? Colors.white38
                                  : AppColors.charcoal.withValues(alpha: 0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed:
                          isSaving
                              ? null
                              : () {
                                context
                                    .read<ChatCubit>()
                                    .dismissHealthObservation(messageIndex);
                              },
                      child: const Text(
                        "Don't save",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.harvestAmber,
                      ),
                      onPressed: () => WarningSignsBottomSheet.show(context),
                      child: const Text("View warning signs"),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionItem(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white54 : AppColors.charcoal54,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color:
                  isDark
                      ? Colors.white70
                      : AppColors.charcoal.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

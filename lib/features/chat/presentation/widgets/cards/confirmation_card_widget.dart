import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:grocery_app/core/theme/app_colors.dart';

import '../../cubit/chat_cubit.dart';
import '../../cubit/chat_state.dart';

/// Renders the Distinct Amber Confirmation Card matching mockup design.
class ConfirmationCardWidget extends StatelessWidget {
  final Map<String, dynamic> confirmationData;

  const ConfirmationCardWidget({Key? key, required this.confirmationData})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title =
        confirmationData['action_title']?.toString() ??
        "Confirm before this happens";
    final description =
        confirmationData['description']?.toString() ??
        "Add 2 x A2 desi ghee 500g to cart — ₹900 total";
    final confirmationId =
        confirmationData['confirmation_id']?.toString() ?? '';
    final message =
        confirmationData['description']?.toString() ?? 'Confirm action';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ChatCubit, ChatState>(
      builder: (context, state) {
        final isConfirming = state.isConfirming;

        return Container(
          margin: const EdgeInsets.only(top: 10.0, bottom: 4.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF3B2506)
                : AppColors.harvestAmber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.harvestAmber, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.harvestAmber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.harvestAmber,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.charcoal,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.harvestAmber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                    onPressed:
                        isConfirming
                            ? null
                            : () {
                              if (confirmationId.isNotEmpty) {
                                context.read<ChatCubit>().confirmAction(
                                  confirmationId: confirmationId,
                                  message: message,
                                );
                              }
                            },
                    child:
                        isConfirming
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              "Confirm",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                    onPressed:
                        isConfirming
                            ? null
                            : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Action cancelled."),
                                ),
                              );
                            },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

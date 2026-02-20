import 'package:flutter/material.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isSearching;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
      ),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          // Use a consistent solid color for dark mode
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(27),
          boxShadow:
              focusNode.hasFocus
                  ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(27),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(
                Icons.search_rounded,
                color:
                    focusNode.hasFocus
                        ? colorScheme.primary
                        : (isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: "Search products...",
                    hintStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    isDense: true,
                  ),
                  onChanged: (value) => onChanged(value.trim()),
                ),
              ),
              if (isSearching)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                )
              else if (controller.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? Colors.grey.shade800
                                : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color:
                            isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                        size: 16,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

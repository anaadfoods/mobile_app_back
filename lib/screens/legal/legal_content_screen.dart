import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:grocery_app/models/legal_document_model.dart';
import 'package:grocery_app/styles/colors.dart';

/// Screen to display legal document content in HTML format
class LegalContentScreen extends StatelessWidget {
  final LegalDocument document;

  const LegalContentScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Premium Header
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.parchment.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.parchment,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                document.typeDisplay,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.parchment,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.parchment.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.parchment.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Version Info
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Version ${document.version}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          'Last updated: ${document.createdAt}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // HTML Content
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.charcoal.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Html(
                data: _formatContent(document.content),
                style: {
                  "body": Style(
                    fontSize: FontSize(14),
                    lineHeight: const LineHeight(1.4),
                    color: theme.textTheme.bodyMedium?.color,
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                  "h1": Style(
                    fontSize: FontSize(20),
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                    margin: Margins.zero,
                  ),
                  "h2": Style(
                    fontSize: FontSize(18),
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                    margin: Margins.zero,
                  ),
                  "p": Style(margin: Margins.zero),
                  "strong": Style(fontWeight: FontWeight.w600),
                  "a": Style(
                    color: AppColors.deepSoilGreen,
                    textDecoration: TextDecoration.underline,
                  ),
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format content - replace \r\n with proper HTML line breaks
  String _formatContent(String content) {
    // Replace double line breaks with single <br> for tighter spacing
    String formatted = content.replaceAll('\r\n\r\n', '<br>');
    // Replace single line breaks with space to keep text flowing
    formatted = formatted.replaceAll('\r\n', ' ');
    // Format section numbers to be bold with minimal spacing
    formatted = formatted.replaceAllMapped(
      RegExp(r'(\d+)\.\s+([A-Z])'),
      (match) => '<br><strong>${match.group(1)}. ${match.group(2)}</strong>',
    );
    return formatted;
  }
}

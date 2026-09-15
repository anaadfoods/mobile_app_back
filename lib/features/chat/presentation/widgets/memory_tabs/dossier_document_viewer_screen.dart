import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class DossierDocumentViewerScreen extends StatelessWidget {
  final String title;
  final String markdownContent;
  final String documentUrl;

  const DossierDocumentViewerScreen({
    Key? key,
    this.title = "Ayur-Vigyan Health Dossier",
    required this.markdownContent,
    required this.documentUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, size: 20),
            tooltip: "Copy Summary",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: markdownContent));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Health Dossier copied to clipboard.")),
              );
            },
          ),
          if (documentUrl.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.cloud_download_outlined, size: 20),
              tooltip: "Open / Download Document",
              onPressed: () async {
                try {
                  final uri = Uri.parse(documentUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (_) {}
              },
            ),
        ],
      ),
      body: Markdown(
        data: markdownContent,
        selectable: true,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        styleSheet: MarkdownStyleSheet(
          h1: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            height: 1.4,
          ),
          h2: const TextStyle(
            fontSize: 14.8,
            fontWeight: FontWeight.bold,
            color: AppColors.harvestAmber,
            height: 1.4,
          ),
          h3: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
          p: TextStyle(
            fontSize: 12.8,
            height: 1.5,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
          listBullet: const TextStyle(color: AppColors.harvestAmber, fontWeight: FontWeight.bold),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(top: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1)),
          ),
        ),
      ),
    );
  }
}

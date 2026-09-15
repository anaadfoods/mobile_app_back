import 'package:flutter/material.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/entities/medical_report_item_entity.dart';

class MedicalOcrTabWidget extends StatefulWidget {
  final List<MedicalReportItemEntity> reports;
  final VoidCallback? onUploadPressed;

  const MedicalOcrTabWidget({
    super.key,
    required this.reports,
    this.onUploadPressed,
  });

  @override
  State<MedicalOcrTabWidget> createState() => _MedicalOcrTabWidgetState();
}

class _MedicalOcrTabWidgetState extends State<MedicalOcrTabWidget> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurfaceElevated : AppColors.pureWhite;

    if (widget.reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.document_scanner_rounded, size: 48, color: AppColors.harvestAmber.withValues(alpha: 0.6)),
              const SizedBox(height: 12),
              const Text(
                "No Medical Reports Uploaded Yet",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                "Upload lab panels, blood tests, or prescriptions in AI Chat to automatically extract biomarkers and personalize your dietary guidelines.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.8,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bool isCompressed = widget.reports.length > 5;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Medical Reports & OCR (${widget.reports.length})",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              if (widget.onUploadPressed != null)
                TextButton.icon(
                  onPressed: widget.onUploadPressed,
                  icon: const Icon(Icons.upload_file_rounded, size: 16, color: AppColors.harvestAmber),
                  label: const Text(
                    "Upload Report",
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.harvestAmber),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          ...widget.reports.asMap().entries.map((entry) {
            final index = entry.key;
            final report = entry.value;

            if (isCompressed) {
              final isExpanded = _expandedIndex == index;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        setState(() {
                          _expandedIndex = isExpanded ? null : index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            _buildCompactStatusIcon(report.status),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    report.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    report.uploadedDate,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (report.markers.any((m) => m.isAbnormal)) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC62828).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  "${report.markers.where((m) => m.isAbnormal).length} Abnormal",
                                  style: const TextStyle(fontSize: 10, color: Color(0xFFC62828), fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                        child: _buildReportCard(report, cardBg, isDark, context, isExpanded: true),
                      ),
                  ],
                ),
              );
            } else {
              return _buildReportCard(report, cardBg, isDark, context);
            }
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCompactStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'COMPLETED':
        return const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 20);
      case 'PROCESSING':
        return const Icon(Icons.access_time_filled_rounded, color: Color(0xFFE65100), size: 20);
      default:
        return const Icon(Icons.cancel_rounded, color: Color(0xFFC62828), size: 20);
    }
  }

  Widget _buildReportCard(MedicalReportItemEntity report, Color cardBg, bool isDark, BuildContext context, {bool isExpanded = false}) {
    return Container(
      margin: isExpanded ? EdgeInsets.zero : const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: isExpanded ? null : BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isExpanded)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_rounded, size: 22, color: Color(0xFF00897B)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          _buildStatusBadge(report.status, isDark),
                          const SizedBox(width: 8),
                          Text(
                            report.uploadedDate,
                            style: TextStyle(
                              fontSize: 11.2,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (report.fileUrl.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.harvestAmber),
                    tooltip: "View Document",
                    onPressed: () => _handleViewDocument(context, report),
                  ),
              ],
            ),
          
          if (!isExpanded)
            const SizedBox(height: 10),

          if (isExpanded && report.fileUrl.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.harvestAmber),
                label: const Text("View Document", style: TextStyle(color: AppColors.harvestAmber, fontSize: 12)),
                onPressed: () => _handleViewDocument(context, report),
              ),
            ),

          if (report.fileUrl.isNotEmpty && _isImageFile(report.fileUrl)) ...[
            GestureDetector(
              onTap: () => _showImagePreviewDialog(context, report.fileUrl, report.title),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: isDark ? Colors.black26 : const Color(0xFFF3F4F6),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        report.fileUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 120,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.description_rounded, size: 36, color: Color(0xFF00897B)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text("Tap to View Full Image", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          Text(
            report.description,
            style: TextStyle(
              fontSize: 12.4,
              height: 1.42,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),

          if (report.markers.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text(
              "Extracted Biomarkers:",
              style: TextStyle(fontSize: 11.8, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: report.markers.map((m) => _buildMarkerChip(m, isDark)).toList(),
            ),
          ] else if (report.extractedKeywords.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: report.extractedKeywords.map((k) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(k, style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.w500)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    Color bg;
    Color fg;
    String label;

    switch (status.toUpperCase()) {
      case 'COMPLETED':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = "COMPLETED";
        break;
      case 'PROCESSING':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        label = "PROCESSING";
        break;
      default:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        label = "FAILED";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? bg.withValues(alpha: 0.25) : bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.8, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }

  Widget _buildMarkerChip(MedicalMarkerEntity marker, bool isDark) {
    final isAbn = marker.isAbnormal;
    final color = isAbn ? const Color(0xFFC62828) : const Color(0xFF2E7D32);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        "${marker.name}: ${marker.value ?? ''} ${marker.unit} ${isAbn ? '⚠️' : '✓'}",
        style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  bool _isImageFile(String url) {
    final clean = url.split('?').first.toLowerCase();
    return clean.endsWith('.jpg') || clean.endsWith('.jpeg') || clean.endsWith('.png') || clean.endsWith('.webp');
  }

  void _handleViewDocument(BuildContext context, MedicalReportItemEntity report) {
    if (_isImageFile(report.fileUrl)) {
      _showImagePreviewDialog(context, report.fileUrl, report.title);
    } else {
      _openFileUrl(report.fileUrl);
    }
  }

  void _showImagePreviewDialog(BuildContext context, String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xEE1F2937),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  color: Colors.black,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                  ),
                  child: InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: CircularProgressIndicator(color: AppColors.harvestAmber),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Icon(Icons.broken_image_rounded, color: Colors.white60, size: 48),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xEE1F2937),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                ),
                child: const Center(
                  child: Text(
                    "Pinch or drag to zoom",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openFileUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:grocery_app/common_widgets/animated_screen_header.dart';
import 'package:grocery_app/common_widgets/glassmorphic_icon_button.dart';
import 'package:grocery_app/core/theme/app_colors.dart';
import 'package:grocery_app/service_locator.dart';
import '../../domain/usecases/delete_memory_use_case.dart';
import '../cubit/health_profile_cubit.dart';
import '../cubit/health_profile_state.dart';
import '../widgets/memory_tabs/body_type_tab_widget.dart';
import '../widgets/memory_tabs/food_thali_tab_widget.dart';
import '../widgets/memory_tabs/medical_ocr_tab_widget.dart';
import '../widgets/memory_tabs/summary_dossier_tab_widget.dart';

/// 4-Tab AI Health Memory & Profile Screen with Animated Screen Header.
class HealthProfileScreen extends StatelessWidget {
  final HealthProfileCubit? cubit;
  const HealthProfileScreen({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<HealthProfileCubit>.value(
        value: cubit!,
        child: const _HealthProfileView(),
      );
    }
    return BlocProvider<HealthProfileCubit>(
      create: (_) => HealthProfileCubit()..loadHealthProfileData(),
      child: const _HealthProfileView(),
    );
  }
}

class _HealthProfileView extends StatefulWidget {
  const _HealthProfileView();

  @override
  State<_HealthProfileView> createState() => _HealthProfileViewState();
}

class _HealthProfileViewState extends State<_HealthProfileView> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _headerController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _showDeleteMemoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete AI Memory?'),
        content: const Text(
          'This will permanently delete all personalized semantic facts that Anaad AI has learned about you. '
          'Your chat history and health observations will not be affected.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await getIt<DeleteMemoryUseCase>()();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI memory deleted successfully.'),
                      backgroundColor: AppColors.deepSoilGreen,
                    ),
                  );
                  context.read<HealthProfileCubit>().loadHealthProfileData();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete AI memory: $e'),
                      backgroundColor: AppColors.softRed,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.softRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // ── Animated Screen Header (like Cart & Home Screens) ──
            BlocBuilder<HealthProfileCubit, HealthProfileState>(
              builder: (context, state) {
                String subtitle = "Synthesized Dosha, Thali & Clinical Dossier";
                if (state is HealthProfileLoaded) {
                  subtitle = state.bodyType.hasAssessment
                      ? "${state.bodyType.title} • Vitality ${state.summary.healthScore}%"
                      : "Assessment Pending • Complete to Activate Memory";
                }
                return AnimatedScreenHeader(
                  title: "AI Health Memory",
                  subtitle: subtitle,
                  icon: Icons.auto_awesome_rounded,
                  showBack: true,
                  onBack: () => context.pop(),
                  hasParticles: true,
                  animationController: _headerController,
                  actions: [
                    GlassmorphicIconButton(
                      icon: Icons.refresh_rounded,
                      iconSize: 20,
                      onTap: () => context.read<HealthProfileCubit>().loadHealthProfileData(),
                    ),
                    const SizedBox(width: 8),
                    GlassmorphicIconButton(
                      icon: Icons.delete_outline_rounded,
                      iconSize: 20,
                      onTap: () => _showDeleteMemoryDialog(context),
                    ),
                  ],
                );
              },
            ),

            // ── 4-Tab Bar ──
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                labelPadding: EdgeInsets.zero,
                indicatorColor: AppColors.harvestAmber,
                indicatorWeight: 3.0,
                labelColor: AppColors.harvestAmber,
                unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                labelStyle: const TextStyle(fontSize: 11.2, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 2),
                    icon: Icon(Icons.spa_rounded, size: 17),
                    text: "Body Type",
                  ),
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 2),
                    icon: Icon(Icons.restaurant_menu_rounded, size: 17),
                    text: "Food Thali",
                  ),
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 2),
                    icon: Icon(Icons.document_scanner_rounded, size: 17),
                    text: "Medical OCR",
                  ),
                  Tab(
                    iconMargin: EdgeInsets.only(bottom: 2),
                    icon: Icon(Icons.auto_awesome_rounded, size: 17),
                    text: "Summary",
                  ),
                ],
              ),
            ),

            // ── Tab Content ──
            Expanded(
              child: BlocBuilder<HealthProfileCubit, HealthProfileState>(
                builder: (context, state) {
                  if (state is HealthProfileLoading || state is HealthProfileInitial) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.harvestAmber),
                          SizedBox(height: 14),
                          Text(
                            "Synthesizing Health Profile & Memories...",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is HealthProfileError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.softRed, size: 44),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.harvestAmber),
                              onPressed: () => context.read<HealthProfileCubit>().loadHealthProfileData(),
                              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                              label: const Text("Retry", style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is HealthProfileLoaded) {
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Body Type
                        BodyTypeTabWidget(
                          bodyType: state.bodyType,
                          onDoshaChanged: (newDosha) => context.read<HealthProfileCubit>().updateDosha(newDosha),
                        ),

                        // Tab 2: Food Thali
                        FoodThaliTabWidget(
                          thalis: state.thalis,
                          onLogThaliPressed: () => _handleUploadFoodThali(context),
                        ),

                        // Tab 3: Medical OCR
                        MedicalOcrTabWidget(
                          reports: state.reports,
                          onUploadPressed: () => _handleUploadMedicalReport(context),
                        ),

                        // Tab 4: Summary Dossier (S3 Document)
                        SummaryDossierTabWidget(
                          summary: state.summary,
                          isGenerating: state.isGeneratingSummary,
                          onRegeneratePressed: () async {
                            final updated = await context.read<HealthProfileCubit>().generateSummaryDocument();
                            if (context.mounted && updated != null) {
                              final countStr = updated.syncedChatsCount > 0
                                  ? "Synced ${updated.syncedChatsCount} recent chat(s) & regenerated summary."
                                  : "Health memory summary regenerated successfully.";
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(countStr),
                                  backgroundColor: AppColors.deepSoilGreen,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUploadMedicalReport(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf', 'docx', 'txt'],
    );
    if (result != null && result.files.single.path != null && context.mounted) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Analyzing medical report with AI: $fileName..."),
          backgroundColor: AppColors.harvestAmber,
          duration: const Duration(seconds: 3),
        ),
      );

      final success = await context.read<HealthProfileCubit>().uploadMedicalReport(
        file: file,
        title: fileName.split('.').first,
        reportType: 'BLOOD_TEST',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? "Medical report processed and added to clinical memory!" : "Failed to process medical report."),
            backgroundColor: success ? AppColors.deepSoilGreen : AppColors.softRed,
          ),
        );
      }
    }
  }

  Future<void> _handleUploadFoodThali(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null && context.mounted) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Analyzing food thali plate with AI: $fileName..."),
          backgroundColor: AppColors.harvestAmber,
          duration: const Duration(seconds: 3),
        ),
      );

      final success = await context.read<HealthProfileCubit>().uploadFoodThali(
        imageFile: file,
        mealType: 'LUNCH',
        notes: 'Uploaded via AI Memory Screen',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? "Food thali analyzed and logged with nutrition insights!" : "Failed to upload food thali."),
            backgroundColor: success ? AppColors.deepSoilGreen : AppColors.softRed,
          ),
        );
      }
    }
  }
}

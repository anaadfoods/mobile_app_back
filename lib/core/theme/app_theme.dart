import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// AppTheme — Global ThemeData factory.
/// Strictly enforces ANAAD Premium 5-Color Rule.
///
/// Light Theme Strategy:
///   • Headers / AppBar → Deep Soil Green (brand authority)
///   • Canvas / Scaffold → Parchment (warm base)
///   • Cards / Popups / Banners → Pure White / Snow White (clean)
///   • Buttons CTA → Deep Soil Green (primary), Harvest Amber (secondary)
///   • Active/Highlight → Golden tones (warmGold, harvestAmber)
///   • Text → Charcoal on light, Parchment on dark surfaces
/// ═══════════════════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._(); // Prevent instantiation

  static const String _fontFamily = AppTextStyles.fontFamily;

  // ═══════════════════════════════════════════════════════════════════════════
  //  LIGHT THEME (Default Premium Content Canvas)
  // ═══════════════════════════════════════════════════════════════════════════

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: _fontFamily,
    brightness: Brightness.light,
    cardColor: AppColors.pureWhite,

    // ── Color Scheme ─────────────────────────────────────────────────────────
    colorScheme: const ColorScheme.light(
      primary: AppColors.deepSoilGreen, // Deep Soil Green
      secondary:
          AppColors.harvestAmber, // Harvest Amber for active/secondary elements
      surface: AppColors.parchment, // Parchment
      error: AppColors.softRed, // Warm terracotta (not scary red)
      onPrimary: AppColors.parchment, // Parchment
      onSecondary: AppColors.charcoal, // Charcoal
      onSurface: AppColors.charcoal, // Charcoal
      onError: AppColors.parchment, // Parchment
    ),

    scaffoldBackgroundColor: AppColors.parchment, // Parchment

    // ── AppBar — GREEN HEADER ────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.deepSoilGreen, // Green as header
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light, // White status bar icons
      iconTheme: const IconThemeData(
        color: AppColors.parchment,
      ), // Parchment icons on green
      titleTextStyle: AppTextStyles.appBarTitle.copyWith(
        color: AppColors.parchment,
      ), // Parchment text on green
    ),

    // ── Card — CLEAN WHITE ───────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.pureWhite, // Pure White for cards
      elevation: 2,
      shadowColor: AppColors.charcoal.withValues(
        alpha: AppColors.shadowOpacityLight,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),

    // ── Dialog — WHITE with green title ───────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.pureWhite,
      elevation: 8,
      shadowColor: AppColors.charcoal.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusXL),
      ),
      titleTextStyle: AppTextStyles.title.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: AppColors.deepSoilGreen, // Green title
      ),
    ),

    // ── Bottom Sheet — CLEAN WHITE ───────────────────────────────────────────
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.pureWhite,
      modalBackgroundColor: AppColors.pureWhite,
      elevation: 8,
      shadowColor: AppColors.charcoal.withValues(alpha: 0.12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // ── SnackBar — Premium themed ────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.deepSoilGreen,
      contentTextStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.parchment,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      actionTextColor: AppColors.harvestAmber,
    ),

    // ── ListTile ─────────────────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusS),
      ),
      iconColor: AppColors.deepSoilGreen, // Green icons for list items
      textColor: AppColors.charcoal,
    ),

    // ── TextTheme ────────────────────────────────────────────────────────────
    textTheme: TextTheme(
      displayLarge: AppTextStyles.heading.copyWith(
        color: AppColors.deepSoilGreen,
      ),
      displayMedium: AppTextStyles.subheading.copyWith(
        color: AppColors.deepSoilGreen,
      ),
      displaySmall: AppTextStyles.title.copyWith(
        color: AppColors.deepSoilGreen,
      ),
      bodyLarge: AppTextStyles.body.copyWith(
        color: AppColors.charcoal,
      ),
      bodyMedium: AppTextStyles.bodySmall.copyWith(color: AppColors.charcoal),
      bodySmall: AppTextStyles.caption.copyWith(color: AppColors.charcoal70),
      labelLarge: AppTextStyles.button.copyWith(color: AppColors.charcoal),
    ),

    // ── ElevatedButton — GREEN PRIMARY CTA ───────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.deepSoilGreen, // Green primary button
        foregroundColor: AppColors.parchment,
        textStyle: AppTextStyles.button.copyWith(fontFamily: _fontFamily),
        elevation: 2,
        shadowColor: AppColors.deepSoilGreen.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusM),
        ),
        minimumSize: const Size(0, 48),
      ),
    ),

    // ── TextButton — GOLDEN ACCENT ───────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor:
            AppColors.harvestAmber, // Golden amber for text buttons
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusS),
        ),
      ),
    ),

    // ── OutlinedButton — GREEN OUTLINE ───────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.deepSoilGreen,
        side: const BorderSide(color: AppColors.deepSoilGreen, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusM),
        ),
        minimumSize: const Size(0, 48),
      ),
    ),

    // ── InputDecoration ──────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.pureWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        borderSide: BorderSide(color: AppColors.charcoal.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        borderSide: BorderSide(color: AppColors.charcoal.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        borderSide: const BorderSide(
          color: AppColors.harvestAmber, // Golden focus ring
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        borderSide: const BorderSide(color: AppColors.softRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        borderSide: const BorderSide(color: AppColors.softRed, width: 2),
      ),
      labelStyle: AppTextStyles.label.copyWith(color: AppColors.charcoal70),
      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.charcoal38),
    ),

    // ── Divider ──────────────────────────────────────────────────────────────
    dividerTheme: DividerThemeData(
      color: AppColors.charcoal.withValues(alpha: 0.08),
      thickness: 1,
      space: 1,
    ),

    // ── FAB — GOLDEN ─────────────────────────────────────────────────────────
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.harvestAmber, // Golden FAB
      foregroundColor: AppColors.pureWhite,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // ── TabBar ───────────────────────────────────────────────────────────────
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.deepSoilGreen,
      unselectedLabelColor: AppColors.charcoal54,
      labelStyle: AppTextStyles.button,
      unselectedLabelStyle: AppTextStyles.label,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: const BorderSide(
          color: AppColors.harvestAmber, // Golden indicator
          width: 3,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      dividerColor: AppColors.transparent,
    ),

    // ── Chip — GOLDEN TINT ───────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.lightGold,
      selectedColor: AppColors.harvestAmber,
      secondarySelectedColor: AppColors.deepSoilGreen,
      labelStyle: AppTextStyles.caption.copyWith(
        color: AppColors.charcoal,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: AppTextStyles.caption.copyWith(
        color: AppColors.parchment,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide.none,
    ),

    // ── ProgressIndicator ────────────────────────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.deepSoilGreen,
      linearTrackColor: AppColors.lightGold,
      circularTrackColor: AppColors.lightGold,
    ),

    // ── Switch / Toggle ──────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.deepSoilGreen;
        }
        return AppColors.charcoal38;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.deepSoilGreen.withValues(alpha: 0.3);
        }
        return AppColors.charcoal12;
      }),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  //  DARK THEME / PREMIUM HEAVY BRANDING MODE
  // ═══════════════════════════════════════════════════════════════════════════

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: _fontFamily,
    brightness: Brightness.dark,
    cardColor: AppColors.darkSurface,

    // ── Color Scheme ─────────────────────────────────────────────────────────
    colorScheme: const ColorScheme.dark(
      primary: AppColors.deepSoilGreen, // Deep Soil Green for headers
      secondary: AppColors.darkSoftGold, // Soft Gold highlights
      surface: AppColors.darkSurface, // Elevated dark surface
      error: AppColors.darkSoftRed, // Accessible red
      onPrimary: AppColors.pureWhite, // White on primary
      onSecondary: AppColors.darkCanvas, // Canvas on secondary
      onSurface: AppColors.parchment, // Parchment on surface
      onError: AppColors.pureWhite, // White on error
    ),

    scaffoldBackgroundColor: AppColors.darkCanvas, // Premium dark canvas
    // ── AppBar ───────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.darkSurface, // Elevated app bar
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: AppColors.parchment),
      titleTextStyle: AppTextStyles.appBarTitle.copyWith(
        color: AppColors.parchment,
      ),
    ),

    // ── Card ─────────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: AppColors.darkSurfaceElevated, // Distinct elevated card color
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        side: const BorderSide(
          color: AppColors.charcoal40,
          width: 0.5,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),

    // ── Dialog ───────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.darkSurfaceElevated,
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusL),
        side: const BorderSide(color: AppColors.charcoal40),
      ),
      titleTextStyle: AppTextStyles.title.copyWith(
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: AppColors.parchment,
      ),
    ),

    // ── Bottom Sheet ─────────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.darkSurfaceElevated,
      modalBackgroundColor: AppColors.darkSurfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // ── SnackBar ─────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.parchment,
      contentTextStyle: AppTextStyles.bodySmall.copyWith(
        color: AppColors.deepSoilGreen,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
      actionTextColor: AppColors.harvestAmber,
    ),

    // ── ListTile ─────────────────────────────────────────────────────────────
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusS),
      ),
      iconColor: AppColors.parchment70,
      textColor: AppColors.parchment,
    ),

    textTheme: TextTheme(
      displayLarge: AppTextStyles.heading.copyWith(color: AppColors.pureWhite),
      displayMedium: AppTextStyles.subheading.copyWith(
        color: AppColors.pureWhite,
      ),
      displaySmall: AppTextStyles.title.copyWith(color: AppColors.pureWhite),
      bodyLarge: AppTextStyles.body.copyWith(color: AppColors.pureWhite),
      bodyMedium: AppTextStyles.bodySmall.copyWith(
        color: AppColors.pureWhite,
      ),
      bodySmall: AppTextStyles.caption.copyWith(color: AppColors.pureWhite),
      labelLarge: AppTextStyles.button.copyWith(color: AppColors.pureWhite),
    ),

    // ── ElevatedButton ───────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            AppColors.parchment, // Parchment text/fill inversion for dark mode
        foregroundColor: AppColors.deepSoilGreen,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusM),
        ),
        minimumSize: const Size(0, 48),
        textStyle: AppTextStyles.button.copyWith(fontFamily: _fontFamily),
      ),
    ),

    // ── TextButton ───────────────────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.parchment,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusS),
        ),
      ),
    ),

    // ── OutlinedButton ───────────────────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.parchment,
        side: const BorderSide(color: AppColors.parchment),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusM),
        ),
        minimumSize: const Size(0, 48),
      ),
    ),

    // ── InputDecoration ──────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.deepSoilGreen,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        borderSide: const BorderSide(color: AppColors.rawEarth12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        borderSide: const BorderSide(color: AppColors.rawEarth12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        borderSide: const BorderSide(color: AppColors.parchment, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppColors.radiusM),
        borderSide: const BorderSide(color: AppColors.rawEarth),
      ),
      labelStyle: AppTextStyles.label.copyWith(color: AppColors.parchment70),
      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.parchment54),
    ),

    // ── Divider ──────────────────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: AppColors.rawEarth12,
      thickness: 1,
      space: 1,
    ),

    // ── FAB ──────────────────────────────────────────────────────────────────
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.parchment, // Parchment
      foregroundColor: AppColors.deepSoilGreen,
    ),

    // ── TabBar ───────────────────────────────────────────────────────────────
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.parchment,
      unselectedLabelColor: AppColors.parchment54,
      labelStyle: AppTextStyles.button,
      unselectedLabelStyle: AppTextStyles.label,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: const BorderSide(color: AppColors.parchment, width: 3),
        borderRadius: BorderRadius.circular(2),
      ),
      dividerColor: AppColors.transparent,
    ),
  );
}

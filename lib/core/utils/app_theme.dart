import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand colours ─────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF0F172A); // Deep Slate
  static const Color accent = Color(0xFFD4AF37); // Metallic Gold

  // ── Surface / background ──────────────────────────────────────────────────
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardColor = Colors.white;
  static const Color divider = Color(0xFFE2E8F0);
  static const Color surfaceSoft = Color(0xFFF1F5F9);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // ── Semantic dashboard colours ───────────────────────────────────────────
  static const Color kpiInventory = Color(0xFF475569);
  static const Color kpiDiamond = Color(0xFFD4AF37);
  static const Color kpiProcess = Color(0xFFD97706);
  static const Color kpiPurchase = Color(0xFFDC2626);
  static const Color kpiRevenue = Color(0xFF059669);
  static const Color kpiProfit = Color(0xFF0F172A);
  static const Color success = Color(0xFF15803D);
  static const Color danger = Color(0xFFB91C1C);

  // ── Dashboard spacing rhythm ─────────────────────────────────────────────
  static const double dashboardSectionGap = 28;
  static const double dashboardBlockGap = 20;

  // ── Status colours ────────────────────────────────────────────────────────
  static const Color statusRaw = Color(0xFF9E9E9E);
  static const Color statusInProcess = Color(0xFFFFB300);
  static const Color statusCompleted = Color(0xFF43A047);
  static const Color statusSold = Color(0xFF1E88E5);
  static const Color statusPending = Color(0xFFFF7043);
  static const Color statusPaid = Color(0xFF43A047);
  static const Color statusReceived = Color(0xFF1E88E5);

  // ── Party-type colours ────────────────────────────────────────────────────
  static const Color partySupplier = Color(0xFF7B1FA2);
  static const Color partyCustomer = Color(0xFF0277BD);
  static const Color partyWorker = Color(0xFF00695C);

  // ── Shapes ────────────────────────────────────────────────────────────────
  static const double cardRadius = 16;
  static const double dialogRadius = 24;
  static const double buttonRadius = 12;
  static const double chipRadius = 24;
  static const double buttonHeight = 48;

  // ── Shadows ───────────────────────────────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A0F172A),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color(0x050F172A),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  // ── Full theme ────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      headlineSmall: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary),
      titleLarge: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary),
      titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 15, color: textPrimary, letterSpacing: -0.2),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: textPrimary, letterSpacing: -0.1),
      bodySmall: GoogleFonts.inter(fontSize: 13, color: textSecondary),
      labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.2),
      labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.5),
      labelSmall: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textMuted,
          letterSpacing: 0.5),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textPrimary,
        outline: divider,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme,

      // Cards
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius)),
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
      ),

      // Dialogs
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dialogRadius)),
        backgroundColor: Colors.white,
        elevation: 24,
        shadowColor: const Color(0x1A0F172A),
        titleTextStyle: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            letterSpacing: -0.5),
        contentTextStyle:
            GoogleFonts.inter(fontSize: 15, color: textSecondary, height: 1.5),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9), // Slate 100
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
            borderSide: const BorderSide(color: Colors.transparent, width: 1)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
            borderSide: const BorderSide(color: primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        labelStyle:
            GoogleFonts.inter(fontSize: 14, color: textSecondary, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: textMuted),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),

      // Filled button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.minPositive, buttonHeight),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius)),
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: divider, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          minimumSize: const Size(double.minPositive, buttonHeight),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius)),
          textStyle: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize:
              const Size(double.minPositive, buttonHeight),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius)),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
          color: divider, thickness: 1, space: 0),

      // Popup menus
      popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))),

      // Tooltips
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xE6000000),
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle:
            GoogleFonts.inter(color: Colors.white, fontSize: 12),
      ),

      // Snack bars
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        backgroundColor: const Color(0xFF1A1A2E),
        contentTextStyle:
            GoogleFonts.inter(color: Colors.white, fontSize: 13),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Color statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'raw':
      return AppTheme.statusRaw;
    case 'in_process':
      return AppTheme.statusInProcess;
    case 'completed':
      return AppTheme.statusCompleted;
    case 'sold':
      return AppTheme.statusSold;
    case 'pending':
      return AppTheme.statusPending;
    case 'paid':
      return AppTheme.statusPaid;
    case 'received':
      return AppTheme.statusReceived;
    default:
      return AppTheme.statusRaw;
  }
}

Color partyTypeColor(String type) {
  switch (type.toLowerCase()) {
    case 'supplier':
      return AppTheme.partySupplier;
    case 'customer':
      return AppTheme.partyCustomer;
    case 'worker':
      return AppTheme.partyWorker;
    default:
      return AppTheme.textSecondary;
  }
}

// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// COLORES — MODO CLARO
// ══════════════════════════════════════════════════════════════
class AppColors {
  AppColors._();

  static const Color primary       = Color(0xFF22C55E);
  static const Color primaryLight  = Color(0xFF4ADE80);
  static const Color primaryDark   = Color(0xFF16A34A);
  static const Color primaryPale   = Color(0xFFF0FDF4);
  static const Color primaryBorder = Color(0xFFBBF7D0);

  static const Color secondary      = Color(0xFF4A7FB5);
  static const Color secondaryLight = Color(0xFFEFF6FF);
  static const Color secondaryDark  = Color(0xFF2C5F8A);

  static const Color accent      = Color(0xFFF5B732);
  static const Color accentLight = Color(0xFFFFFBEB);

  static const Color background     = Color(0xFFF8FAFC);
  static const Color surface        = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  static const Color textPrimary   = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textHint      = Color(0xFF94A3B8);

  static const Color success = Color(0xFF22C55E);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF5B732);

  static const Color priceColor    = Color(0xFF1E293B);
  static const Color discountBadge = Color(0xFFEF4444);

  static const Color border  = Color(0xFFE2E8F0);  
  static const Color divider = Color(0xFFE2E8F0);  

  static const Color navSelected   = Color(0xFF16A34A);
  static const Color navUnselected = Color(0xFF94A3B8);
}


// ══════════════════════════════════════════════════════════════
// COLORES — MODO OSCURO (VERDADERO OSCURO)
// ══════════════════════════════════════════════════════════════
class AppColorsDark {
  AppColorsDark._();

  static const Color primary       = Color(0xFF22C55E);
  static const Color primaryLight  = Color(0xFF4ADE80);
  static const Color primaryDark   = Color(0xFF16A34A);
  static const Color primaryPale   = Color(0xFF1A3A2A);
  static const Color primaryBorder = Color(0xFF2D5A3A);

  static const Color secondary      = Color(0xFF60A5FA);
  static const Color secondaryLight = Color(0xFF1E3A5F);
  static const Color secondaryDark  = Color(0xFF93C5FD);

  static const Color accent      = Color(0xFFF5B732);
  static const Color accentLight = Color(0xFF332A1A);

  static const Color background     = Color(0xFF121212);
  static const Color surface        = Color(0xFF1E1E1E);
  static const Color surfaceVariant = Color(0xFF2C2C2C);

  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint      = Color(0xFF757575);

  static const Color success = Color(0xFF22C55E);
  static const Color error   = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF5B732);

  static const Color priceColor    = Color(0xFFFFFFFF);
  static const Color discountBadge = Color(0xFFEF4444);

  static const Color border  = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  static const Color navSelected   = Color(0xFF22C55E);
  static const Color navUnselected = Color(0xFF8E8E93);
}

// ══════════════════════════════════════════════════════════════
// TEXT STYLES
// ══════════════════════════════════════════════════════════════
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Nunito';

  static TextStyle displayLarge(BuildContext context) {
    return Theme.of(context).textTheme.displayLarge!.copyWith(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    );
  }
  
  static TextStyle displayMedium(BuildContext context) {
    return Theme.of(context).textTheme.displayMedium!.copyWith(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w700,
    );
  }
  
  static TextStyle headlineLarge(BuildContext context) {
    return Theme.of(context).textTheme.headlineLarge!.copyWith(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    );
  }
  
  static TextStyle headlineMedium(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
      fontFamily: fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    );
  }
  
  static TextStyle titleLarge(BuildContext context) {
    return Theme.of(context).textTheme.titleLarge!.copyWith(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }
  
  static TextStyle titleMedium(BuildContext context) {
    return Theme.of(context).textTheme.titleMedium!.copyWith(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
  }
  
  static TextStyle bodyLarge(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
    );
  }
  
  static TextStyle bodyMedium(BuildContext context) {
    return Theme.of(context).textTheme.bodyMedium!.copyWith(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );
  }
  
  static TextStyle bodySmall(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    );
  }
  
  static TextStyle labelLarge(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge!.copyWith(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }
  
  static TextStyle priceStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodyLarge!.copyWith(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
  }
  
  static TextStyle priceLarge(BuildContext context) {
    return Theme.of(context).textTheme.headlineMedium!.copyWith(
      fontFamily: fontFamily,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    );
  }
}

// ══════════════════════════════════════════════════════════════
// DIMENSIONES
// ══════════════════════════════════════════════════════════════
class AppDimensions {
  AppDimensions._();

  static const double paddingXS  = 4.0;
  static const double paddingS   = 8.0;
  static const double paddingM   = 16.0;
  static const double paddingL   = 24.0;
  static const double paddingXL  = 32.0;
  static const double paddingXXL = 48.0;

  static const double radiusS    = 8.0;
  static const double radiusM    = 12.0;
  static const double radiusL    = 16.0;
  static const double radiusXL   = 24.0;
  static const double radiusXXL  = 32.0;
  static const double radiusFull = 100.0;

  static const double cardElevation     = 2.0;
  static const double cardElevationHigh = 8.0;

  static const double iconS  = 18.0;
  static const double iconM  = 24.0;
  static const double iconL  = 32.0;
  static const double iconXL = 48.0;

  static const double buttonHeight  = 52.0;
  static const double buttonHeightS = 40.0;
  static const double inputHeight   = 56.0;
  static const double bottomNavHeight = 72.0;
}

// ══════════════════════════════════════════════════════════════
// APP THEME
// ══════════════════════════════════════════════════════════════
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        bg:             AppColors.background,
        surface:        AppColors.surface,
        surfaceVariant: AppColors.surfaceVariant,
        textPrimary:    AppColors.textPrimary,
        textSecondary:  AppColors.textSecondary,
        textHint:       AppColors.textHint,
        border:         AppColors.border,
        navSelected:    AppColors.navSelected,
        navUnselected:  AppColors.navUnselected,
        inputFill:      AppColors.surface,
      );
      

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        bg:             AppColorsDark.background,
        surface:        AppColorsDark.surface,
        surfaceVariant: AppColorsDark.surfaceVariant,
        textPrimary:    AppColorsDark.textPrimary,
        textSecondary:  AppColorsDark.textSecondary,
        textHint:       AppColorsDark.textHint,
        border:         AppColorsDark.border,
        navSelected:    AppColorsDark.navSelected,
        navUnselected:  AppColorsDark.navUnselected,
        inputFill:      AppColorsDark.surface,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surfaceVariant,
    required Color textPrimary,
    required Color textSecondary,
    required Color textHint,
    required Color border,
    required Color navSelected,
    required Color navUnselected,
    required Color inputFill,
  }) {


    final isDark = brightness == Brightness.dark;

    final textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTextStyles.fontFamily,
      textTheme: textTheme,
      colorScheme: ColorScheme(
        brightness:      brightness,
        primary:         AppColors.primary,
        onPrimary:       Colors.white,
        secondary:       isDark ? AppColorsDark.secondary : AppColors.secondary,
        onSecondary:     textPrimary,
        background:      bg,
        onBackground:    textPrimary,
        surface:         surface,
        onSurface:       textPrimary,
        error:           AppColors.error,
        onError:         Colors.white,
        surfaceVariant:  surfaceVariant,
        onSurfaceVariant: textSecondary,
        outline:         border,
      ),
      scaffoldBackgroundColor: bg,
      appBarTheme: AppBarTheme(
        backgroundColor:        surface,
        elevation:              0,
        scrolledUnderElevation: 2,
        iconTheme:   IconThemeData(color: textPrimary),
        titleTextStyle: textTheme.headlineLarge,
      ),
      cardTheme: CardThemeData(
        color:       surface,
        elevation:   AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        shadowColor: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          textStyle: textTheme.labelLarge,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical:   AppDimensions.paddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle:  textTheme.bodyMedium?.copyWith(color: textHint),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:       surface,
        selectedItemColor:     navSelected,
        unselectedItemColor:   navUnselected,
        showSelectedLabels:    true,
        showUnselectedLabels:  true,
        type:      BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? AppColors.primary
              : (isDark ? AppColorsDark.textHint : AppColors.textHint),
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (s) => s.contains(MaterialState.selected)
              ? AppColors.primary.withOpacity(0.4)
              : (isDark ? AppColorsDark.surfaceVariant : AppColors.surfaceVariant),
        ),
      ),
    );
  }
}
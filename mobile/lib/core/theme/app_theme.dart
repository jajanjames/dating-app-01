// FILE: lib/core/theme/app_theme.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Design tokens for naam (iOS & Android) matching the updated brand identity:
/// - Pure white background (#FFFFFF)
/// - naam ribbon-heart hot magenta-rose (#F7196B)
/// - Deep charcoal wordmark ink (#333333 / #18181B) and muted neutral (#71717A)
abstract final class JDateTokens {
  // Primary #F7196B naam Ribbon-Heart Magenta Accent & Deep Charcoal Ink
  static const Color brandRose = Color(0xFFF7196B);
  static const Color solarYellow = Color(0xFFFACC15);
  static const Color conciergeCream = Color(0xFFFBF3D5);
  static const Color conciergeGold = Color(0xFFEAB308);
  static const Color pitchBlack = Color(0xFF18181B);
  static const Color logoCharcoal = Color(0xFF333333);
  static const Color systemGreen = Color(0xFF34C759);

  // Solid Light Mode Surfaces
  static const Color pearlBackground = Color(0xFFFFFFFF);
  static const Color pearlSurface = Color(0xFFF8F8FA);
  static const Color pearlGlassFill = Color(0xF2FFFFFF);
  static const Color pearlGlassBorder = Color(0x1418181B);
  static const Color pearlInk = Color(0xFF18181B);
  static const Color pearlMuted = Color(0xFF71717A);

  // Semantic Error
  static const Color errorLight = Color(0xFFDC2626);

  // Spatial Scale
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;

  // Continuous Squircle Radii
  static const double radiusSm = 14.0;
  static const double radiusMd = 20.0;
  static const double radiusLg = 24.0;
  static const double radiusPortraitCard = 24.0;
  static const double radiusPill = 999.0;

  // Optical Blur Sigma
  static const double glassBlurSigma = 24.0;

  // Minimum Touch Target
  static const double minHitTarget = 48.0;
}

/// Light Mode Only theme provider.
final themeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.light);

/// Official naam Brand Wordmark widget rendering the bundled `assets/images/naam_logo.png`
/// (horizontal lowercase `naam` + inline magenta ribbon heart) with a matching vector fallback.
class NaamBrandLogo extends StatelessWidget {
  const NaamBrandLogo({
    super.key,
    this.height = 20.0,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/naam_logo.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _NaamVectorFallbackLogo(height: height);
      },
    );
  }
}

class _NaamVectorFallbackLogo extends StatelessWidget {
  const _NaamVectorFallbackLogo({
    this.height = 20.0,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    final fontSize = height * 0.92;
    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'naam',
            style: TextStyle(
              color: JDateTokens.logoCharcoal,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
              height: 1.0,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            Icons.favorite_border_rounded,
            size: fontSize * 0.88,
            color: JDateTokens.brandRose,
          ),
        ],
      ),
    );
  }
}

/// Reusable Liquid Glass / Clean Surface container.
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = JDateTokens.radiusLg,
    this.padding = const EdgeInsets.all(JDateTokens.spaceMd),
    this.blurSigma = JDateTokens.glassBlurSigma,
    this.tintColor,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double blurSigma;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    final baseFill = tintColor ?? JDateTokens.pearlGlassFill;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: baseFill,
            border: Border.all(
              color: JDateTokens.pearlGlassBorder,
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D18181B),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Circular tactile button used in headers and action bars.
class LiquidGlassOrbButton extends StatelessWidget {
  const LiquidGlassOrbButton({
    super.key,
    required this.icon,
    this.onTap,
    this.onPressed,
    this.tooltip = '',
    this.size = 54.0,
    this.iconSize = 22.0,
    this.iconColor,
    this.accentColor,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final String tooltip;
  final double size;
  final double iconSize;
  final Color? iconColor;
  final Color? accentColor;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final effectiveCallback = onTap ?? onPressed;
    final effectiveIconColor = isPrimary
        ? Colors.white
        : (iconColor ?? accentColor ?? JDateTokens.pitchBlack);

    return GestureDetector(
      onTap: effectiveCallback,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: effectiveCallback == null ? 0.38 : 1.0,
        child: SizedBox(
          width: size < 44.0 ? 44.0 : size,
          height: size < 44.0 ? 44.0 : size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrimary ? JDateTokens.brandRose : Colors.white,
              border: isPrimary
                  ? null
                  : Border.all(color: const Color(0xFFEAEAEF), width: 1.2),
              boxShadow: [
                if (isPrimary)
                  const BoxShadow(
                    color: Color(0x4DF7196B),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  )
                else
                  const BoxShadow(
                    color: Color(0x0D18181B),
                    blurRadius: 14,
                    offset: Offset(0, 4),
                  ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: effectiveIconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Light Mode theme with crisp white surfaces, #18181B typography, and #F7196B naam magenta-rose accents.
abstract final class AppTheme {
  static const Color yellowPrimary = JDateTokens.solarYellow;
  static const Color rosePrimary = JDateTokens.brandRose;
  static const Color inkPrimaryLight = JDateTokens.pearlInk;

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: JDateTokens.brandRose,
      onPrimary: Colors.white,
      secondary: JDateTokens.pitchBlack,
      onSecondary: Colors.white,
      tertiary: JDateTokens.solarYellow,
      surface: Colors.white,
      onSurface: JDateTokens.pearlInk,
      surfaceContainerHighest: JDateTokens.pearlSurface,
      onSurfaceVariant: JDateTokens.pearlMuted,
      outline: JDateTokens.pearlGlassBorder,
      error: JDateTokens.errorLight,
      onError: Colors.white,
    );

    final baseTextTheme = Typography.material2021().black.apply(
          bodyColor: JDateTokens.pearlInk,
          displayColor: JDateTokens.pearlInk,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: JDateTokens.pearlBackground,
      cardColor: Colors.white,
      dividerColor: JDateTokens.pearlGlassBorder,
      iconTheme: const IconThemeData(color: JDateTokens.pitchBlack),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: JDateTokens.pearlInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: JDateTokens.pearlInk,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: const TextStyle(
          color: JDateTokens.pearlInk,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          height: 1.14,
        ),
        displaySmall: const TextStyle(
          color: JDateTokens.pearlInk,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          height: 1.18,
        ),
        headlineMedium: const TextStyle(
          color: JDateTokens.pearlInk,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        titleLarge: const TextStyle(
          color: JDateTokens.pearlInk,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          height: 1.3,
        ),
        titleMedium: const TextStyle(
          color: JDateTokens.pearlInk,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        bodyLarge: const TextStyle(
          color: JDateTokens.pearlInk,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodyMedium: const TextStyle(
          color: JDateTokens.pearlMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.4,
        ),
        bodySmall: const TextStyle(
          color: JDateTokens.pearlMuted,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.35,
        ),
        labelLarge: const TextStyle(
          color: JDateTokens.pearlInk,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        labelMedium: const TextStyle(
          color: JDateTokens.pearlInk,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: JDateTokens.brandRose,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, JDateTokens.minHitTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: JDateTokens.spaceLg,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

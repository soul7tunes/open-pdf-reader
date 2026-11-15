import 'dart:ui';

import 'package:flutter/material.dart';

/// Open PDF Reader V2 design system — dark glassmorphism, first-class.
///
/// Language (from the user's "Design all" inspiration):
/// deep indigo background, frosted glass cards (white 8–12% fill, 1px
/// white 20% border, 24px radius), violet → pink → blue gradient glow,
/// big bold Poppins type, pill buttons, glass bottom navigation.
/// 2026 trends applied: Liquid Glass / glassmorphism 2.0 and Material 3
/// Expressive — glass only on the navigation layer and floating toolbars,
/// never over content; springy press-scale motion; thumb-first layout.
class AppColors {
  AppColors._();

  // Brand gradient: violet → pink → blue.
  static const Color violet = Color(0xFF7C3AED);
  static const Color pink = Color(0xFFEC4899);
  static const Color blue = Color(0xFF3B82F6);

  static const LinearGradient brandGradient = LinearGradient(
    colors: <Color>[violet, pink, blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark (default) theme.
  static const Color darkBg = Color(0xFF0A0A24);
  static const Color darkBg2 = Color(0xFF14143A);
  static const Color darkText = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFC7C7E8);
  static const Color darkGlass = Color(0x1AFFFFFF); // white 10%
  static const Color darkGlassBorder = Color(0x33FFFFFF); // white 20%
  static const Color darkGlassStrong = Color(0x2EFFFFFF);

  // Light theme — lavender glass.
  static const Color lightBg = Color(0xFFEDEBFF);
  static const Color lightBg2 = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1B1B3A);
  static const Color lightTextSecondary = Color(0xFF55557A);
  static const Color lightGlass = Color(0x99FFFFFF); // white 60%
  static const Color lightGlassBorder = Color(0xCCFFFFFF); // white 80%
  static const Color lightGlassStrong = Color(0xE6FFFFFF);
}

/// One place for the type scale. Nothing tiny: titles 24–28, section
/// titles 18–20, body 15–16, captions 12–13.
class AppType {
  AppType._();

  static const String headingFamily = 'Poppins';
  static const String bodyFamily = 'Inter';

  static TextTheme textTheme(Color text, Color secondary) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: headingFamily,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: text,
        height: 1.15,
      ),
      headlineMedium: TextStyle(
        fontFamily: headingFamily,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: text,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontFamily: headingFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: text,
        height: 1.25,
      ),
      titleMedium: TextStyle(
        fontFamily: headingFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: text,
        height: 1.3,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: text,
        height: 1.45,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: text,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: headingFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        height: 1.3,
      ),
    );
  }
}

/// The two app themes. Dark is the default (dark-first premium look).
class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: AppType.bodyFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.violet,
        secondary: AppColors.pink,
        tertiary: AppColors.blue,
        surface: AppColors.darkBg2,
      ),
      textTheme: AppType.textTheme(
        AppColors.darkText,
        AppColors.darkTextSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppType.headingFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
        iconTheme: IconThemeData(color: AppColors.darkText, size: 26),
      ),
      iconTheme: const IconThemeData(color: AppColors.darkText, size: 24),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkBg2,
        contentTextStyle: AppType.textTheme(
          AppColors.darkText,
          AppColors.darkTextSecondary,
        ).bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      fontFamily: AppType.bodyFamily,
      colorScheme: const ColorScheme.light(
        primary: AppColors.violet,
        secondary: AppColors.pink,
        tertiary: AppColors.blue,
        surface: Colors.white,
      ),
      textTheme: AppType.textTheme(
        AppColors.lightText,
        AppColors.lightTextSecondary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppType.headingFamily,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.lightText,
        ),
        iconTheme: IconThemeData(color: AppColors.lightText, size: 26),
      ),
      iconTheme: const IconThemeData(color: AppColors.lightText, size: 24),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.lightText,
        contentTextStyle: AppType.textTheme(
          Colors.white,
          Colors.white70,
        ).bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      useMaterial3: true,
    );
  }
}

/// Helpers that read the current brightness without a BuildContext theme
/// lookup in every widget.
extension GlassContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get glassFill =>
      isDark ? AppColors.darkGlass : AppColors.lightGlass;
  Color get glassFillStrong =>
      isDark ? AppColors.darkGlassStrong : AppColors.lightGlassStrong;
  Color get glassBorder =>
      isDark ? AppColors.darkGlassBorder : AppColors.lightGlassBorder;
  Color get textSecondary => isDark
      ? AppColors.darkTextSecondary
      : AppColors.lightTextSecondary;
}

/// Deep indigo background with three soft gradient glow blobs.
/// Static radial gradients only — no blur filters, so it stays 60fps.
class GlassBackground extends StatelessWidget {
  const GlassBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool dark = context.isDark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkBg : AppColors.lightBg,
      ),
      child: Stack(
        children: <Widget>[
          // Violet glow, top right.
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.violet.withValues(
                      alpha: dark ? 0.45 : 0.25,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Pink glow, middle left.
          Positioned(
            top: 320,
            left: -140,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.pink.withValues(alpha: dark ? 0.32 : 0.18),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Blue glow, bottom right.
          Positioned(
            bottom: -140,
            right: -60,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[
                    AppColors.blue.withValues(alpha: dark ? 0.38 : 0.20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// A frosted glass card: translucent fill, 1px light border, 24px radius,
/// soft shadow. No BackdropFilter here — the glow background behind it
/// gives the glass feel without the fps cost.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: context.glassFill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: context.glassBorder, width: 1),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDark ? 0.30 : 0.08,
            ),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Gradient icon chip used on tool tiles and file rows.
class GradientIconChip extends StatelessWidget {
  const GradientIconChip({
    required this.icon,
    super.key,
    this.size = 52,
    this.iconSize = 26,
    this.gradient = AppColors.brandGradient,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }
}

/// Springy press-scale wrapper (Material 3 Expressive motion):
/// shrinks to 96% while pressed, springs back on release.
class PressScale extends StatefulWidget {
  const PressScale({required this.child, required this.onTap, super.key});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// The primary action button: full-width gradient pill, big bold label.
class GradientButton extends StatelessWidget {
  const GradientButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.enabled = true,
    this.height = 62,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && onPressed != null;
    return PressScale(
      onTap: active ? onPressed! : () {},
      child: Opacity(
        opacity: active ? 1 : 0.5,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.50),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, color: Colors.white, size: 26),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppType.headingFamily,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A glass pill button (secondary action).
class GlassButton extends StatelessWidget {
  const GlassButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && onPressed != null;
    return PressScale(
      onTap: active ? onPressed! : () {},
      child: Opacity(
        opacity: active ? 1 : 0.5,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: context.glassFillStrong,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: context.glassBorder, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(
                  icon,
                  size: 24,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppType.headingFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill-shaped glass search bar.
class GlassSearchBar extends StatelessWidget {
  const GlassSearchBar({
    required this.controller,
    required this.hint,
    super.key,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: context.glassFill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.glassBorder, width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.textSecondary,
              ),
          prefixIcon: Icon(
            Icons.search,
            size: 26,
            color: context.textSecondary,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 22),
                  onPressed: () {
                    controller.clear();
                    onChanged?.call('');
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

/// Staggered entrance: fade + slide up, delayed per list index.
class StaggeredIn extends StatelessWidget {
  const StaggeredIn({
    required this.index,
    required this.child,
    super.key,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// The one place BackdropFilter is used on content screens: the floating
/// glass pill bar (bottom nav / viewer controls). Everywhere else the
/// glass is static, so scrolling stays smooth.
class FloatingGlassBar extends StatelessWidget {
  const FloatingGlassBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.glassFillStrong,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: context.glassBorder, width: 1),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: context.isDark ? 0.35 : 0.10,
                ),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

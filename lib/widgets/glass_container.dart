import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';

/// iOS 27 Liquid Glass surface with translucent tint, backdrop blur,
/// specular hairline border, and automatic accessibility fallback.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double blurSigma;
  final Color? tintColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding,
    this.margin,
    this.blurSigma = 18,
    this.tintColor,
    this.borderColor,
    this.borderWidth = 0.85,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableBlur = MediaQuery.disableAnimationsOf(context);

    final effectiveTint = tintColor ?? colors.glassTint;
    final effectiveBorder = borderColor ?? colors.glassBorder;
    final effectiveShadow = boxShadow ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ];

    Widget surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: disableBlur
            ? (isDark ? colors.card : colors.card.withValues(alpha: 0.96))
            : effectiveTint,
        borderRadius: borderRadius,
        border: Border.all(color: effectiveBorder, width: borderWidth),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: isDark ? 0.10 : 0.42),
            Colors.white.withValues(alpha: isDark ? 0.02 : 0.06),
          ],
        ),
      ),
      child: child,
    );

    if (!disableBlur) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: surface,
      );
    }

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: effectiveShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: surface,
      ),
    );
  }
}

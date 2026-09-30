import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';

class LiquidGlassCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? tintColor;
  final double opacity;
  final VoidCallback? onTap;
  final bool hasSpecularBorder;
  final double borderWidth;
  final bool enableLightShimmer;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.borderRadius = 28.0,
    this.blur = 24.0,
    this.padding = const EdgeInsets.all(16.0),
    this.margin,
    this.tintColor,
    this.opacity = 1.0,
    this.onTap,
    this.hasSpecularBorder = true,
    this.borderWidth = 1.2,
    this.enableLightShimmer = true,
  });

  @override
  State<LiquidGlassCard> createState() => _LiquidGlassCardState();
}

class _LiquidGlassCardState extends State<LiquidGlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    if (widget.enableLightShimmer) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(LiquidGlassCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enableLightShimmer && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if (!widget.enableLightShimmer && _shimmerController.isAnimating) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardBody = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
        child: AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            final shimmerPos = _shimmerController.value;

            return Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.tintColor ??
                    GlassTheme.glassColor(isDark, opacityMultiplier: widget.opacity),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: widget.hasSpecularBorder
                    ? Border.all(
                        width: widget.borderWidth,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.70),
                      )
                    : null,
                gradient: LinearGradient(
                  begin: Alignment(-1.0 + (shimmerPos * 2.5), -1.0),
                  end: Alignment(1.0 + (shimmerPos * 2.5), 1.0),
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.16 * widget.opacity),
                          Colors.white.withValues(alpha: 0.28 * widget.opacity), // specular light gleam
                          Colors.white.withValues(alpha: 0.05 * widget.opacity),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.70 * widget.opacity),
                          Colors.white.withValues(alpha: 0.90 * widget.opacity), // specular light gleam
                          Colors.white.withValues(alpha: 0.40 * widget.opacity),
                        ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
              child: child,
            );
          },
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap != null) {
      cardBody = GestureDetector(
        onTap: widget.onTap,
        child: cardBody,
      );
    }

    return Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: GlassTheme.glassShadow(isDark),
      ),
      child: cardBody,
    );
  }
}

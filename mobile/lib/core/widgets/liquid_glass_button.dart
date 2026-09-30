import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/glass_theme.dart';

enum GlassButtonVariant {
  primary,
  secondary,
  glass,
}

class LiquidGlassButton extends StatefulWidget {
  final Widget? icon;
  final String? label;
  final VoidCallback? onPressed;
  final GlassButtonVariant variant;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? accentColor;
  final bool isLoading;

  const LiquidGlassButton({
    super.key,
    this.icon,
    this.label,
    required this.onPressed,
    this.variant = GlassButtonVariant.glass,
    this.height = 54.0,
    this.borderRadius = 27.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0),
    this.accentColor,
    this.isLoading = false,
  });

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed == null || widget.isLoading) return;
    HapticFeedback.lightImpact();
    _animController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (widget.onPressed == null || widget.isLoading) return;
    _animController.reverse();
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: widget.height,
              padding: widget.padding,
              decoration: _buildDecoration(isDark),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            widget.icon!,
                            if (widget.label != null) const SizedBox(width: 8),
                          ],
                          if (widget.label != null)
                            Text(
                              widget.label!,
                              style: GlassTheme.title(
                                isDark: widget.variant == GlassButtonVariant.primary ? true : isDark,
                                weight: FontWeight.w600,
                              ).copyWith(fontSize: 16),
                            ),
                        ],
                      ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration(bool isDark) {
    switch (widget.variant) {
      case GlassButtonVariant.primary:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            colors: [
              widget.accentColor ?? GlassTheme.iosBlue,
              (widget.accentColor ?? GlassTheme.iosBlue).withOpacity(0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            width: 1.2,
            color: Colors.white.withOpacity(0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: (widget.accentColor ?? GlassTheme.iosBlue).withOpacity(0.38),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        );

      case GlassButtonVariant.secondary:
      case GlassButtonVariant.glass:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: isDark
              ? Colors.white.withOpacity(0.12)
              : Colors.white.withOpacity(0.65),
          border: Border.all(
            width: 1.2,
            color: isDark
                ? Colors.white.withOpacity(0.24)
                : Colors.white.withOpacity(0.80),
          ),
          boxShadow: GlassTheme.glassShadow(isDark),
        );
    }
  }
}

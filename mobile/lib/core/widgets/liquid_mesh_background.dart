import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidMeshBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const LiquidMeshBackground({
    super.key,
    required this.child,
    this.isDark = true,
  });

  @override
  State<LiquidMeshBackground> createState() => _LiquidMeshBackgroundState();
}

class _LiquidMeshBackgroundState extends State<LiquidMeshBackground>
    with TickerProviderStateMixin {
  late AnimationController _primaryController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Primary fluid wave motion (5.5s cycle for visible, hypnotic liquid flow)
    _primaryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat(reverse: true);

    // Secondary pulsing wave (3.2s cycle for organic expansion)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Base canvas
        Positioned.fill(
          child: Container(
            color: widget.isDark ? const Color(0xFF06070B) : const Color(0xFFF3F5FC),
          ),
        ),

        // Animated Fluid Liquid Orbs
        AnimatedBuilder(
          animation: Listenable.merge([_primaryController, _pulseController]),
          builder: (context, _) {
            final t1 = _primaryController.value;
            final t2 = _pulseController.value;

            // Fluid wave paths
            final dx1 = math.sin(t1 * 2 * math.pi) * 85;
            final dy1 = math.cos(t1 * 2 * math.pi) * 75;
            final dx2 = math.cos(t2 * 2 * math.pi) * 70;
            final dy2 = math.sin(t2 * 2 * math.pi) * 80;
            final scale1 = 0.85 + (0.25 * math.sin(t1 * math.pi));
            final scale2 = 0.90 + (0.20 * math.cos(t2 * math.pi));

            return Stack(
              children: [
                // Top-Left Neon Indigo/Violet Fluid Bloom
                Positioned(
                  top: -100 + dy1,
                  left: -80 + dx1,
                  child: Transform.scale(
                    scale: scale1,
                    child: Container(
                      width: size.width * 1.1,
                      height: size.width * 1.1,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: widget.isDark
                              ? [
                                  const Color(0xFF7C3AED).withValues(alpha: 0.55),
                                  const Color(0xFF4C1D95).withValues(alpha: 0.28),
                                  Colors.transparent,
                                ]
                              : [
                                  const Color(0xFFA78BFA).withValues(alpha: 0.45),
                                  const Color(0xFFC4B5FD).withValues(alpha: 0.20),
                                  Colors.transparent,
                                ],
                          stops: const [0.0, 0.48, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Middle-Right Electric Coral/Magenta Fluid Bloom
                Positioned(
                  top: size.height * 0.28 + dy2,
                  right: -110 + dx2,
                  child: Transform.scale(
                    scale: scale2,
                    child: Container(
                      width: size.width * 1.05,
                      height: size.width * 1.05,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: widget.isDark
                              ? [
                                  const Color(0xFFDB2777).withValues(alpha: 0.48),
                                  const Color(0xFF9D174D).withValues(alpha: 0.22),
                                  Colors.transparent,
                                ]
                              : [
                                  const Color(0xFFF472B6).withValues(alpha: 0.40),
                                  const Color(0xFFFBCFE8).withValues(alpha: 0.18),
                                  Colors.transparent,
                                ],
                          stops: const [0.0, 0.52, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Center Cyan/Snap Yellow Ambient Caustics
                Positioned(
                  bottom: -110 - dy1,
                  left: size.width * 0.1 - dx2,
                  child: Transform.scale(
                    scale: scale1,
                    child: Container(
                      width: size.width * 0.95,
                      height: size.width * 0.95,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: widget.isDark
                              ? [
                                  const Color(0xFF06B6D4).withValues(alpha: 0.45),
                                  const Color(0xFFEAB308).withValues(alpha: 0.20),
                                  Colors.transparent,
                                ]
                              : [
                                  const Color(0xFF38BDF8).withValues(alpha: 0.38),
                                  const Color(0xFFFEF08A).withValues(alpha: 0.18),
                                  Colors.transparent,
                                ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Foreground application content
        widget.child,
      ],
    );
  }
}

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/glass_theme.dart';

class CameraScreen extends StatefulWidget {
  final VoidCallback? onSnapCaptured;

  const CameraScreen({super.key, this.onSnapCaptured});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  int _selectedDuration = 5;
  bool _allowReplay = true;
  bool _isFrontFacing = false;
  int _selectedLensIndex = 0;
  late AnimationController _shutterPulseController;

  final List<int> _durations = [1, 3, 5, 10, 30];
  final List<String> _lensNames = ["Normal", "Cyber Glow", "Film 35mm", "Retro VHS", "Sunset Flare"];

  @override
  void initState() {
    super.initState();
    // Continuous liquid breathing ripple on the shutter button
    _shutterPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _shutterPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview Placeholder with subtle ambient gradient
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF1C1924),
                  Color(0xFF0C0A12),
                  Colors.black,
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.camera_viewfinder,
                    color: Colors.white.withValues(alpha: 0.35),
                    size: 80,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Camera Kit Engine Ready",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 14,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Liquid Glass Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassCircleButton(
                    icon: CupertinoIcons.bolt_fill,
                    onTap: () {
                      HapticFeedback.lightImpact();
                    },
                  ),
                  // Snap Duration Pill
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: _durations.map((d) {
                            final isSel = d == _selectedDuration;
                            return GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedDuration = d);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeOutBack,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSel ? GlassTheme.snapYellow : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                            color: GlassTheme.snapYellow.withValues(alpha: 0.4),
                                            blurRadius: 10,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  "${d}s",
                                  style: TextStyle(
                                    color: isSel ? Colors.black : Colors.white.withValues(alpha: 0.70),
                                    fontSize: 12,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  _buildGlassCircleButton(
                    icon: CupertinoIcons.switch_camera,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isFrontFacing = !_isFrontFacing);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls & Shutter & Lens Carousel
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Replay Toggle Pill with spring tap
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() => _allowReplay = !_allowReplay);
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutBack,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _allowReplay
                              ? Colors.white.withValues(alpha: 0.18)
                              : Colors.black.withValues(alpha: 0.40),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _allowReplay
                                ? GlassTheme.snapYellow.withValues(alpha: 0.70)
                                : Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.arrow_2_circlepath,
                              size: 13,
                              color: _allowReplay ? GlassTheme.snapYellow : Colors.white.withValues(alpha: 0.60),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _allowReplay ? "1 Replay Allowed" : "No Replay",
                              style: TextStyle(
                                color: _allowReplay ? Colors.white : Colors.white.withValues(alpha: 0.60),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Lenses Carousel
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _lensNames.length,
                    itemBuilder: (context, index) {
                      final isSel = index == _selectedLensIndex;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedLensIndex = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel
                                ? Colors.white.withValues(alpha: 0.28)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                              color: isSel
                                  ? Colors.white.withValues(alpha: 0.85)
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            _lensNames[index],
                            style: TextStyle(
                              color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.60),
                              fontSize: 12,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Liquid Pulsing Concentric Shutter Button
                AnimatedBuilder(
                  animation: _shutterPulseController,
                  builder: (context, _) {
                    final rippleProgress = _shutterPulseController.value;
                    final rippleScale = 1.0 + (rippleProgress * 0.45);
                    final rippleOpacity = (1.0 - rippleProgress).clamp(0.0, 1.0) * 0.55;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Expanding liquid pulse wave
                        Transform.scale(
                          scale: rippleScale,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: GlassTheme.snapYellow.withValues(alpha: rippleOpacity),
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),

                        // Physical Liquid Glass Shutter
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            widget.onSnapCaptured?.call();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.white.withValues(alpha: 0.18),
                                behavior: SnackBarBehavior.floating,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(20)),
                                ),
                                content: const Text(
                                  "📸 Snap captured! Ready to send into chat.",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.85),
                                width: 4.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: GlassTheme.snapYellow.withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCircleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

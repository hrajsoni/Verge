import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/glass_theme.dart';

class LiquidSnapViewer extends StatefulWidget {
  final String mediaUrl;
  final int durationSeconds;
  final bool canReplay;
  final String senderName;
  final VoidCallback onFinished;
  final VoidCallback? onReplay;

  const LiquidSnapViewer({
    super.key,
    required this.mediaUrl,
    required this.durationSeconds,
    required this.senderName,
    required this.onFinished,
    this.canReplay = false,
    this.onReplay,
  });

  static Future<void> show({
    required BuildContext context,
    required String mediaUrl,
    required int durationSeconds,
    required String senderName,
    bool canReplay = false,
    VoidCallback? onReplay,
    required VoidCallback onFinished,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, anim1, anim2) {
        return LiquidSnapViewer(
          mediaUrl: mediaUrl,
          durationSeconds: durationSeconds,
          senderName: senderName,
          canReplay: canReplay,
          onReplay: onReplay,
          onFinished: () {
            Navigator.of(context).pop();
            onFinished();
          },
        );
      },
    );
  }

  @override
  State<LiquidSnapViewer> createState() => _LiquidSnapViewerState();
}

class _LiquidSnapViewerState extends State<LiquidSnapViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late int _remainingSeconds;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationSeconds;

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );

    _progressController.forward().whenComplete(() {
      _finishSnap();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _finishSnap() {
    HapticFeedback.lightImpact();
    widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Snap Media Display
          GestureDetector(
            onTap: _finishSnap,
            child: CachedNetworkImage(
              imageUrl: widget.mediaUrl,
              fit: BoxFit.cover,
              placeholder: (context, _) => const Center(
                child: CupertinoActivityIndicator(color: Colors.white, radius: 18),
              ),
              errorWidget: (context, url, error) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: GlassTheme.snapYellow, size: 40),
                    const SizedBox(height: 12),
                    Text("Snap expired or unavailable", style: GlassTheme.body(isDark: true)),
                  ],
                ),
              ),
            ),
          ),

          // Top Liquid Glass HUD (Sender Info & Countdown Timer Ring)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sender Tag
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.flame_fill, color: GlassTheme.snapYellow, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              widget.senderName,
                              style: GlassTheme.title(isDark: true).copyWith(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Liquid Glass Countdown Indicator
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _progressController,
                              builder: (context, _) {
                                return CircularProgressIndicator(
                                  value: 1.0 - _progressController.value,
                                  strokeWidth: 3.0,
                                  valueColor: const AlwaysStoppedAnimation(GlassTheme.snapYellow),
                                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                                );
                              },
                            ),
                            Text(
                              '$_remainingSeconds',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

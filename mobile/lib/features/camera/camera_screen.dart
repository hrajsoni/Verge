import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/widgets/liquid_glass_button.dart';

class CameraScreen extends StatefulWidget {
  final VoidCallback? onSnapCaptured;

  const CameraScreen({super.key, this.onSnapCaptured});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  int _selectedDuration = 5;
  bool _allowReplay = true;
  bool _isFrontFacing = false;
  int _selectedLensIndex = 0;
  late AnimationController _shutterPulseController;
  late AnimationController _videoRecordingController;
  bool _isRecordingVideo = false;

  // Real capture state
  Uint8List? _capturedBytes;
  bool _isUploading = false;

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

    _videoRecordingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
  }

  @override
  void dispose() {
    _shutterPulseController.dispose();
    _videoRecordingController.dispose();
    super.dispose();
  }

  Future<void> _captureSnap({required ImageSource source}) async {
    HapticFeedback.heavyImpact();
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: source,
        preferredCameraDevice: _isFrontFacing ? CameraDevice.front : CameraDevice.rear,
        imageQuality: 88,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _capturedBytes = bytes;
        });
      }
    } catch (e) {
      debugPrint('[Camera] Capture error: $e');
    }
  }

  Future<void> _sendSnap() async {
    if (_capturedBytes == null) return;
    setState(() => _isUploading = true);
    HapticFeedback.mediumImpact();

    try {
      final uploadRes = await ApiClient().requestUploadUrl(
        mimeType: 'image/jpeg',
        type: 'SNAP',
        sizeBytes: _capturedBytes!.length,
      );

      if (uploadRes.data != null && uploadRes.data['uploadUrl'] != null) {
        final presignedUrl = uploadRes.data['uploadUrl'] as String;
        await ApiClient().uploadFileToS3(
          presignedUrl: presignedUrl,
          fileBytes: _capturedBytes!,
          mimeType: 'image/jpeg',
        );
      }
    } catch (e) {
      debugPrint('[Camera] Upload warning: $e');
    }

    if (!mounted) return;
    setState(() {
      _isUploading = false;
      _capturedBytes = null;
    });

    widget.onSnapCaptured?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.white.withValues(alpha: 0.22),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Row(
          children: [
            Icon(CupertinoIcons.checkmark_alt_circle_fill, color: GlassTheme.snapYellow),
            SizedBox(width: 10),
            Text(
              "📸 Snap uploaded & ready to share!",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _discardSnap() {
    HapticFeedback.lightImpact();
    setState(() {
      _capturedBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedBytes != null) {
      return _buildSnapPreviewScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview Placeholder with Snapchat double-tap flip
          GestureDetector(
            onDoubleTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isFrontFacing = !_isFrontFacing);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.white.withValues(alpha: 0.20),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(milliseconds: 900),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  content: Text(
                    _isFrontFacing ? "Front Camera Active" : "Rear Camera Active",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
            child: Container(
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
                      "Camera Engine Ready",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 14,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Double tap to flip · Hold to record",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
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
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
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

                // Controls Row: Gallery + Shutter + Lens Reset
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Gallery Picker Button
                      _buildGlassCircleButton(
                        icon: CupertinoIcons.photo_on_rectangle,
                        size: 52,
                        onTap: () => _captureSnap(source: ImageSource.gallery),
                      ),

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

                              // Physical Liquid Glass Shutter with Snapchat hold-to-record
                              GestureDetector(
                                onTap: () => _captureSnap(source: ImageSource.camera),
                                onLongPressStart: (_) {
                                  HapticFeedback.heavyImpact();
                                  setState(() => _isRecordingVideo = true);
                                  _videoRecordingController.forward(from: 0.0);
                                },
                                onLongPressEnd: (_) {
                                  HapticFeedback.mediumImpact();
                                  _videoRecordingController.stop();
                                  setState(() => _isRecordingVideo = false);
                                  _captureSnap(source: ImageSource.camera);
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 84,
                                      height: 84,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _isRecordingVideo
                                              ? Colors.redAccent
                                              : Colors.white.withValues(alpha: 0.85),
                                          width: 4.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_isRecordingVideo ? Colors.redAccent : GlassTheme.snapYellow)
                                                .withValues(alpha: 0.45),
                                            blurRadius: 28,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          width: _isRecordingVideo ? 54 : 66,
                                          height: _isRecordingVideo ? 54 : 66,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _isRecordingVideo
                                                ? Colors.redAccent
                                                : Colors.white.withValues(alpha: 0.95),
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
                                    if (_isRecordingVideo)
                                      AnimatedBuilder(
                                        animation: _videoRecordingController,
                                        builder: (context, _) {
                                          return SizedBox(
                                            width: 84,
                                            height: 84,
                                            child: CircularProgressIndicator(
                                              value: _videoRecordingController.value,
                                              strokeWidth: 4.5,
                                              valueColor: const AlwaysStoppedAnimation(GlassTheme.snapYellow),
                                            ),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Filter Reset Button
                      _buildGlassCircleButton(
                        icon: CupertinoIcons.sparkles,
                        size: 52,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedLensIndex = 0);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapPreviewScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Captured Image
          Image.memory(
            _capturedBytes!,
            fit: BoxFit.cover,
          ),

          // Top Header Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGlassCircleButton(
                    icon: CupertinoIcons.xmark,
                    onTap: _discardSnap,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.timer, color: GlassTheme.snapYellow, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          "${_selectedDuration}s · ${_allowReplay ? '1 Replay' : 'No Replay'}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
          ),

          // Bottom Send Bar
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: LiquidGlassButton(
                          label: "Send Snap",
                          isLoading: _isUploading,
                          variant: GlassButtonVariant.primary,
                          accentColor: GlassTheme.snapYellow,
                          icon: const Icon(CupertinoIcons.paperplane_fill, color: Colors.black, size: 18),
                          onPressed: _sendSnap,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 44,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: Colors.white, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}

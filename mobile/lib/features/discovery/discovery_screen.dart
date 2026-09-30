import 'dart:math' as math;
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/widgets/liquid_glass_button.dart';
import '../../core/widgets/liquid_glass_card.dart';

class DiscoveryProfile {
  final String id;
  final String name;
  final int age;
  final double distanceKm;
  final String bio;
  final List<String> interests;
  final List<String> photos;

  const DiscoveryProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.distanceKm,
    required this.bio,
    required this.interests,
    required this.photos,
  });
}

class DiscoveryScreen extends StatefulWidget {
  final VoidCallback? onOpenMatches;

  const DiscoveryScreen({super.key, this.onOpenMatches});

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _activePhotoIndex = 0;
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0.0;
  late AnimationController _hoverController;

  // History stack for Tinder Rewind mechanic
  final List<int> _swipeHistory = [];

  final List<DiscoveryProfile> _profiles = const [
    DiscoveryProfile(
      id: "1",
      name: "Sophia Vance",
      age: 23,
      distanceKm: 2.4,
      bio: "Film photography & techno nights. Send me your favorite song or snap your weekend view 📸✨",
      interests: ["Photography", "Techno", "Matcha", "Art"],
      photos: [
        "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80",
        "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&auto=format&fit=crop&q=80",
        "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&auto=format&fit=crop&q=80",
      ],
    ),
    DiscoveryProfile(
      id: "2",
      name: "Elena Rostova",
      age: 24,
      distanceKm: 4.1,
      bio: "Coffee enthusiast, architecture lover & sunset chaser. Looking for genuine connections.",
      interests: ["Coffee", "Design", "Running", "Travel"],
      photos: [
        "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&auto=format&fit=crop&q=80",
        "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&auto=format&fit=crop&q=80",
      ],
    ),
    DiscoveryProfile(
      id: "3",
      name: "Aria Chen",
      age: 22,
      distanceKm: 6.8,
      bio: "Software dev & DJ. Let's trade Spotify playlists and grab boba 🧋🎧",
      interests: ["Coding", "Electronic", "Boba", "Gaming"],
      photos: [
        "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800&auto=format&fit=crop&q=80",
        "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80",
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Idle liquid float animation (gentle floating breathing motion)
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onSwipe(bool isLike) {
    HapticFeedback.mediumImpact();
    if (_currentIndex < _profiles.length) {
      final currentProfile = _profiles[_currentIndex];
      _swipeHistory.add(_currentIndex);

      // Call backend swipe API
      ApiClient().swipeUser(currentProfile.id, isLike ? 'LIKE' : 'PASS').catchError((e) {
        debugPrint('[Discovery] Swipe API fallback: $e');
        return e;
      });

      // Tinder-style Match trigger (if Sophia or mutual)
      if (isLike && currentProfile.id == "1") {
        _showMatchCelebration(currentProfile);
      }
    }

    setState(() {
      _currentIndex++;
      _activePhotoIndex = 0;
      _dragOffset = Offset.zero;
      _dragAngle = 0.0;
    });
  }

  void _undoSwipe() {
    if (_swipeHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.white.withValues(alpha: 0.20),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text("No previous swipes to rewind!", style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() {
      final lastIndex = _swipeHistory.removeLast();
      _currentIndex = lastIndex;
      _activePhotoIndex = 0;
      _dragOffset = Offset.zero;
      _dragAngle = 0.0;
    });
  }

  void _showMatchCelebration(DiscoveryProfile profile) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Match Celebration",
      barrierColor: Colors.black.withValues(alpha: 0.88),
      transitionDuration: const Duration(milliseconds: 400),
      transitionBuilder: (context, anim, _, child) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim.value),
          child: Opacity(opacity: anim.value, child: child),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: LiquidGlassCard(
                borderRadius: 36,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glowing Flame Icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GlassTheme.snapYellow,
                        boxShadow: [
                          BoxShadow(
                            color: GlassTheme.snapYellow.withValues(alpha: 0.5),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.flame_fill, color: Colors.black, size: 36),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "It's a Match!",
                      style: GlassTheme.headline(isDark: isDark).copyWith(
                        fontSize: 32,
                        color: GlassTheme.snapYellow,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "You and ${profile.name} liked each other.",
                      textAlign: TextAlign.center,
                      style: GlassTheme.body(isDark: isDark).copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 28),

                    // Dual Spring Avatars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: GlassTheme.iosBlue, width: 2.5),
                          ),
                          child: const CircleAvatar(
                            radius: 44,
                            backgroundImage: NetworkImage(
                              "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=800",
                            ),
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(-16, 0),
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: GlassTheme.snapYellow, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: GlassTheme.snapYellow.withValues(alpha: 0.35),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundImage: CachedNetworkImageProvider(profile.photos.first),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),

                    // Action Buttons
                    LiquidGlassButton(
                      label: "Send a Snap",
                      variant: GlassButtonVariant.primary,
                      accentColor: GlassTheme.snapYellow,
                      icon: const Icon(CupertinoIcons.camera_fill, color: Colors.black, size: 18),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onOpenMatches?.call();
                      },
                    ),
                    const SizedBox(height: 12),
                    LiquidGlassButton(
                      label: "Keep Swiping",
                      variant: GlassButtonVariant.secondary,
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showProfileDetailSheet(DiscoveryProfile profile, bool isDark) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  color: isDark ? Colors.black.withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.90),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 40),
                    children: [
                      // Pull handle
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // Photos Carousel
                      SizedBox(
                        height: 380,
                        child: PageView.builder(
                          itemCount: profile.photos.length,
                          itemBuilder: (context, pIdx) {
                            return CachedNetworkImage(
                              imageUrl: profile.photos[pIdx],
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Profile Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "${profile.name}, ${profile.age}",
                                  style: GlassTheme.headline(isDark: isDark).copyWith(fontSize: 28),
                                ),
                                const SizedBox(width: 8),
                                const Icon(CupertinoIcons.checkmark_seal_fill, color: GlassTheme.iosBlue, size: 22),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.location_solid, color: GlassTheme.iosBlue, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  "${profile.distanceKm} km nearby",
                                  style: GlassTheme.caption(isDark: isDark).copyWith(
                                    color: GlassTheme.iosBlue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text("About Me", style: GlassTheme.title(isDark: isDark)),
                            const SizedBox(height: 8),
                            Text(profile.bio, style: GlassTheme.body(isDark: isDark).copyWith(fontSize: 15)),
                            const SizedBox(height: 20),
                            Text("Interests & Passions", style: GlassTheme.title(isDark: isDark)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.interests.map((interest) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: GlassTheme.iosBlue.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: GlassTheme.iosBlue.withValues(alpha: 0.35)),
                                  ),
                                  child: Text(
                                    interest,
                                    style: const TextStyle(
                                      color: GlassTheme.iosBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 32),
                            // Quick Action Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: CupertinoIcons.clear,
                                  color: Colors.redAccent,
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _onSwipe(false);
                                  },
                                  size: 60,
                                ),
                                _buildActionButton(
                                  icon: CupertinoIcons.heart_fill,
                                  color: Colors.pinkAccent,
                                  isDark: isDark,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    _onSwipe(true);
                                  },
                                  size: 60,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // iOS Liquid Glass Top Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GlassTheme.snapYellow,
                        boxShadow: [
                          BoxShadow(
                            color: GlassTheme.snapYellow.withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.flame_fill, color: Colors.black, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text("Be-Snap", style: GlassTheme.headline(isDark: isDark)),
                  ],
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.white.withValues(alpha: 0.60),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.70),
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.slider_horizontal_3,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Interactive 3D Liquid Swipe Card Stack
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: _currentIndex >= _profiles.length
                  ? _buildEmptyState(isDark)
                  : Stack(
                      children: [
                        // Next card underneath
                        if (_currentIndex + 1 < _profiles.length)
                          Transform.scale(
                            scale: 0.94,
                            child: Transform.translate(
                              offset: const Offset(0, 16),
                              child: _buildProfileCard(
                                _profiles[_currentIndex + 1],
                                isDark,
                                isTop: false,
                              ),
                            ),
                          ),

                        // Active interactive card with 3D tilt & idle breathing
                        AnimatedBuilder(
                          animation: _hoverController,
                          builder: (context, child) {
                            final idleY = _dragOffset == Offset.zero
                                ? math.sin(_hoverController.value * 2 * math.pi) * 5.0
                                : 0.0;

                            return GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  _dragOffset += details.delta;
                                  _dragAngle = (_dragOffset.dx / size.width) * 0.18;
                                });
                              },
                              onPanEnd: (details) {
                                if (_dragOffset.dx.abs() > 120) {
                                  _onSwipe(_dragOffset.dx > 0);
                                } else {
                                  setState(() {
                                    _dragOffset = Offset.zero;
                                    _dragAngle = 0.0;
                                  });
                                }
                              },
                              child: Transform.translate(
                                offset: Offset(_dragOffset.dx, _dragOffset.dy + idleY),
                                child: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateZ(_dragAngle)
                                    ..rotateY((_dragOffset.dx / size.width) * 0.12),
                                  child: Stack(
                                    children: [
                                      _buildProfileCard(
                                        _profiles[_currentIndex],
                                        isDark,
                                        isTop: true,
                                      ),
                                      // Dynamic Liquid Stamp on drag
                                      if (_dragOffset.dx > 25)
                                        Positioned(
                                          top: 40,
                                          left: 30,
                                          child: _buildSwipeStamp("LIKE", Colors.greenAccent),
                                        ),
                                      if (_dragOffset.dx < -25)
                                        Positioned(
                                          top: 40,
                                          right: 30,
                                          child: _buildSwipeStamp("PASS", Colors.redAccent),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
            ),
          ),

          // Bottom Action Bar with Tinder-inspired Rewind + Pass + Super Like + Like
          Padding(
            padding: const EdgeInsets.only(bottom: 96, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rewind / Undo Button
                _buildActionButton(
                  icon: CupertinoIcons.arrow_counterclockwise,
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                  onTap: _undoSwipe,
                  size: 48,
                ),
                const SizedBox(width: 16),

                // Pass Button
                _buildActionButton(
                  icon: CupertinoIcons.clear,
                  color: Colors.redAccent,
                  isDark: isDark,
                  onTap: () => _onSwipe(false),
                  size: 58,
                ),
                const SizedBox(width: 16),

                // Super Like Button
                _buildActionButton(
                  icon: CupertinoIcons.star_fill,
                  color: GlassTheme.snapYellow,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    _onSwipe(true);
                  },
                  size: 48,
                ),
                const SizedBox(width: 16),

                // Like Button
                _buildActionButton(
                  icon: CupertinoIcons.heart_fill,
                  color: Colors.pinkAccent,
                  isDark: isDark,
                  onTap: () => _onSwipe(true),
                  size: 58,
                  isPrimary: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeStamp(String text, Color color) {
    return Transform.rotate(
      angle: text == "LIKE" ? -0.2 : 0.2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2.5),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(DiscoveryProfile profile, bool isDark, {required bool isTop}) {
    final photoUrl = profile.photos.length > _activePhotoIndex
        ? profile.photos[_activePhotoIndex]
        : profile.photos.first;

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Photo
          CachedNetworkImage(
            imageUrl: photoUrl,
            fit: BoxFit.cover,
            placeholder: (context, _) => Container(color: Colors.grey.shade900),
          ),

          // Story Segments at top (Tinder/Instagram pattern)
          if (profile.photos.length > 1)
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: Row(
                children: List.generate(profile.photos.length, (idx) {
                  final isCurrent = idx == _activePhotoIndex;
                  return Expanded(
                    child: Container(
                      height: 3.5,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: isCurrent ? Colors.white : Colors.white.withValues(alpha: 0.35),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),

          // Left/Right touch targets for multi-photo navigation
          if (isTop) ...[
            Positioned(
              left: 0,
              top: 40,
              bottom: 120,
              width: MediaQuery.of(context).size.width * 0.35,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (_activePhotoIndex > 0) {
                    HapticFeedback.selectionClick();
                    setState(() => _activePhotoIndex--);
                  }
                },
              ),
            ),
            Positioned(
              right: 0,
              top: 40,
              bottom: 120,
              width: MediaQuery.of(context).size.width * 0.65,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (_activePhotoIndex < profile.photos.length - 1) {
                    HapticFeedback.selectionClick();
                    setState(() => _activePhotoIndex++);
                  }
                },
              ),
            ),
          ],

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.45, 0.65, 1.0],
              ),
            ),
          ),

          // Liquid Glass Frosted Info Panel
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: LiquidGlassCard(
              padding: const EdgeInsets.all(18),
              borderRadius: 24,
              opacity: 0.9,
              enableLightShimmer: isTop,
              onTap: isTop ? () => _showProfileDetailSheet(profile, isDark) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${profile.name}, ${profile.age}",
                          style: GlassTheme.headline(isDark: true).copyWith(fontSize: 24),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: GlassTheme.iosBlue.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: GlassTheme.iosBlue.withValues(alpha: 0.60),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.location_solid, color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              "${profile.distanceKm} km",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Info 'i' button for expanding details
                      GestureDetector(
                        onTap: () => _showProfileDetailSheet(profile, isDark),
                        child: const Icon(CupertinoIcons.info_circle_fill, color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GlassTheme.body(isDark: true).copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: profile.interests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    required double size,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.10)
                  : Colors.white.withValues(alpha: 0.70),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.85),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: isPrimary ? 22 : 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: size * 0.44),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: LiquidGlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.sparkles, color: GlassTheme.snapYellow, size: 48),
            const SizedBox(height: 16),
            Text("You're all caught up!", style: GlassTheme.title(isDark: isDark)),
            const SizedBox(height: 8),
            Text(
              "Check back soon or expand your discovery radius in settings.",
              textAlign: TextAlign.center,
              style: GlassTheme.body(isDark: isDark),
            ),
            const SizedBox(height: 24),
            LiquidGlassButton(
              label: "Rewind Swipes",
              variant: GlassButtonVariant.primary,
              accentColor: GlassTheme.snapYellow,
              icon: const Icon(CupertinoIcons.arrow_counterclockwise, color: Colors.black, size: 18),
              onPressed: _undoSwipe,
            ),
          ],
        ),
      ),
    );
  }
}

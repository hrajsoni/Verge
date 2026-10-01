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

  double _discoveryRadiusKm = 25.0;
  bool _isExpandingRadius = false;

  final List<DiscoveryProfile> _profiles = [
    const DiscoveryProfile(
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
    const DiscoveryProfile(
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
    const DiscoveryProfile(
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

  final List<DiscoveryProfile> _extendedPool = const [
    DiscoveryProfile(
      id: "4",
      name: "Chloe Kim",
      age: 23,
      distanceKm: 28.5,
      bio: "Snowboarder & UX designer. Always hunting for the city's crispest pour-over coffee ☕️🏂",
      interests: ["Design", "Snowboarding", "Coffee", "Cinema"],
      photos: [
        "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800&auto=format&fit=crop&q=80",
        "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&auto=format&fit=crop&q=80",
      ],
    ),
    DiscoveryProfile(
      id: "5",
      name: "Marcus Vance",
      age: 25,
      distanceKm: 34.2,
      bio: "Record producer & vinyl collector. Let's go to jazz clubs and talk synths 🎷🎹",
      interests: ["Music", "Vinyl", "Audio", "Nightlife"],
      photos: [
        "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800&auto=format&fit=crop&q=80",
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800&auto=format&fit=crop&q=80",
      ],
    ),
    DiscoveryProfile(
      id: "6",
      name: "Zara Patel",
      age: 24,
      distanceKm: 42.0,
      bio: "Art gallery curator & botanical enthusiast. Looking for someone to explore hidden museums with 🌿🖼️",
      interests: ["Art", "Museums", "Plants", "Photography"],
      photos: [
        "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800&auto=format&fit=crop&q=80",
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

    _prewarmNextDeckImages();
  }

  /// Tinder-style Deck Image Pre-warming: Pre-fetches the next 3 profiles' images
  /// into RAM memory cache so swiping has zero image popping or blank cards.
  void _prewarmNextDeckImages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (int i = 0; i <= 3; i++) {
        final idx = _currentIndex + i;
        if (idx < _profiles.length) {
          for (final photo in _profiles[idx].photos) {
            precacheImage(CachedNetworkImageProvider(photo), context);
          }
        }
      }
    });
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

    _prewarmNextDeckImages();
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

                            // Voice Prompt (Hinge / Tinder / RAW style interactive waveform)
                            _VoicePromptPlayer(
                              promptQuestion: "My most spontaneous weekend story 🎙️",
                              audioDurationSeconds: 24,
                              isDark: isDark,
                            ),
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
                    Text("Verge", style: GlassTheme.headline(isDark: isDark)),
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
    final estimatedProfiles = (_discoveryRadiusKm * 1.5).round();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: LiquidGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GlassTheme.snapYellow.withValues(alpha: 0.18),
                  border: Border.all(color: GlassTheme.snapYellow.withValues(alpha: 0.40)),
                ),
                child: const Center(
                  child: Icon(CupertinoIcons.compass_fill, color: GlassTheme.snapYellow, size: 36),
                ),
              ),
              const SizedBox(height: 16),
              Text("Deck Depleted", style: GlassTheme.title(isDark: isDark).copyWith(fontSize: 22)),
              const SizedBox(height: 6),
              Text(
                "You've seen everyone within ${_discoveryRadiusKm.round()} km.",
                textAlign: TextAlign.center,
                style: GlassTheme.body(isDark: isDark).copyWith(fontSize: 14),
              ),
              const SizedBox(height: 22),

              // Interactive Discovery Radius Expansion Slider
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.40)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Expand Discovery Radius",
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${_discoveryRadiusKm.round()} km",
                          style: const TextStyle(
                            color: GlassTheme.snapYellow,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: GlassTheme.snapYellow,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.20),
                        thumbColor: Colors.white,
                        overlayColor: GlassTheme.snapYellow.withValues(alpha: 0.20),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: _discoveryRadiusKm,
                        min: 25.0,
                        max: 100.0,
                        divisions: 15,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _discoveryRadiusKm = val;
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.person_2_fill, color: GlassTheme.iosBlue, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          "Reveals ~$estimatedProfiles more people nearby",
                          style: const TextStyle(
                            color: GlassTheme.iosBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Expand & Search Button
              LiquidGlassButton(
                label: _isExpandingRadius ? "Searching Radar..." : "Expand Radius & Search",
                isLoading: _isExpandingRadius,
                variant: GlassButtonVariant.primary,
                accentColor: GlassTheme.snapYellow,
                icon: const Icon(CupertinoIcons.sparkles, color: Colors.black, size: 18),
                onPressed: () async {
                  HapticFeedback.heavyImpact();
                  setState(() => _isExpandingRadius = true);
                  await Future.delayed(const Duration(milliseconds: 650));
                  if (!mounted) return;

                  setState(() {
                    _isExpandingRadius = false;
                    // Append extended profiles to deck
                    for (final p in _extendedPool) {
                      if (!_profiles.any((existing) => existing.id == p.id)) {
                        _profiles.add(p);
                      }
                    }
                  });

                  _prewarmNextDeckImages();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      content: Row(
                        children: [
                          const Icon(CupertinoIcons.check_mark_circled_solid, color: GlassTheme.snapYellow),
                          const SizedBox(width: 8),
                          Text(
                            "Found ${_extendedPool.length} new people within ${_discoveryRadiusKm.round()} km!",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              if (_swipeHistory.isNotEmpty)
                LiquidGlassButton(
                  label: "Rewind Last Swipe",
                  variant: GlassButtonVariant.secondary,
                  icon: const Icon(CupertinoIcons.arrow_counterclockwise, color: Colors.white, size: 16),
                  onPressed: _undoSwipe,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Interactive Hinge/Tinder/RAW Voice Prompt Audio Player with dynamic animated waveform
class _VoicePromptPlayer extends StatefulWidget {
  final String promptQuestion;
  final int audioDurationSeconds;
  final bool isDark;

  const _VoicePromptPlayer({
    required this.promptQuestion,
    required this.audioDurationSeconds,
    required this.isDark,
  });

  @override
  State<_VoicePromptPlayer> createState() => _VoicePromptPlayerState();
}

class _VoicePromptPlayerState extends State<_VoicePromptPlayer>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late AnimationController _animController;
  final List<double> _waveformHeights = const [
    0.3, 0.6, 0.9, 0.4, 0.8, 1.0, 0.7, 0.5,
    0.9, 0.6, 0.3, 0.8, 0.5, 0.9, 0.7, 0.4,
    0.6, 0.8, 0.4, 0.2,
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.audioDurationSeconds),
    );

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isPlaying = false;
        });
        _animController.reset();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _animController.forward();
    } else {
      _animController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.mic_fill, color: GlassTheme.iosPink, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.promptQuestion,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _animController,
            builder: (context, _) {
              final progress = _animController.value;
              final currentSec = (progress * widget.audioDurationSeconds).round();

              return Row(
                children: [
                  // Play/Pause button
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [GlassTheme.iosPink, GlassTheme.iosPurple],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: GlassTheme.iosPink.withValues(alpha: 0.35),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Dynamic Waveform Bars
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: List.generate(_waveformHeights.length, (idx) {
                          final barProgress = idx / _waveformHeights.length;
                          final isPlayed = progress >= barProgress;
                          final baseHeight = _waveformHeights[idx] * 28;

                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 3.5,
                            height: _isPlaying
                                ? (baseHeight + (isPlayed ? 4 : 0)).clamp(6.0, 32.0)
                                : baseHeight.clamp(6.0, 32.0),
                            decoration: BoxDecoration(
                              color: isPlayed
                                  ? GlassTheme.iosPink
                                  : (widget.isDark ? Colors.white30 : Colors.black26),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Duration text
                  Text(
                    "0:${currentSec.toString().padLeft(2, '0')} / 0:${widget.audioDurationSeconds}",
                    style: TextStyle(
                      color: widget.isDark ? Colors.white60 : Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}


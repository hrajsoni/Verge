import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/glass_theme.dart';

class LiquidGlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final int unreadChatCount;

  const LiquidGlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.unreadChatCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 70,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                  width: 1.2,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.85),
                ),
                boxShadow: GlassTheme.glassShadow(isDark),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / 4;

                  return Stack(
                    children: [
                      // Liquid Gliding Frosted Indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutBack, // Organic elastic spring
                        left: currentIndex * tabWidth,
                        top: 0,
                        bottom: 0,
                        width: tabWidth,
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              colors: currentIndex == 1 // Camera tab
                                  ? [
                                      GlassTheme.snapYellow.withValues(alpha: 0.35),
                                      GlassTheme.snapYellow.withValues(alpha: 0.18),
                                    ]
                                  : [
                                      isDark
                                          ? Colors.white.withValues(alpha: 0.22)
                                          : Colors.black.withValues(alpha: 0.10),
                                      isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : Colors.black.withValues(alpha: 0.04),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              width: 1.2,
                              color: currentIndex == 1
                                  ? GlassTheme.snapYellow.withValues(alpha: 0.70)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.35)
                                      : Colors.black.withValues(alpha: 0.15)),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: currentIndex == 1
                                    ? GlassTheme.snapYellow.withValues(alpha: 0.25)
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.08)
                                        : Colors.black.withValues(alpha: 0.04)),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Nav Bar Items
                      Row(
                        children: [
                          Expanded(
                            child: _NavItem(
                              icon: CupertinoIcons.flame_fill,
                              label: "Discover",
                              isActive: currentIndex == 0,
                              onTap: () => onTabSelected(0),
                            ),
                          ),
                          Expanded(
                            child: _NavItem(
                              icon: CupertinoIcons.camera_fill,
                              label: "Camera",
                              isActive: currentIndex == 1,
                              isCenterHighlight: true,
                              onTap: () => onTabSelected(1),
                            ),
                          ),
                          Expanded(
                            child: _NavItem(
                              icon: CupertinoIcons.chat_bubble_2_fill,
                              label: "Chats",
                              isActive: currentIndex == 2,
                              badgeCount: unreadChatCount,
                              onTap: () => onTabSelected(2),
                            ),
                          ),
                          Expanded(
                            child: _NavItem(
                              icon: CupertinoIcons.person_crop_circle_fill,
                              label: "Profile",
                              isActive: currentIndex == 3,
                              onTap: () => onTabSelected(3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isCenterHighlight;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isCenterHighlight = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedScale(
          scale: isActive ? 1.08 : 0.95,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: isCenterHighlight ? 25 : 23,
                    color: isActive
                        ? (isCenterHighlight
                            ? (isDark ? GlassTheme.snapYellow : const Color(0xFFD4AF37))
                            : (isDark ? Colors.white : Colors.black))
                        : (isDark ? Colors.white.withValues(alpha: 0.40) : Colors.black.withValues(alpha: 0.35)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: GlassTheme.caption(isDark: isDark).copyWith(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? (isDark ? Colors.white : Colors.black)
                          : (isDark ? Colors.white.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.38)),
                    ),
                  ),
                ],
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -4,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: GlassTheme.iosPink,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

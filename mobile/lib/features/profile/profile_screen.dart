import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/widgets/liquid_glass_card.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onRestartOnboarding;

  const ProfileScreen({super.key, this.onRestartOnboarding});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = "Harshit Raj";
  String _bio = "Building cross-platform apps & capturing moments ✨";
  String _avatarUrl = "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=800&auto=format&fit=crop&q=80";
  int _maxDistance = 25;
  String _ageRange = "20 - 28";

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiClient().getMyProfile();
      if (res.data != null) {
        final profile = res.data['profile'] ?? {};
        final prefs = res.data['preferences'] ?? {};
        if (mounted) {
          setState(() {
            if (profile['displayName'] != null) _displayName = profile['displayName'];
            if (profile['bio'] != null && (profile['bio'] as String).isNotEmpty) _bio = profile['bio'];
            if (profile['avatarUrl'] != null) _avatarUrl = profile['avatarUrl'];
            if (prefs['maxDistanceKm'] != null) _maxDistance = prefs['maxDistanceKm'];
            if (prefs['minAge'] != null && prefs['maxAge'] != null) {
              _ageRange = "${prefs['minAge']} - ${prefs['maxAge']}";
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[ProfileScreen] Profile fetch fallback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Profile", style: GlassTheme.headline(isDark: isDark)),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.7)),
                    ),
                    child: Icon(
                      CupertinoIcons.gear_alt,
                      color: isDark ? Colors.white : Colors.black87,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Hero Profile Card
          LiquidGlassCard(
            padding: const EdgeInsets.all(24),
            borderRadius: 30,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: GlassTheme.snapYellow, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: GlassTheme.snapYellow.withValues(alpha: 0.3),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundImage: NetworkImage(_avatarUrl),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: GlassTheme.iosBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.pencil, color: Colors.white, size: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(_displayName, style: GlassTheme.headline(isDark: isDark).copyWith(fontSize: 22)),
                const SizedBox(height: 4),
                Text("@besnap_user • 24", style: GlassTheme.caption(isDark: isDark)),
                const SizedBox(height: 12),
                Text(
                  _bio,
                  textAlign: TextAlign.center,
                  style: GlassTheme.body(isDark: isDark).copyWith(fontSize: 14),
                ),
                const SizedBox(height: 18),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCol("142", "Snaps Sent", isDark),
                    Container(height: 28, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                    _buildStatCol("28", "Matches", isDark),
                    Container(height: 28, width: 1, color: Colors.white.withValues(alpha: 0.2)),
                    _buildStatCol("99%", "Replay Rate", isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Preferences & Settings Cards
          Text(
            "DISCOVERY PREFERENCES",
            style: GlassTheme.caption(isDark: isDark).copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          LiquidGlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            borderRadius: 22,
            child: Column(
              children: [
                _buildSettingRow(
                  icon: CupertinoIcons.location_solid,
                  label: "Maximum Distance",
                  value: "$_maxDistance km",
                  isDark: isDark,
                ),
                Divider(color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2)),
                _buildSettingRow(
                  icon: CupertinoIcons.person_2_fill,
                  label: "Age Range",
                  value: _ageRange,
                  isDark: isDark,
                ),
                Divider(color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2)),
                _buildSettingRow(
                  icon: CupertinoIcons.bell_fill,
                  label: "Snap Notifications",
                  value: "Enabled",
                  isDark: isDark,
                ),
                Divider(color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.2)),
                _buildSettingRow(
                  icon: CupertinoIcons.arrow_counterclockwise_circle_fill,
                  label: "Onboarding Flow",
                  value: "Restart",
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onRestartOnboarding?.call();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 120), // padding for floating glass nav bar
        ],
      ),
    );
  }

  Widget _buildStatCol(String val, String label, bool isDark) {
    return Column(
      children: [
        Text(val, style: GlassTheme.title(isDark: isDark).copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: GlassTheme.caption(isDark: isDark).copyWith(fontSize: 11)),
      ],
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: GlassTheme.iosBlue, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: GlassTheme.body(isDark: isDark).copyWith(fontSize: 15)),
            ),
            Text(value, style: GlassTheme.caption(isDark: isDark).copyWith(fontSize: 14, color: GlassTheme.iosBlue)),
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_right, color: Colors.white.withValues(alpha: 0.3), size: 16),
          ],
        ),
      ),
    );
  }
}

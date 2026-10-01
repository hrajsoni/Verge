import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/widgets/liquid_glass_card.dart';
import 'chat_screen.dart';

class ConversationItem {
  final String id;
  final String name;
  final String avatar;
  final String lastMessage;
  final String time;
  final bool hasUnopenedSnap;
  final int unreadCount;
  final int? streakDays;
  final int? streakHoursRemaining;
  final int? matchExpiresInHours;

  const ConversationItem({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    this.hasUnopenedSnap = false,
    this.unreadCount = 0,
    this.streakDays,
    this.streakHoursRemaining,
    this.matchExpiresInHours,
  });
}

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final List<ConversationItem> _conversations = [];
  bool _isLoading = false;

  final List<ConversationItem> _fallbackConversations = const [
    ConversationItem(
      id: "demo_1",
      name: "Sophia Vance",
      avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80",
      lastMessage: "New Snap received • Tap to view",
      time: "2m",
      hasUnopenedSnap: true,
      unreadCount: 1,
      streakDays: 8,
      streakHoursRemaining: 3, // Loss-aversion: 3h remaining to keep streak!
    ),
    ConversationItem(
      id: "demo_2",
      name: "Elena Rostova",
      avatar: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&auto=format&fit=crop&q=80",
      lastMessage: "Are you going to the exhibition tomorrow?",
      time: "1h",
      hasUnopenedSnap: false,
      unreadCount: 0,
      streakDays: 5,
      streakHoursRemaining: 16,
    ),
    ConversationItem(
      id: "demo_3",
      name: "Aria Chen",
      avatar: "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800&auto=format&fit=crop&q=80",
      lastMessage: "Sent you a playlist link!",
      time: "3h",
      hasUnopenedSnap: false,
      unreadCount: 0,
      matchExpiresInHours: 19, // Bumble 24h anti-ghosting match countdown
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().getConversations();
      if (res.data != null && res.data is List && (res.data as List).isNotEmpty) {
        final items = (res.data as List).map<ConversationItem>((raw) {
          final otherUser = raw['otherUser'] ?? {};
          final lastMsg = raw['lastMessage'] ?? {};
          return ConversationItem(
            id: raw['id'] ?? '',
            name: otherUser['displayName'] ?? 'New Friend',
            avatar: otherUser['avatarUrl'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
            lastMessage: lastMsg['isSnap'] == true
                ? 'Ephemeral Snap'
                : (lastMsg['text'] ?? 'Say hello!'),
            time: 'now',
            hasUnopenedSnap: lastMsg['isSnap'] == true,
            unreadCount: raw['unreadCount'] ?? 0,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _conversations.clear();
            _conversations.addAll(items);
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('[Conversations] Loaded offline fallback: $e');
    }

    if (mounted) {
      setState(() {
        _conversations.clear();
        _conversations.addAll(_fallbackConversations);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayList = _conversations.isNotEmpty ? _conversations : _fallbackConversations;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Messages", style: GlassTheme.headline(isDark: isDark)),
                GestureDetector(
                  onTap: _loadConversations,
                  child: ClipRRect(
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
                          _isLoading ? CupertinoIcons.arrow_2_circlepath : CupertinoIcons.square_pencil,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Matches Story Carousel with Bumble-style 24-hour Expiring Match Countdowns
          SizedBox(
            height: 104,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final item = displayList[index];
                final isExpiringMatch = item.matchExpiresInHours != null;

                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isExpiringMatch
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : const LinearGradient(
                                      colors: [GlassTheme.snapYellow, GlassTheme.iosPink, GlassTheme.iosPurple],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isExpiringMatch ? const Color(0xFFFB8500) : GlassTheme.snapYellow)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundImage: CachedNetworkImageProvider(item.avatar),
                            ),
                          ),
                          // Bumble-inspired Anti-Ghosting Match Countdown Badge
                          if (isExpiringMatch)
                            Positioned(
                              bottom: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFB8500),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white, width: 1.2),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(CupertinoIcons.timer, color: Colors.white, size: 9),
                                    const SizedBox(width: 2),
                                    Text(
                                      "${item.matchExpiresInHours}h",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.name.split(' ').first,
                        style: GlassTheme.caption(isDark: isDark).copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Conversations List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final item = displayList[index];
                final hasStreak = item.streakDays != null;
                final isStreakUrgent = item.streakHoursRemaining != null && item.streakHoursRemaining! <= 4;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LiquidGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    borderRadius: 22,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (_) => ChatScreen(
                            peerName: item.name,
                            peerAvatar: item.avatar,
                            conversationId: item.id,
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: CachedNetworkImageProvider(item.avatar),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        item.name,
                                        style: GlassTheme.title(isDark: isDark).copyWith(fontSize: 16),
                                      ),
                                      // Snapchat Streaks Engine (🔥 Daily Reciprocal Snaps)
                                      if (hasStreak) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isStreakUrgent
                                                ? Colors.deepOrange.withValues(alpha: 0.22)
                                                : Colors.orangeAccent.withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isStreakUrgent
                                                  ? Colors.deepOrange
                                                  : Colors.orangeAccent.withValues(alpha: 0.50),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text("🔥", style: TextStyle(fontSize: 11)),
                                              const SizedBox(width: 2),
                                              Text(
                                                "${item.streakDays}",
                                                style: TextStyle(
                                                  color: isStreakUrgent ? Colors.deepOrange : Colors.orangeAccent,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (isStreakUrgent) ...[
                                                const SizedBox(width: 4),
                                                Text(
                                                  "⏳ ${item.streakHoursRemaining}h",
                                                  style: const TextStyle(
                                                    color: Colors.deepOrangeAccent,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    item.time,
                                    style: GlassTheme.caption(isDark: isDark).copyWith(fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (item.hasUnopenedSnap) ...[
                                    const Icon(CupertinoIcons.bolt_fill, color: GlassTheme.snapYellow, size: 14),
                                    const SizedBox(width: 5),
                                  ],
                                  Expanded(
                                    child: Text(
                                      item.lastMessage,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GlassTheme.body(isDark: isDark).copyWith(
                                        fontSize: 13,
                                        fontWeight: item.hasUnopenedSnap ? FontWeight.w600 : FontWeight.w400,
                                        color: item.hasUnopenedSnap
                                            ? (isDark ? GlassTheme.snapYellow : const Color(0xFFB45309))
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

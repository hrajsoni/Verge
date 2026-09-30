import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  const ConversationItem({
    required this.id,
    required this.name,
    required this.avatar,
    required this.lastMessage,
    required this.time,
    this.hasUnopenedSnap = false,
    this.unreadCount = 0,
  });
}

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  final List<ConversationItem> _conversations = const [
    ConversationItem(
      id: "1",
      name: "Sophia Vance",
      avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800&auto=format&fit=crop&q=80",
      lastMessage: "New Snap received • Tap to view",
      time: "2m",
      hasUnopenedSnap: true,
      unreadCount: 1,
    ),
    ConversationItem(
      id: "2",
      name: "Elena Rostova",
      avatar: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800&auto=format&fit=crop&q=80",
      lastMessage: "Are you going to the exhibition tomorrow?",
      time: "1h",
      hasUnopenedSnap: false,
      unreadCount: 0,
    ),
    ConversationItem(
      id: "3",
      name: "Aria Chen",
      avatar: "https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800&auto=format&fit=crop&q=80",
      lastMessage: "Sent you a playlist link!",
      time: "3h",
      hasUnopenedSnap: false,
      unreadCount: 0,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.15 : 0.7)),
                      ),
                      child: Icon(
                        CupertinoIcons.square_pencil,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Matches Story Carousel
          SizedBox(
            height: 98,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final item = _conversations[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [GlassTheme.snapYellow, GlassTheme.iosPink, GlassTheme.iosPurple],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: GlassTheme.snapYellow.withOpacity(0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundImage: CachedNetworkImageProvider(item.avatar),
                        ),
                      ),
                      const SizedBox(height: 6),
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
              itemCount: _conversations.length,
              itemBuilder: (context, index) {
                final item = _conversations[index];
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
                                  Text(
                                    item.name,
                                    style: GlassTheme.title(isDark: isDark).copyWith(fontSize: 16),
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

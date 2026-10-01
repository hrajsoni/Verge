import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../network/api_client.dart';
import '../theme/glass_theme.dart';

enum NotificationType {
  snapReceived,
  mutualMatch,
  streakExpiring,
  screenshotAlert,
  general,
}

class InAppNotification {
  final String id;
  final String title;
  final String body;
  final String? avatarUrl;
  final NotificationType type;
  final VoidCallback? onTap;
  final DateTime timestamp;

  InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.avatarUrl,
    this.type = NotificationType.general,
    this.onTap,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _inAppNotificationController = StreamController<InAppNotification>.broadcast();
  Stream<InAppNotification> get onInAppNotification => _inAppNotificationController.stream;

  String? _pushToken;
  String? get pushToken => _pushToken;

  /// Register FCM / APNs Push Token with Be-Snap Backend
  Future<void> registerDeviceToken(String token, {String platform = 'ios'}) async {
    _pushToken = token;
    try {
      await ApiClient().post('/notifications/device-token', {
        'token': token,
        'platform': platform,
      });
      debugPrint('[NotificationService] Push token registered successfully: $token');
    } catch (e) {
      debugPrint('[NotificationService] Offline/fallback token registration: $e');
    }
  }

  /// Triggers a foreground in-app heads-up liquid banner
  void showHeadsUp(InAppNotification notification) {
    HapticFeedback.mediumImpact();
    _inAppNotificationController.add(notification);
  }

  void dispose() {
    _inAppNotificationController.close();
  }
}

/// Liquid Glass In-App Heads-Up Notification Banner Widget
class LiquidNotificationBannerOverlay extends StatefulWidget {
  final Widget child;

  const LiquidNotificationBannerOverlay({super.key, required this.child});

  @override
  State<LiquidNotificationBannerOverlay> createState() => _LiquidNotificationBannerOverlayState();
}

class _LiquidNotificationBannerOverlayState extends State<LiquidNotificationBannerOverlay>
    with SingleTickerProviderStateMixin {
  InAppNotification? _currentNotification;
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _dismissTimer;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    _sub = NotificationService().onInAppNotification.listen((notification) {
      _displayBanner(notification);
    });
  }

  void _displayBanner(InAppNotification notification) {
    _dismissTimer?.cancel();
    setState(() {
      _currentNotification = notification;
    });
    _animController.forward(from: 0.0);

    // Auto-dismiss after 4.5 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 4500), () {
      if (mounted) {
        _animController.reverse().then((_) {
          if (mounted) {
            setState(() => _currentNotification = null);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animController.dispose();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        widget.child,
        if (_currentNotification != null)
          Positioned(
            top: 0,
            left: 16,
            right: 16,
            child: SafeArea(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _currentNotification?.onTap?.call();
                      _animController.reverse();
                    },
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta != null && details.primaryDelta! < -8) {
                        _animController.reverse();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.65)
                                  : Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.70),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Icon or Avatar
                                if (_currentNotification?.avatarUrl != null)
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundImage: CachedNetworkImageProvider(
                                      _currentNotification!.avatarUrl!,
                                    ),
                                  )
                                else
                                  _buildTypeIcon(_currentNotification!.type),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _currentNotification!.title,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _currentNotification!.body,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDark ? Colors.white70 : Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  CupertinoIcons.chevron_forward,
                                  color: isDark ? Colors.white38 : Colors.black26,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeIcon(NotificationType type) {
    Color bg;
    IconData icon;
    switch (type) {
      case NotificationType.snapReceived:
        bg = GlassTheme.snapYellow;
        icon = CupertinoIcons.bolt_fill;
        break;
      case NotificationType.mutualMatch:
        bg = GlassTheme.iosPink;
        icon = CupertinoIcons.heart_fill;
        break;
      case NotificationType.streakExpiring:
        bg = Colors.deepOrangeAccent;
        icon = CupertinoIcons.flame_fill;
        break;
      case NotificationType.screenshotAlert:
        bg = Colors.redAccent;
        icon = CupertinoIcons.exclamationmark_triangle_fill;
        break;
      case NotificationType.general:
        bg = GlassTheme.iosBlue;
        icon = CupertinoIcons.bell_fill;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.20),
        shape: BoxShape.circle,
        border: Border.all(color: bg.withValues(alpha: 0.40)),
      ),
      child: Icon(icon, color: bg, size: 20),
    );
  }
}

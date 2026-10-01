import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/network/api_client.dart';
import '../../core/network/socket_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/widgets/liquid_mesh_background.dart';
import '../../core/widgets/liquid_snap_viewer.dart';

enum SnapState { unopened, opened, expired }

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final bool isSnap;
  final String? snapMediaUrl;
  final int snapDurationSeconds;
  SnapState snapState;
  final bool allowReplay;
  final bool isVoiceNote;
  final int voiceDurationSeconds;
  final bool isSystemAlert;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.isSnap = false,
    this.snapMediaUrl,
    this.snapDurationSeconds = 5,
    this.snapState = SnapState.unopened,
    this.allowReplay = false,
    this.isVoiceNote = false,
    this.voiceDurationSeconds = 8,
    this.isSystemAlert = false,
  });
}

class ChatScreen extends StatefulWidget {
  final String peerName;
  final String peerAvatar;
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.peerName,
    required this.peerAvatar,
    this.conversationId = "demo_conv_1",
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isPeerTyping = false;
  Timer? _typingDebounce;

  StreamSubscription? _msgSub;
  StreamSubscription? _typingSub;
  StreamSubscription? _stopTypingSub;
  StreamSubscription? _screenshotSub;

  @override
  void initState() {
    super.initState();
    // Default messages
    _messages.addAll([
      ChatMessage(
        id: "1",
        text: "Hey! Loved your photography snaps 📸",
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      ),
      ChatMessage(
        id: "2",
        text: "Thanks! Just took a new one with the vintage filter",
        isMe: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
      ),
      ChatMessage(
        id: "3",
        text: "Delivered Snap",
        isMe: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        isSnap: true,
        snapMediaUrl: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&auto=format&fit=crop&q=80",
        snapDurationSeconds: 5,
        snapState: SnapState.unopened,
        allowReplay: true,
      ),
    ]);

    // Connect to WebSocket room
    SocketService().joinConversation(widget.conversationId);

    _msgSub = SocketService().onNewMessage.listen((data) {
      if (data['conversationId'] == widget.conversationId && data['message'] != null) {
        final m = data['message'];
        final isSnap = m['snapViewDuration'] != null || m['isSnap'] == true;
        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                id: m['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                text: m['text'] ?? (isSnap ? '📸 Ephemeral Snap' : ''),
                isMe: false,
                timestamp: DateTime.tryParse(m['sentAt'] ?? '') ?? DateTime.now(),
                isSnap: isSnap,
                snapMediaUrl: m['media']?['objectKey'] ?? '',
                snapDurationSeconds: m['snapViewDuration'] ?? 5,
                snapState: SnapState.unopened,
                allowReplay: (m['snapMaxViews'] ?? 1) > 1,
              ),
            );
          });
          HapticFeedback.lightImpact();
        }
      }
    });

    _typingSub = SocketService().onUserTyping.listen((data) {
      if (data['conversationId'] == widget.conversationId && mounted) {
        setState(() => _isPeerTyping = true);
      }
    });

    _stopTypingSub = SocketService().onUserStopTyping.listen((data) {
      if (data['conversationId'] == widget.conversationId && mounted) {
        setState(() => _isPeerTyping = false);
      }
    });

    // Client-side Screenshot Snooping Listener
    _screenshotSub = SocketService().onScreenshotTaken.listen((data) {
      if (data['conversationId'] == widget.conversationId && mounted) {
        final alertText = "⚠️ Screenshot of ephemeral snap detected!";
        setState(() {
          _messages.add(
            ChatMessage(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              text: alertText,
              isMe: false,
              timestamp: DateTime.now(),
              isSystemAlert: true,
            ),
          );
        });
        NotificationService().showHeadsUp(
          InAppNotification(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: "Screenshot Detected",
            body: "${widget.peerName} took a screenshot of ephemeral snap!",
            avatarUrl: widget.peerAvatar,
            type: NotificationType.screenshotAlert,
          ),
        );
      }
    });

    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    SocketService().sendTyping(widget.conversationId);
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      SocketService().sendStopTyping(widget.conversationId);
    });
  }

  void _simulateScreenshotAlert() {
    HapticFeedback.heavyImpact();
    SocketService().sendScreenshotAlert(widget.conversationId);
  }

  void _sendVoiceNote() {
    HapticFeedback.mediumImpact();
    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: "Voice Note (0:08)",
      isMe: true,
      timestamp: DateTime.now(),
      isVoiceNote: true,
      voiceDurationSeconds: 8,
    );
    setState(() {
      _messages.add(newMsg);
    });
    ApiClient().sendMessage(
      conversationId: widget.conversationId,
      text: "Voice Note (0:08)",
    ).catchError((e) {
      debugPrint('[Chat] Voice note send: $e');
      return e;
    });
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _msgSub?.cancel();
    _typingSub?.cancel();
    _stopTypingSub?.cancel();
    _screenshotSub?.cancel();
    SocketService().leaveConversation(widget.conversationId);
    _textController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();

    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(newMsg);
      _textController.clear();
    });

    SocketService().sendStopTyping(widget.conversationId);

    ApiClient().sendMessage(
      conversationId: widget.conversationId,
      text: text,
    ).catchError((e) {
      debugPrint('[Chat] sendMessage fallback: $e');
      return e;
    });
  }

  Future<void> _captureAndSendSnap() async {
    HapticFeedback.heavyImpact();
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final uploadRes = await ApiClient().requestUploadUrl(
          mimeType: 'image/jpeg',
          type: 'SNAP',
          sizeBytes: bytes.length,
        );

        if (uploadRes.data != null && uploadRes.data['uploadUrl'] != null) {
          final presignedUrl = uploadRes.data['uploadUrl'] as String;
          final mediaId = uploadRes.data['mediaId'] as String;

          await ApiClient().uploadFileToS3(
            presignedUrl: presignedUrl,
            fileBytes: bytes,
            mimeType: 'image/jpeg',
          );

          await ApiClient().sendMessage(
            conversationId: widget.conversationId,
            mediaId: mediaId,
            snapDuration: 5,
            snapMaxViews: 2,
          );

          if (mounted) {
            setState(() {
              _messages.add(
                ChatMessage(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  text: "Delivered Snap",
                  isMe: true,
                  timestamp: DateTime.now(),
                  isSnap: true,
                  snapDurationSeconds: 5,
                  snapState: SnapState.unopened,
                  allowReplay: true,
                ),
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint('[Chat] Error sending snap: $e');
    }
  }

  void _openSnap(ChatMessage msg) async {
    if (msg.snapState == SnapState.expired) return;
    HapticFeedback.mediumImpact();

    String viewUrl = msg.snapMediaUrl ?? "";
    int duration = msg.snapDurationSeconds;
    bool canReplay = msg.allowReplay && msg.snapState == SnapState.opened;

    if (msg.id.length > 10) {
      try {
        final res = await ApiClient().openSnap(msg.id);
        if (res.data != null) {
          viewUrl = res.data['viewUrl'] ?? viewUrl;
          duration = res.data['durationSeconds'] ?? duration;
          canReplay = res.data['canReplay'] ?? canReplay;
        }
      } catch (e) {
        debugPrint('[Chat] openSnap API error: $e');
      }
    }

    if (!mounted) return;
    LiquidSnapViewer.show(
      context: context,
      mediaUrl: viewUrl.isNotEmpty
          ? viewUrl
          : "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&auto=format&fit=crop&q=80",
      durationSeconds: duration,
      senderName: widget.peerName,
      canReplay: canReplay,
      onFinished: () async {
        if (msg.id.length > 10) {
          try {
            await ApiClient().markSnapViewed(msg.id);
          } catch (e) {
            debugPrint('[Chat] markSnapViewed error: $e');
          }
        }
        if (mounted) {
          setState(() {
            if (msg.allowReplay && msg.snapState == SnapState.unopened) {
              msg.snapState = SnapState.opened;
            } else {
              msg.snapState = SnapState.expired;
            }
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LiquidMeshBackground(
        isDark: isDark,
        child: Column(
          children: [
            // iOS Frosted Glass Top Navigation Header
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 12,
                    left: 16,
                    right: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.65),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.6)),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(CupertinoIcons.chevron_back, color: GlassTheme.iosBlue, size: 28),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(widget.peerAvatar),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.peerName,
                              style: GlassTheme.title(isDark: isDark).copyWith(fontSize: 16),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF34C759),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _isPeerTyping ? "Typing..." : "Active now",
                                  style: GlassTheme.caption(isDark: isDark).copyWith(
                                    fontSize: 11,
                                    color: _isPeerTyping ? GlassTheme.snapYellow : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Simulated Screenshot Snooping Trigger
                      GestureDetector(
                        onTap: _simulateScreenshotAlert,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.40),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.shield_lefthalf_fill,
                            color: GlassTheme.snapYellow,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(CupertinoIcons.phone_fill, color: GlassTheme.iosBlue, size: 22),
                      const SizedBox(width: 14),
                      const Icon(CupertinoIcons.videocam_fill, color: GlassTheme.iosBlue, size: 26),
                    ],
                  ),
                ),
              ),
            ),

            // Message List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, isDark);
                },
              ),
            ),

            // iOS Liquid Glass Input Dock
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.70),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: isDark ? 0.22 : 0.8)),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _captureAndSendSnap,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: GlassTheme.snapYellow,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.camera_fill, color: Colors.black, size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Voice Note recording button
                          GestureDetector(
                            onTap: _sendVoiceNote,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: GlassTheme.iosPink,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.mic_fill, color: Colors.white, size: 18),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              style: GlassTheme.body(isDark: isDark),
                              decoration: InputDecoration(
                                hintText: "Send a chat or snap...",
                                hintStyle: GlassTheme.body(isDark: isDark).copyWith(
                                  color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.black38,
                                ),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _sendMessage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: GlassTheme.iosBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isDark) {
    if (msg.isSystemAlert) {
      return _buildSystemAlertBubble(msg);
    }

    if (msg.isVoiceNote) {
      return _buildVoiceNoteBubble(msg, isDark);
    }

    if (msg.isSnap) {
      return _buildSnapBubble(msg, isDark);
    }

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isMe ? 20 : 4),
            bottomRight: Radius.circular(msg.isMe ? 4 : 20),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: msg.isMe
                    ? GlassTheme.iosBlue.withValues(alpha: 0.82)
                    : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.70)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: msg.isMe ? 0.35 : (isDark ? 0.20 : 0.80)),
                ),
              ),
              child: Text(
                msg.text,
                style: GlassTheme.body(isDark: msg.isMe ? true : isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemAlertBubble(ChatMessage msg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.redAccent.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle_fill, color: Colors.redAccent, size: 14),
            const SizedBox(width: 6),
            Text(
              msg.text,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceNoteBubble(ChatMessage msg, bool isDark) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        child: _ChatVoiceNoteBubble(
          durationSeconds: msg.voiceDurationSeconds,
          isMe: msg.isMe,
          isDark: isDark,
        ),
      ),
    );
  }

  Widget _buildSnapBubble(ChatMessage msg, bool isDark) {
    Color bubbleColor;
    String statusText;
    IconData icon;

    switch (msg.snapState) {
      case SnapState.unopened:
        bubbleColor = GlassTheme.snapYellow;
        statusText = "Tap to view Snap (${msg.snapDurationSeconds}s)";
        icon = CupertinoIcons.bolt_fill;
        break;
      case SnapState.opened:
        bubbleColor = const Color(0xFF64D2FF);
        statusText = "Opened • Tap to replay";
        icon = CupertinoIcons.arrow_2_circlepath;
        break;
      case SnapState.expired:
        bubbleColor = Colors.grey;
        statusText = "Snap expired";
        icon = CupertinoIcons.eye_slash_fill;
        break;
    }

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => _openSnap(msg),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: bubbleColor.withValues(alpha: 0.75),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: bubbleColor.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bubbleColor.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: bubbleColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Ephemeral Snap",
                            style: GlassTheme.title(isDark: isDark).copyWith(fontSize: 13),
                          ),
                          Text(
                            statusText,
                            style: GlassTheme.caption(isDark: isDark).copyWith(
                              fontSize: 11,
                              color: bubbleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Interactive in-chat voice note bubble with dynamic animated waveform
class _ChatVoiceNoteBubble extends StatefulWidget {
  final int durationSeconds;
  final bool isMe;
  final bool isDark;

  const _ChatVoiceNoteBubble({
    required this.durationSeconds,
    required this.isMe,
    required this.isDark,
  });

  @override
  State<_ChatVoiceNoteBubble> createState() => _ChatVoiceNoteBubbleState();
}

class _ChatVoiceNoteBubbleState extends State<_ChatVoiceNoteBubble>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late AnimationController _controller;
  final List<double> _bars = const [
    0.3, 0.7, 0.4, 0.9, 1.0, 0.6, 0.3, 0.8,
    0.5, 0.9, 0.6, 0.4, 0.7, 0.5, 0.3,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isPlaying = false);
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) {
      _controller.forward();
    } else {
      _controller.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isMe
                ? GlassTheme.iosBlue.withValues(alpha: 0.82)
                : (widget.isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.70)),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: widget.isMe ? 0.35 : (widget.isDark ? 0.20 : 0.80)),
            ),
          ),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = _controller.value;
              final currentSec = (progress * widget.durationSeconds).round();

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                        color: widget.isMe ? GlassTheme.iosBlue : Colors.black87,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: List.generate(_bars.length, (idx) {
                      final barProgress = idx / _bars.length;
                      final isPlayed = progress >= barProgress;
                      final baseH = _bars[idx] * 22;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 3.0,
                        height: _isPlaying
                            ? (baseH + (isPlayed ? 3 : 0)).clamp(4.0, 24.0)
                            : baseH.clamp(4.0, 24.0),
                        decoration: BoxDecoration(
                          color: isPlayed
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.40),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "0:${currentSec.toString().padLeft(2, '0')}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}


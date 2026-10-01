import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  SocketConnectionState _state = SocketConnectionState.disconnected;
  SocketConnectionState get state => _state;
  bool get isConnected => _state == SocketConnectionState.connected;

  String? _host;
  String? _token;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelaySec = 30;

  // Offline outgoing message / event buffering queue
  final List<Map<String, dynamic>> _offlineQueue = [];

  // Stream Controllers for live events & connection states
  final _connectionStateController = StreamController<SocketConnectionState>.broadcast();
  final _newMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _userTypingController = StreamController<Map<String, dynamic>>.broadcast();
  final _userStopTypingController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesReadController = StreamController<Map<String, dynamic>>.broadcast();
  final _screenshotAlertController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<SocketConnectionState> get onConnectionStateChanged => _connectionStateController.stream;
  Stream<Map<String, dynamic>> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onUserTyping => _userTypingController.stream;
  Stream<Map<String, dynamic>> get onUserStopTyping => _userStopTypingController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _messagesReadController.stream;
  Stream<Map<String, dynamic>> get onScreenshotTaken => _screenshotAlertController.stream;

  void _setState(SocketConnectionState newState) {
    if (_state != newState) {
      _state = newState;
      _connectionStateController.add(_state);
      debugPrint('[SocketService] State transitioned to: $_state');
    }
  }

  void connect({
    String host = 'http://localhost:3000',
    required String token,
  }) {
    if (_socket != null && _state == SocketConnectionState.connected) return;

    _host = host;
    _token = token;
    _reconnectAttempts = 0;
    _reconnectTimer?.cancel();
    _setState(SocketConnectionState.connecting);

    _initSocket();
  }

  void _initSocket() {
    if (_token == null || _host == null) return;

    _socket?.dispose();
    _socket = io.io(
      _host!,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': _token})
          .setExtraHeaders({'Authorization': 'Bearer $_token'})
          .build(),
    );

    _socket?.onConnect((_) {
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      _setState(SocketConnectionState.connected);
      debugPrint('[SocketService] Connected to Be-Snap Real-Time Gateway');
      _flushOfflineQueue();
    });

    _socket?.onDisconnect((_) {
      _setState(SocketConnectionState.disconnected);
      debugPrint('[SocketService] Disconnected from Gateway');
      _scheduleReconnect();
    });

    _socket?.onConnectError((err) {
      _setState(SocketConnectionState.disconnected);
      debugPrint('[SocketService] Connection Error: $err');
      _scheduleReconnect();
    });

    // Gateway events
    _socket?.on('new_message', (data) {
      if (data is Map) {
        _newMessageController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('user_typing', (data) {
      if (data is Map) {
        _userTypingController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('user_stop_typing', (data) {
      if (data is Map) {
        _userStopTypingController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('messages_read', (data) {
      if (data is Map) {
        _messagesReadController.add(Map<String, dynamic>.from(data));
      }
    });

    // Client-side screenshot snooping event
    _socket?.on('screenshot_taken', (data) {
      if (data is Map) {
        _screenshotAlertController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.connect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _setState(SocketConnectionState.reconnecting);
    _reconnectAttempts++;

    // Exponential backoff: 2^(attempts-1) with jitter, capped at 30 seconds
    final exponentialDelay = math.min(
      math.pow(2, _reconnectAttempts - 1).toInt(),
      _maxReconnectDelaySec,
    );
    final jitter = math.Random().nextInt(1000);
    final delay = Duration(seconds: exponentialDelay, milliseconds: jitter);

    debugPrint('[SocketService] Reconnecting in ${delay.inMilliseconds}ms (Attempt #$_reconnectAttempts)...');
    _reconnectTimer = Timer(delay, () {
      if (_state != SocketConnectionState.connected) {
        _initSocket();
      }
    });
  }

  void _emitOrQueue(String event, Map<String, dynamic> data) {
    if (_socket?.connected == true && _state == SocketConnectionState.connected) {
      _socket?.emit(event, data);
    } else {
      debugPrint('[SocketService] Buffering offline outbound event: $event');
      _offlineQueue.add({'event': event, 'data': data});
    }
  }

  void _flushOfflineQueue() {
    if (_offlineQueue.isEmpty) return;
    debugPrint('[SocketService] Flushing ${_offlineQueue.length} offline buffered events...');
    final pending = List<Map<String, dynamic>>.from(_offlineQueue);
    _offlineQueue.clear();

    for (final item in pending) {
      final event = item['event'] as String;
      final data = item['data'] as Map<String, dynamic>;
      _socket?.emit(event, data);
    }
  }

  void joinConversation(String conversationId) {
    _emitOrQueue('join_conversation', {'conversationId': conversationId});
  }

  void leaveConversation(String conversationId) {
    _emitOrQueue('leave_conversation', {'conversationId': conversationId});
  }

  void sendTyping(String conversationId) {
    _emitOrQueue('typing', {'conversationId': conversationId});
  }

  void sendStopTyping(String conversationId) {
    _emitOrQueue('stop_typing', {'conversationId': conversationId});
  }

  void markMessageRead(String conversationId) {
    _emitOrQueue('message_read', {'conversationId': conversationId});
  }

  void sendScreenshotAlert(String conversationId) {
    _emitOrQueue('screenshot_taken', {'conversationId': conversationId});
    // Also trigger locally so current sender is notified immediately
    _screenshotAlertController.add({
      'conversationId': conversationId,
      'isLocal': true,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _setState(SocketConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _connectionStateController.close();
    _newMessageController.close();
    _userTypingController.close();
    _userStopTypingController.close();
    _messagesReadController.close();
    _screenshotAlertController.close();
  }
}

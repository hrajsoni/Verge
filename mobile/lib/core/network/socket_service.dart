import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Stream Controllers for live events
  final _newMessageController = StreamController<Map<String, dynamic>>.broadcast();
  final _userTypingController = StreamController<Map<String, dynamic>>.broadcast();
  final _userStopTypingController = StreamController<Map<String, dynamic>>.broadcast();
  final _messagesReadController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onUserTyping => _userTypingController.stream;
  Stream<Map<String, dynamic>> get onUserStopTyping => _userStopTypingController.stream;
  Stream<Map<String, dynamic>> get onMessagesRead => _messagesReadController.stream;

  void connect({
    String host = 'http://localhost:3000',
    required String token,
  }) {
    if (_socket != null && _isConnected) return;

    _socket = io.io(
      host,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket?.onConnect((_) {
      _isConnected = true;
      debugPrint('[SocketService] Connected to Be-Snap Real-Time Gateway');
    });

    _socket?.onDisconnect((_) {
      _isConnected = false;
      debugPrint('[SocketService] Disconnected from Gateway');
    });

    _socket?.onConnectError((err) {
      _isConnected = false;
      debugPrint('[SocketService] Connection Error: $err');
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

    _socket?.connect();
  }

  void joinConversation(String conversationId) {
    if (_socket?.connected == true) {
      _socket?.emit('join_conversation', {'conversationId': conversationId});
    }
  }

  void leaveConversation(String conversationId) {
    if (_socket?.connected == true) {
      _socket?.emit('leave_conversation', {'conversationId': conversationId});
    }
  }

  void sendTyping(String conversationId) {
    if (_socket?.connected == true) {
      _socket?.emit('typing', {'conversationId': conversationId});
    }
  }

  void sendStopTyping(String conversationId) {
    if (_socket?.connected == true) {
      _socket?.emit('stop_typing', {'conversationId': conversationId});
    }
  }

  void markMessageRead(String conversationId) {
    if (_socket?.connected == true) {
      _socket?.emit('message_read', {'conversationId': conversationId});
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _newMessageController.close();
    _userTypingController.close();
    _userStopTypingController.close();
    _messagesReadController.close();
  }
}

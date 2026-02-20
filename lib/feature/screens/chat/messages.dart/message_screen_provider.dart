import 'dart:async';

import 'package:chatloop/feature/screens/chat/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageScreenProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();
  late final String _currentUserId;

  // State Variables
  List<Map<String, dynamic>> _messages = [];
  final List<Map<String, dynamic>> _optimisticMessages = [];
  final Set<String> _deletedMessageIds = {};
  Map<String, dynamic>? _replyToMessage;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  bool _isLoading = true;
  String? _error;
  double _dragOffset = 0.0;

  // Getters
  List<Map<String, dynamic>> get messages {
    // Combine server messages and optimistic messages
    // Filter out deleted messages
    final serverMessages = _messages.where(
      (msg) => !_deletedMessageIds.contains(msg['id']),
    );

    final serverIds = serverMessages.map((m) => m['id']).toSet();

    // Only show optimistic messages that are NOT already in the server list
    final uniqueOptimistic = _optimisticMessages
        .where(
          (msg) =>
              !_deletedMessageIds.contains(msg['id']) &&
              !serverIds.contains(msg['id']),
        )
        .toList();

    return [...uniqueOptimistic.reversed, ...serverMessages];
  }

  Map<String, dynamic>? get replyToMessage => _replyToMessage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentUserId => _currentUserId;
  double get dragOffset => _dragOffset;

  // Initialization
  void init(String chatId) {
    _currentUserId = Supabase.instance.client.auth.currentUser!.id;
    _subscribeToMessages(chatId);
    _markAsSeen(chatId);
  }

  void updateDragOffset(double value) {
    _dragOffset = value;
    notifyListeners();
  }

  void _subscribeToMessages(String chatId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _messagesSubscription?.cancel();
    _messagesSubscription = _chatService
        .getMessagesStream(chatId)
        .listen(
          (data) {
            _messages = data;
            _isLoading = false;

            // Clean up optimistic messages that are now present in the server data
            // We can check by ID if we updated them, or older ones
            final serverIds = data.map((e) => e['id']).toSet();
            _optimisticMessages.removeWhere(
              (opt) => serverIds.contains(opt['id']),
            );

            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> _markAsSeen(String chatId) async {
    await _chatService.markMessagesAsSeen(chatId, _currentUserId);
  }

  // Actions
  void setReplyTo(Map<String, dynamic> message) {
    _replyToMessage = message;
    notifyListeners();
  }

  void clearReply() {
    _replyToMessage = null;
    notifyListeners();
  }

  Future<void> sendMessage(String chatId, String text) async {
    if (text.trim().isEmpty) return;

    final tempId = DateTime.now().toIso8601String();
    final optimisticMsg = {
      'id': tempId,
      'text': text.trim(),
      'sender_id': _currentUserId,
      'created_at': DateTime.now().toIso8601String(),
      'is_seen': false,
      'is_optimistic': true,
      if (_replyToMessage != null)
        'reply_to': _replyToMessage, // Store reply context if supported?
    };

    _optimisticMessages.add(optimisticMsg);
    // Clear reply after sending
    _replyToMessage = null;
    notifyListeners();

    try {
      // Send and get the real record back
      final realMessage = await _chatService.sendMessage(
        chatId,
        _currentUserId,
        text,
      );

      // Update local optimistic ID to real ID
      // This allows the getter to dedup once the stream catches up
      final index = _optimisticMessages.indexWhere((m) => m['id'] == tempId);
      if (index != -1) {
        _optimisticMessages[index] = {
          ..._optimisticMessages[index],
          'id': realMessage['id'], // Swap temp ID with real ID
          'created_at':
              realMessage['created_at'], // Sync time if server returns it
          'is_optimistic': false, // No longer optimistic technically
        };
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error sending message: $e');
      // Keep optimistic message or mark as error?
      // For now, remove it to avoid confusion or add error state.
      _optimisticMessages.removeWhere((m) => m['id'] == tempId);
      _error = "Failed to send message";
      notifyListeners();
    }
  }

  Future<void> unsendMessage(String messageId) async {
    // Add to deleted set for instant UI update
    _deletedMessageIds.add(messageId);

    // Also remove from optimistic if it exists there
    _optimisticMessages.removeWhere((m) => m['id'] == messageId);

    notifyListeners();

    try {
      await _chatService.removeMessage(messageId);
    } catch (e) {
      debugPrint('Error un-sending message: $e');
      // Undo deletion?
      _deletedMessageIds.remove(messageId);
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}

import 'dart:async';

import 'package:chatloop/feature/screens/chat/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatProvider extends ChangeNotifier {
  int _selectedTabIndex = 0;
  List<Map<String, dynamic>> _users = [];
  Map<String, Map<String, dynamic>> _userNotes = {}; // userId -> Note Data
  bool _isLoading = false;
  String? _errorMessage;

  int get selectedTabIndex => _selectedTabIndex;
  List<Map<String, dynamic>> get users => _users;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Get current user's note from the map
  String get currentUserNote {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return '';
    return _userNotes[uid]?['note_text'] ?? '';
  }

  // Get current user's song from the map
  Map<String, String>? get currentSong {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return null;
    final noteData = _userNotes[uid];
    if (noteData != null && noteData['song_title'] != null) {
      return {
        'title': noteData['song_title'],
        'artist': noteData['song_artist'] ?? '',
        'image': noteData['song_url'] ?? '',
      };
    }
    return null;
  }

  ChatProvider() {
    _fetchUsersAndNotes();
    subscribeToChats();
  }

  void setTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  // Save note to Supabase (Upsert logic)
  Future<void> saveNote(String noteText, Map<String, String>? song) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = {
        'user_id': userId,
        'note_text': noteText,
        'song_title': song?['title'],
        'song_artist': song?['artist'],
        'song_url': song?['image'],
        // 'created_at': DateTime.now().toIso8601String(), // Optional, default is now()
        // 'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(), // Optional, default is +24h
      };

      await supabase.from('notes').upsert(data, onConflict: 'user_id');

      // Update local state immediately for responsiveness
      _userNotes[userId] = data;
      notifyListeners();

      // Optionally refresh to get server-side timestamps if needed
      // _fetchUsersAndNotes();
    } catch (e) {
      debugPrint('Error saving note: $e');
      _errorMessage = 'Failed to save note: $e';
      notifyListeners();
    }
  }

  // Helper getters for UI to separate note/song updates
  // UI calls these, which then call saveNote
  void updateUserNote(String note) {
    saveNote(note, currentSong);
  }

  void updateCurrentSong(Map<String, String>? song) {
    saveNote(currentUserNote, song);
  }

  Map<String, dynamic>? getNoteForUser(String userId) {
    return _userNotes[userId];
  }

  Future<void> _fetchUsersAndNotes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        _users = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 1. Fetch Profiles
      final profilesResponse = await supabase
          .from('profiles')
          .select()
          .neq('id', currentUserId);
      _users = List<Map<String, dynamic>>.from(profilesResponse);

      // 2. Fetch Active Notes
      // Fetch ALL notes that haven't expired.
      // Note: We don't need to filter by user here if we want to show notes for users not in the profile list (though unlikely).
      // We rely on RLS `expires_at > now()` policy if set, or we filter manually.
      final notesResponse = await supabase
          .from('notes')
          .select()
          .gt('expire_at', DateTime.now().toIso8601String());

      final notesList = List<Map<String, dynamic>>.from(notesResponse);
      _userNotes.clear();
      for (var note in notesList) {
        _userNotes[note['user_id']] = note;
      }

      // Also fetch CURRENT USER'S note specifically if RLS hides it or loop above missed it (e.g. if we filtered).
      // But `notes` query above should get it if it's active.

      _errorMessage = null;
    } catch (e) {
      debugPrint('Error fetching data: $e');
      _errorMessage = 'Failed to load data: $e';
      // _users = []; // Keep old users if refresh fails?
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUsers() async {
    await Future.wait([_fetchUsersAndNotes(), subscribeToChats()]);
  }

  String getUserName(Map<String, dynamic> user) {
    return user['full_name'] ?? user['username'] ?? 'User';
  }

  String getUserAvatar(Map<String, dynamic> user) {
    String url =
        user['avatar_url'] ??
        user['photo_url'] ??
        user['photoUrl'] ??
        'https://i.pravatar.cc/150?u=${user['id']}';

    if (url.contains(',')) {
      url = url.split(',').first.trim();
    }
    return url;
  }
  // ... inside ChatProvider ...

  // Chat Integration
  final ChatService _chatService = ChatService();
  StreamSubscription<List<Map<String, dynamic>>>? _chatsSubscription;
  List<Map<String, dynamic>> _chats = [];
  List<Map<String, dynamic>> get chats => _chats;

  Future<void> subscribeToChats() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    _chatsSubscription?.cancel();

    // We start with loading state if empty
    if (_chats.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    _chatsSubscription = _chatService
        .getChatsStream(uid)
        .listen(
          (chatsData) async {
            try {
              // Enrich with profiles and last messages
              final enriched = await _chatService.enrichChats(chatsData, uid);
              _chats = enriched;
              _isLoading = false;
              _errorMessage = null;
              notifyListeners();
            } catch (e) {
              debugPrint('Error enriching chats in stream: $e');
            }
          },
          onError: (e) {
            debugPrint('Error in chats stream: $e');
            _errorMessage = 'Connection error: $e';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Deprecated one-time fetch, but we can keep it or alias it
  // Actually, let's just make loadMyChats call subscribeToChats to enforce streaming
  Future<void> loadMyChats() async {
    await subscribeToChats();
  }

  // Create chat from user selection
  Future<String?> startChat(String friendId) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      return await _chatService.getOrCreateChat(uid, friendId);
    } catch (e) {
      debugPrint('Error creating chat: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _chatsSubscription?.cancel();
    super.dispose();
  }
}

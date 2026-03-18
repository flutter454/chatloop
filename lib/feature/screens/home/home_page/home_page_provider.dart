import 'dart:convert';

import 'package:chatloop/feature/screens/chat/incoming_call_screen/incoming_call_screen.dart';
import 'package:chatloop/feature/screens/chat/video_call_screen/video_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePageProvider extends ChangeNotifier {
  Map? incomingCall;
  bool isCallScreenOpen = false;

  final supabase = Supabase.instance.client;
  HomePageProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Load likes
    final likedStr = prefs.getString('mock_liked_posts');
    if (likedStr != null) {
      _likedPostIds.addAll(List<String>.from(jsonDecode(likedStr)));
    }

    final likersStr = prefs.getString('mock_post_likers');
    if (likersStr != null) {
      final map = jsonDecode(likersStr) as Map<String, dynamic>;
      map.forEach((key, value) {
        _postLikers[key] = List<Map<String, dynamic>>.from(value);
      });
    }

    // Load comments
    final commentsStr = prefs.getString('mock_post_comments');
    if (commentsStr != null) {
      final map = jsonDecode(commentsStr) as Map<String, dynamic>;
      map.forEach((key, value) {
        _postComments[key] = List<Map<String, dynamic>>.from(value);
      });
    }

    notifyListeners();
  }

  Future<void> _saveLikesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('mock_liked_posts', jsonEncode(_likedPostIds.toList()));
    prefs.setString('mock_post_likers', jsonEncode(_postLikers));
  }

  Future<void> _saveCommentsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('mock_post_comments', jsonEncode(_postComments));
  }

  // ── Likes state ───────────────────────────────────────────────
  final Set<String> _likedPostIds = {};
  final Map<String, List<Map<String, dynamic>>> _postLikers = {};

  bool isLiked(String uri) => _likedPostIds.contains(uri);

  List<Map<String, dynamic>> getLikers(String uri) {
    if (!_postLikers.containsKey(uri)) {
      _postLikers[uri] = [];
    }
    return _postLikers[uri] ?? [];
  }

  void toggleLike(
    String uri, {
    required String currentUserId,
    required String userName,
    required String avatarUrl,
  }) {
    _postLikers[uri] ??= getLikers(uri);

    if (_likedPostIds.contains(uri)) {
      _likedPostIds.remove(uri);
      _postLikers[uri]!.removeWhere((u) => u['id'] == currentUserId);
    } else {
      _likedPostIds.add(uri);
      if (!_postLikers[uri]!.any((u) => u['id'] == currentUserId)) {
        _postLikers[uri]!.add({
          'id': currentUserId,
          'name': userName,
          'avatar': avatarUrl,
        });
      }
    }
    notifyListeners();
    _saveLikesToPrefs();
  }

  // ── Comments state ──────────────────────────────────────────────
  final Map<String, List<Map<String, dynamic>>> _postComments = {};

  List<Map<String, dynamic>> getComments(String uri) {
    if (!_postComments.containsKey(uri)) {
      _postComments[uri] = [];
    }
    return _postComments[uri] ?? [];
  }

  void addComment(
    String uri, {
    required String currentUserId,
    required String userName,
    required String avatarUrl,
    required String text,
  }) {
    _postComments[uri] ??= [];
    _postComments[uri]!.add({
      'id': currentUserId,
      'name': userName,
      'avatar': avatarUrl,
      'text': text,
      'timestamp': DateTime.now().toIso8601String(),
    });
    notifyListeners();
    _saveCommentsToPrefs();
  }

  void listenForIncomingCalls(BuildContext context) {
    final myId = supabase.auth.currentUser!.id;

    supabase
        .from('calls')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', myId)
        .listen((data) {
          if (data.isNotEmpty) {
            final call = data.last;

            if (call['status'] == 'calling' && !isCallScreenOpen) {
              incomingCall = call;
              isCallScreenOpen = true;
              notifyListeners();

              _showIncomingCall(context, call);
            }
          }
        });
  }

  void _showIncomingCall(BuildContext context, Map call) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callData: call,
          onAccept: () => acceptCall(context, call),
          onReject: () => rejectCall(context, call['id']),
        ),
      ),
    ).then((_) {
      isCallScreenOpen = false;
    });
  }

  Future<void> acceptCall(BuildContext context, Map call) async {
    await supabase
        .from('calls')
        .update({'status': 'accepted'})
        .eq('id', call['id']);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoCallScreen(channelName: call['channel_id']),
      ),
    );
  }

  Future<void> rejectCall(BuildContext context, String callId) async {
    await supabase
        .from('calls')
        .update({'status': 'rejected'})
        .eq('id', callId);

    Navigator.pop(context);
  }
}

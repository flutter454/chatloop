import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePageProvider extends ChangeNotifier {
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

  final List<Map<String, String>> _stories = [
    {'name': 'Sree', 'image': 'https://i.pravatar.cc/150?u=1'},
    {'name': 'Chenna', 'image': 'https://i.pravatar.cc/150?u=2'},
    {'name': 'littel', 'image': 'https://i.pravatar.cc/150?u=3'},
    {'name': 'sreenadh', 'image': 'https://i.pravatar.cc/150?u=4'},
  ];

  final List<Map<String, String>> _posts = [
    {
      'user': 'lil_wyatt838',
      'avatar': 'https://i.pravatar.cc/150?u=5',
      'image': 'https://picsum.photos/id/1011/800/800',
      'caption': 'Spending time with the squad! 📸',
    },
    {
      'user': 'adventure_seeker',
      'avatar': 'https://i.pravatar.cc/150?u=6',
      'image': 'https://picsum.photos/id/1015/800/800',
      'caption': 'The view from up here is incredible. ⛰️',
    },
    {
      'user': 'urban_explorer',
      'avatar': 'https://i.pravatar.cc/150?u=7',
      'image': 'https://picsum.photos/id/1016/800/800',
      'caption': 'City lights and late nights. 🌃',
    },
  ];

  List<Map<String, String>> get stories => _stories;
  List<Map<String, String>> get posts => _posts;

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
}

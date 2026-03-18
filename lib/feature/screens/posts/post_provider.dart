import 'dart:convert';
import 'dart:io';

import 'package:chatloop/core/services/sharedpreference.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/post_model.dart';

/// Lightweight cache so we don't re-fetch the same profile in a session.
final Map<String, Map<String, dynamic>> _profileCache = {};

class PostProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Upload state ──────────────────────────────────────────────
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  // ── Likes state ───────────────────────────────────────────────
  final Set<String> _likedPostIds = {};
  final Map<String, List<Map<String, dynamic>>> _postLikers = {};

  bool isLiked(String postId) => _likedPostIds.contains(postId);

  List<Map<String, dynamic>> getLikers(String postId) {
    if (!_postLikers.containsKey(postId)) {
      _postLikers[postId] = [];
    }
    return _postLikers[postId] ?? [];
  }

  Future<void> toggleLike(
    String postId, {
    required String currentUserId,
    required String userName,
    required String avatarUrl,
  }) async {
    _postLikers[postId] ??= [];

    final isLiking = !_likedPostIds.contains(postId);

    // Optimistic UI update
    if (isLiking) {
      _likedPostIds.add(postId);
      if (!_postLikers[postId]!.any((u) => u['id'] == currentUserId)) {
        _postLikers[postId]!.add({
          'id': currentUserId,
          'name': userName,
          'avatar': avatarUrl,
        });
      }
    } else {
      _likedPostIds.remove(postId);
      _postLikers[postId]!.removeWhere((u) => u['id'] == currentUserId);
    }
    notifyListeners();

    try {
      if (isLiking) {
        await _supabase.from('post_likes').insert({
          'post_id': int.parse(postId),
          'user_id': currentUserId,
        });
      } else {
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', int.parse(postId))
            .eq('user_id', currentUserId);
      }
    } catch (e) {
      debugPrint(
        '⚠️ Failed to toggle like in Supabase (did you create post_likes table?): $e',
      );
    }
  }

  // ── Comments state ──────────────────────────────────────────────
  final Map<String, List<Map<String, dynamic>>> _postComments = {};

  List<Map<String, dynamic>> getComments(String postId) {
    if (!_postComments.containsKey(postId)) {
      _postComments[postId] = [];
    }
    return _postComments[postId] ?? [];
  }

  Future<void> addComment(
    String postId, {
    required String currentUserId,
    required String userName,
    required String avatarUrl,
    required String text,
  }) async {
    final timestamp = DateTime.now().toIso8601String();

    // Optimistic UI update
    _postComments[postId] ??= [];
    _postComments[postId]!.add({
      'id': currentUserId,
      'name': userName,
      'avatar': avatarUrl,
      'text': text,
      'timestamp': timestamp,
    });
    notifyListeners();

    try {
      await _supabase.from('post_comments').insert({
        'post_id': int.parse(postId),
        'user_id': currentUserId,
        'text': text,
      });
    } catch (e) {
      debugPrint(
        '⚠️ Failed to add comment in Supabase (did you create post_comments table?): $e',
      );
    }
  }

  // ── Fetch Likes & Comments ──────────────────────────────────────
  Future<void> _fetchLikesAndComments(List<int> postIds) async {
    if (postIds.isEmpty) return;
    
    // Initialize caches for these posts
    for (final id in postIds) {
      if (!_postLikers.containsKey(id.toString())) {
        _postLikers[id.toString()] = [];
      } else {
        _postLikers[id.toString()]!.clear();
      }
      
      if (!_postComments.containsKey(id.toString())) {
        _postComments[id.toString()] = [];
      } else {
        _postComments[id.toString()]!.clear();
      }
    }

    final currentUserId = _supabase.auth.currentUser?.id;

    // ── 1. Fetch Likes ──────────────────────────────────────────
    try {
      List<dynamic> likesList = [];
      try {
        final response = await _supabase
            .from('post_likes')
            .select('post_id, user_id, profiles(full_name, username, avatar_url)')
            .inFilter('post_id', postIds);
        likesList = response as List<dynamic>;
      } catch (e) {
        debugPrint('⚠️ Likes profile join failed, fetching without profiles: $e');
        final response = await _supabase
            .from('post_likes')
            .select('*')
            .inFilter('post_id', postIds);
        likesList = response as List<dynamic>;
      }

      _likedPostIds.clear();

      for (final like in likesList) {
        final map = like as Map<String, dynamic>;
        if (!map.containsKey('post_id') || !map.containsKey('user_id')) continue;
        
        final postId = map['post_id'].toString();
        final profile = map['profiles'] as Map<String, dynamic>?;
        final likerId = map['user_id'].toString();
        
        String name = profile?['full_name'] ?? 'User';
        String avatar = profile?['avatar_url'] ?? '';
        
        if (profile == null && _profileCache.containsKey(likerId)) {
           name = _profileCache[likerId]!['full_name'] ?? 'User';
           avatar = _profileCache[likerId]!['avatar_url'] ?? '';
        }

        _postLikers[postId]?.add({
          'id': likerId,
          'name': name,
          'avatar': avatar,
        });

        if (likerId == currentUserId) {
          _likedPostIds.add(postId);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Absolute failure in fetching likes: $e');
    }

    // ── 2. Fetch Comments ───────────────────────────────────────
    try {
      List<dynamic> commentsList = [];
      try {
        final response = await _supabase
            .from('post_comments')
            .select('id, post_id, user_id, text, created_at, profiles(full_name, username, avatar_url)')
            .inFilter('post_id', postIds)
            .order('created_at', ascending: true);
        commentsList = response as List<dynamic>;
      } catch (e) {
        debugPrint('⚠️ Comments profile join failed: $e');
        try {
          final response = await _supabase
              .from('post_comments')
              .select('*')
              .inFilter('post_id', postIds)
              .order('created_at', ascending: true);
          commentsList = response as List<dynamic>;
        } catch (innerE) {
           debugPrint('⚠️ Comments fallback failed with order, trying without: $innerE');
           final response = await _supabase
              .from('post_comments')
              .select('*')
              .inFilter('post_id', postIds);
           commentsList = response as List<dynamic>;
        }
      }

      for (final comment in commentsList) {
        final map = comment as Map<String, dynamic>;
        if (!map.containsKey('post_id') || !map.containsKey('user_id')) continue;

        final postId = map['post_id'].toString();
        final profile = map['profiles'] as Map<String, dynamic>?;
        final commenterId = map['user_id'].toString();

        String name = profile?['full_name'] ?? 'User';
        String avatar = profile?['avatar_url'] ?? '';
        
        if (profile == null && _profileCache.containsKey(commenterId)) {
           name = _profileCache[commenterId]!['full_name'] ?? 'User';
           avatar = _profileCache[commenterId]!['avatar_url'] ?? '';
        }

        _postComments[postId]?.add({
          'id': commenterId,
          'name': name,
          'avatar': avatar,
          'text': map['text'] ?? '',
          'timestamp': map['created_at'] ?? DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('⚠️ Absolute failure in fetching comments: $e');
    }
  }

  // ── Feed state ────────────────────────────────────────────────
  List<PostModel> _posts = [];
  List<PostModel> get posts => _posts;

  bool _isFeedLoading = false;
  bool get isFeedLoading => _isFeedLoading;

  String? _feedError;
  String? get feedError => _feedError;

  /// True once we have successfully loaded posts at least once.
  /// Used to skip the network fetch on subsequent screen visits.
  bool _hasFetchedOnce = false;
  bool get hasPosts => _hasFetchedOnce && _posts.isNotEmpty;

  // ── Bucket name (PRIVATE) ─────────────────────────────────────
  static const String _bucket = 'userposts';

  // Signed URL validity in seconds (1 hour)
  static const int _signedUrlExpiry = 3600;

  // ═════════════════════════════════════════════════════════════
  //  UPLOAD POST
  // ═════════════════════════════════════════════════════════════
  Future<void> uploadPost({
    required File file,
    required String caption,
    required bool isVideo,
    required String userName,
    required String userAvatarUrl,
    required VoidCallback onSuccess,
    required Function(String) onError,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      onError('User not logged in');
      return;
    }

    try {
      _isUploading = true;
      notifyListeners();

      // ── Step 1: Build the storage path ───────────────────────
      final String fileExt = file.path.split('.').last.toLowerCase();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String originalName = file.path.split(Platform.pathSeparator).last;
      final String storagePath = '${user.id}/${timestamp}_$originalName';
      final String mediaType = isVideo ? 'video' : 'image';

      debugPrint('─── POST UPLOAD START ───');
      debugPrint('📁 File: ${file.path}');
      debugPrint('📏 File size: ${file.lengthSync()} bytes');
      debugPrint('📤 Storage path: $_bucket/$storagePath');
      debugPrint('🎞️ Media type: $mediaType');

      // ── Step 2: Upload file to PRIVATE bucket ────────────────
      final String uploadResult;
      try {
        uploadResult = await _supabase.storage
            .from(_bucket)
            .upload(
              storagePath,
              file,
              fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: isVideo ? 'video/$fileExt' : 'image/$fileExt',
              ),
            );
        debugPrint('✅ Upload complete. Result: $uploadResult');
      } catch (uploadError) {
        debugPrint('❌ Storage upload FAILED: $uploadError');
        rethrow;
      }

      // ── Step 3: Generate signed URL ──────────────────────────
      // For private buckets, we generate a temporary signed URL.
      // We store `storage_path` in DB and regenerate signed URLs
      // when fetching posts (best practice for private buckets).
      final String signedUrl;
      try {
        signedUrl = await _supabase.storage
            .from(_bucket)
            .createSignedUrl(storagePath, _signedUrlExpiry);
        debugPrint('🔗 Signed URL generated: $signedUrl');
      } catch (urlError) {
        debugPrint('❌ Signed URL generation FAILED: $urlError');
        rethrow;
      }

      // ── Step 4: Validate before insert ───────────────────────
      if (signedUrl.isEmpty) {
        throw Exception('Signed URL is empty – cannot insert post');
      }

      debugPrint('🔍 Pre-insert validation:');
      debugPrint('   user_id      = ${user.id}');
      debugPrint('   storage_path = $storagePath');
      debugPrint('   media_url    = $storagePath');
      debugPrint('   media_type   = $mediaType');
      debugPrint('   caption      = $caption');

      // ── Step 5: Insert post record into `usersposts` table ───
      // First, upsert the profile so that friends can see the correct name
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'username': userName, // fallback
          'avatar_url': userAvatarUrl,
        });
        debugPrint('👤 Profile upserted successfully!');
      } catch (upsertError) {
        debugPrint('⚠️ Profile upsert FAILED (ignoring): $upsertError');
      }

      // IMPORTANT: Include `media_url` because the column has a
      // NOT NULL constraint. We store the storage_path (not the
      // signed URL) since signed URLs expire.
      try {
        await _supabase.from('usersposts').insert({
          'user_id': user.id,
          'storage_path': storagePath,
          'media_url':
              storagePath, // ← THIS WAS MISSING — caused the 23502 error
          'media_type': mediaType,
          'caption': caption,
          'created_at': DateTime.now().toIso8601String(),
        });
        debugPrint('💾 Post saved to database successfully!');
      } catch (dbError) {
        debugPrint('❌ Database insert FAILED: $dbError');
        // Try to clean up the uploaded file if DB insert fails
        try {
          await _supabase.storage.from(_bucket).remove([storagePath]);
          debugPrint('🧹 Cleaned up orphaned storage file');
        } catch (cleanupError) {
          debugPrint('⚠️ Cleanup failed: $cleanupError');
        }
        rethrow;
      }

      debugPrint('─── POST UPLOAD COMPLETE ───');

      _isUploading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      _isUploading = false;
      notifyListeners();
      debugPrint('❌ Upload error: $e');
      onError(e.toString());
    }
  }

  // ═════════════════════════════════════════════════════════════
  //  FETCH POSTS (Feed)
  //  Best practice for private buckets: store storage_path in DB,
  //  regenerate signed URLs when fetching.
  // ═════════════════════════════════════════════════════════════
  /// Loads posts from Supabase only when needed.
  /// Pass [forceRefresh: true] to bypass the cache (used by pull-to-refresh,
  /// upload success and delete).
  Future<void> fetchPosts({bool forceRefresh = false}) async {
    final String cacheKey = 'cached_posts';

    if (!_hasFetchedOnce && !forceRefresh) {
      if (_posts.isEmpty) {
        try {
          final cachedStr = PreferenceService.getString(cacheKey);
          if (cachedStr != null) {
            final List<dynamic> decoded = jsonDecode(cachedStr);
            _posts = decoded.map((e) => PostModel.fromJsonMap(Map<String, dynamic>.from(e))).toList();
            _isFeedLoading = false;
            _hasFetchedOnce = true;
            notifyListeners();
            debugPrint('📦 Instantly loaded ${_posts.length} posts from cache');
          } else {
             _isFeedLoading = true;
             notifyListeners();
          }
        } catch (e) {
          debugPrint('⚠️ Failed to load cached posts: $e');
          _isFeedLoading = true;
          notifyListeners();
        }
      }
    }

    // ── Use cache if we already have data and caller didn't ask to refresh ──
    if (!forceRefresh && _hasFetchedOnce && _posts.isNotEmpty && !_isFeedLoading) {
      // Allow background updating but dont block UI
      debugPrint('📦 Using cached posts and fetching in background');
    }

    try {
      _feedError = null;
      // We do not set _isFeedLoading to true if we already have cached points to prevent UI flashing
      if (_posts.isEmpty) {
        _isFeedLoading = true;
      }
      notifyListeners();

      // Try fetching with profile join first, fallback to plain query
      List<dynamic> data;
      try {
        final response = await _supabase
            .from('usersposts')
            .select('*, profiles(full_name, username, avatar_url)')
            .order('created_at', ascending: false);
        data = response as List<dynamic>;
      } catch (e) {
        debugPrint('⚠️ Profile join failed, fetching without profiles: $e');
        final response = await _supabase
            .from('usersposts')
            .select('*')
            .order('created_at', ascending: false);
        data = response as List<dynamic>;
      }

      debugPrint('📦 Raw posts fetched: ${data.length}');

      // Parse into PostModel list
      final List<PostModel> fetchedPosts = [];
      for (final item in data) {
        try {
          fetchedPosts.add(PostModel.fromMap(item as Map<String, dynamic>));
        } catch (e) {
          debugPrint('⚠️ Failed to parse post: $e — data: $item');
        }
      }

      // ── Generate signed URLs for each post ───────────────────
      // One-by-one with error handling so one bad path doesn't
      // kill the whole feed.
      for (final post in fetchedPosts) {
        if (post.storagePath.isEmpty) {
          debugPrint('⚠️ Post ${post.id} has empty storage path, skipping');
          continue;
        }
        // Skip if storagePath looks like a full URL (old data from public bucket)
        if (post.storagePath.startsWith('http')) {
          post.signedUrl = post.storagePath;
          debugPrint('ℹ️ Post ${post.id} using direct URL (old data)');
          continue;
        }
        try {
          final signedUrl = await _supabase.storage
              .from(_bucket)
              .createSignedUrl(post.storagePath, _signedUrlExpiry);
          post.signedUrl = signedUrl;
          debugPrint('✅ Post ${post.id} signed URL OK');
        } catch (e) {
          debugPrint(
            '❌ Post ${post.id} signed URL failed for '
            'path="${post.storagePath}": $e',
          );
          post.signedUrl = null; // will show broken image icon
        }
      }

      // ── Attach user profiles if missing ────────────────────
      await _attachUserProfiles(fetchedPosts);

      // ── Fetch user likes and comments ──────────────────────
      final postIds = fetchedPosts.map((p) => p.id).toList();
      await _fetchLikesAndComments(postIds);

      _posts = fetchedPosts;
      _hasFetchedOnce = true;
      _isFeedLoading = false;

      // Save to cache memory to show up quickly immediately next time
      try {
        final List<Map<String, dynamic>> cacheData = _posts.map((p) => p.toJsonMap()).toList();
        PreferenceService.saveString(cacheKey, jsonEncode(cacheData));
      } catch (e) {
         debugPrint('⚠️ Error saving cached posts: $e');
      }

      notifyListeners();

      debugPrint(
        '📰 Fetched ${_posts.length} posts, '
        '${_posts.where((p) => p.signedUrl != null).length} with valid URLs',
      );
    } catch (e) {
      _isFeedLoading = false;
      _feedError = e.toString();
      notifyListeners();
      debugPrint('❌ Feed fetch error: $e');
    }
  }

  // ═════════════════════════════════════════════════════════════
  //  ATTACH USER PROFILES
  //  Fallback for when the Supabase join doesn't work (no FK).
  //  Fetches profiles for any post that has null userName.
  // ═════════════════════════════════════════════════════════════
  Future<void> _attachUserProfiles(List<PostModel> posts) async {
    // Collect user IDs that still need profile info
    final Set<String> missingIds = {};
    for (final post in posts) {
      if (post.userName == null || post.userName!.isEmpty) {
        if (!_profileCache.containsKey(post.userId)) {
          missingIds.add(post.userId);
        }
      }
    }

    if (missingIds.isEmpty && posts.every((p) => p.userName != null)) {
      debugPrint('👤 All posts already have profile info');
      return;
    }

    // Fetch missing profiles from the profiles table
    if (missingIds.isNotEmpty) {
      try {
        final response = await _supabase
            .from('profiles')
            .select('id, full_name, username, avatar_url')
            .inFilter('id', missingIds.toList());

        final profilesList = response as List<dynamic>;
        for (final p in profilesList) {
          final map = p as Map<String, dynamic>;
          _profileCache[map['id'] as String] = map;
        }
        debugPrint('👤 Fetched ${profilesList.length} user profiles');
      } catch (e) {
        debugPrint('⚠️ Failed to fetch user profiles: $e');
      }
    }

    // Attach cached profile data to posts that are missing it
    for (final post in posts) {
      if (post.userName == null || post.userName!.isEmpty) {
        final profile = _profileCache[post.userId];
        if (profile != null) {
          post.userName = (profile['full_name'] as String?)?.isNotEmpty == true
              ? profile['full_name'] as String?
              : profile['username'] as String?;
          post.userAvatarUrl = profile['avatar_url'] as String?;
        }
      }
    }
  }

  // ═════════════════════════════════════════════════════════════
  //  REFRESH SIGNED URL (for a single post, e.g. if expired)
  // ═════════════════════════════════════════════════════════════
  Future<String?> refreshSignedUrl(String storagePath) async {
    if (storagePath.isEmpty) return null;
    if (storagePath.startsWith('http')) return storagePath;
    try {
      final url = await _supabase.storage
          .from(_bucket)
          .createSignedUrl(storagePath, _signedUrlExpiry);
      debugPrint('🔄 Refreshed signed URL for: $storagePath');
      return url;
    } catch (e) {
      debugPrint('❌ Refresh signed URL failed: $e');
      return null;
    }
  }

  // ═════════════════════════════════════════════════════════════
  //  DELETE POST
  // ═════════════════════════════════════════════════════════════
  Future<void> deletePost(PostModel post) async {
    try {
      // 1. Delete from storage (wrapped in try-catch so it doesn't block DB delete)
      if (!post.storagePath.startsWith('http') && post.storagePath.isNotEmpty) {
        try {
          await _supabase.storage.from(_bucket).remove([post.storagePath]);
          debugPrint('🗑️ Storage file deleted: ${post.storagePath}');
        } catch (storageError) {
          debugPrint('⚠️ Storage delete failed (ignored): $storageError');
        }
      }

      // 2. Delete from database
      await _supabase.from('usersposts').delete().eq('id', post.id);

      // 3. Remove from cached local list immediately (no full re-fetch needed)
      _posts.removeWhere((p) => p.id == post.id);
      notifyListeners();

      debugPrint('🗑️ Post deleted: ${post.id}');
    } catch (e) {
      debugPrint('❌ Delete error: $e');
      rethrow; // Let the UI show an error snackbar
    }
  }

  // ═════════════════════════════════════════════════════════════
  //  CLEAR CACHE  (call after upload so new post appears)
  // ═════════════════════════════════════════════════════════════
  void clearPostsCache() {
    _hasFetchedOnce = false;
    debugPrint('🗑️ Posts cache cleared — next fetchPosts will hit Supabase');
  }
}

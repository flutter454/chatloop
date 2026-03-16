import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chatloop/core/services/sharedpreference.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'package:chatloop/core/models/story_model.dart';

class StoryProvider extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  List<StoryData> _myStories = [];
  List<List<StoryData>> _friendStories = [];
  Timer? _storyTimer;
  Timer? _fetchTimer;
  RealtimeChannel? _subscription;

  List<StoryData> get myStories => List.unmodifiable(_myStories);
  List<List<StoryData>> get friendStories => List.unmodifiable(_friendStories);
  StoryData? get myStory => _myStories.isNotEmpty ? _myStories.last : null;

  StoryProvider() {
    _loadStoriesFromPrefs();
    fetchStories();
    _subscribeToStories();
    // Auto-refresh stories periodically (e.g., every minute) as backup to realtime
    _fetchTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => fetchStories(),
    );
  }

  void _subscribeToStories() {
    _subscription = Supabase.instance.client
        .channel('public:stories')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stories',
          callback: (payload) {
            debugPrint('Realtime update received: ${payload.eventType}');
            fetchStories();
          },
        )
        .subscribe();
  }

  Future<void> _loadStoriesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    final storiesJson = prefs.getStringList('my_stories');

    // Legacy support: check for single 'my_story' if 'my_stories' is empty
    if (storiesJson == null && prefs.containsKey('my_story')) {
      final legacyStory = prefs.getString('my_story');
      if (legacyStory != null) {
        try {
          final storyData = StoryData.fromMap(jsonDecode(legacyStory));
          // Only load if belongs to current user or if current user is not set (legacy/anonymous)
          if ((currentUserId == null || storyData.userId == currentUserId) &&
              await _isValidStory(storyData)) {
            _myStories.add(storyData);
            _saveStoriesToPrefs();
          }
        } catch (e) {
          debugPrint('Error loading legacy story: $e');
        }
      }
      prefs.remove('my_story'); // Clear legacy
    }

    if (storiesJson != null) {
      final List<StoryData> activeStories = [];
      for (String jsonStr in storiesJson) {
        try {
          var storyData = StoryData.fromMap(jsonDecode(jsonStr));
          // Strict user ID check for privacy
          if (currentUserId != null && storyData.userId != currentUserId) {
            continue;
          }
          if (await _isValidStory(storyData)) {
            // Validate/Regenerate thumbnail
            if (storyData.type == StoryMediaType.video &&
                storyData.thumbnailPath == null &&
                storyData.file != null) {
              // ... (Thumbnail regeneration logic same as before if needed)
            }
            activeStories.add(storyData);
          }
        } catch (e) {
          debugPrint('Error loading story: $e');
        }
      }
      _myStories = activeStories;
      notifyListeners();
    }
  }

  Future<bool> _isValidStory(StoryData storyData) async {
    final bool isValid =
        DateTime.now().difference(storyData.timestamp).inHours < 24;

    // If file is null (remote story), we rely on timestamp validity
    if (storyData.file == null) return isValid;

    final bool fileExists = await storyData.file!.exists();
    return isValid && fileExists;
  }

  // Instead of a timer per story, we run a check periodically or schedule next expiry
  void _startExpiryCheck() {
    _storyTimer?.cancel();
    if (_myStories.isEmpty) return;

    _myStories.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    // Check closest expiry
    final oldestStory = _myStories.first;
    final remainingTime =
        const Duration(days: 1) -
        DateTime.now().difference(oldestStory.timestamp);

    if (remainingTime.inSeconds > 0) {
      _storyTimer = Timer(remainingTime, () {
        _removeExpiredStories();
      });
    } else {
      _removeExpiredStories();
    }
  }

  Future<void> _removeExpiredStories() async {
    final now = DateTime.now();
    _myStories.removeWhere(
      (story) => now.difference(story.timestamp).inHours >= 24,
    );
    await _saveStoriesToPrefs();
    notifyListeners();
    if (_myStories.isNotEmpty) _startExpiryCheck();
  }

  Future<void> _saveStoriesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> storiesJson = _myStories
        .map((s) => jsonEncode(s.toMap()))
        .toList();
    if (storiesJson.isEmpty) {
      await prefs.remove('my_stories');
    } else {
      await prefs.setStringList('my_stories', storiesJson);
    }
  }

  Future<XFile?> pickStoryMedia(
    BuildContext context,
    ImageSource source,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasSeenDialog =
        prefs.getBool('hasSeenStoryPermissionDialog') ?? false;

    if (!hasSeenDialog) {
      final bool? proceed = await _showPermissionExplanationDialog(context);
      if (proceed != true) return null;
      await prefs.setBool('hasSeenStoryPermissionDialog', true);
    }

    // Directly pick media (images or videos) from the gallery
    return await _picker.pickMedia();
  }

  Future<void> createStory(
    File file,
    StoryMediaType type, {
    String? caption,
    String? overlayText,
    double? overlayX,
    double? overlayY,
    String? musicName,
    String? musicUrl,
    String? musicCover,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = await PreferenceService.getString('userId') ?? 'anonymous';
    String? thumbnailPath;
    String? userPhoto = await PreferenceService.getString('photoUrl');

    // Prefer public URL from Supabase Auth metadata if available
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.userMetadata != null) {
        final metaPhoto =
            user.userMetadata?['avatar_url'] ?? user.userMetadata?['photo_url'];
        if (metaPhoto != null && metaPhoto.toString().startsWith('http')) {
          userPhoto = metaPhoto.toString();
        }
      }
    } catch (_) {}

    // Generate thumbnail first (local operation, fast)
    if (type == StoryMediaType.video) {
      try {
        final tempDir = await getTemporaryDirectory();
        thumbnailPath = await VideoThumbnail.thumbnailFile(
          video: file.path,
          thumbnailPath: tempDir.path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 100,
          quality: 75,
        );
      } catch (e) {
        debugPrint('Error generating thumbnail: $e');
      }
    }

    // Create local story first for immediate UI response
    final timestamp = DateTime.now();

    // Get real user name
    String userName = prefs.getString('name') ?? 'Your Story';
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.userMetadata != null) {
        userName =
            user.userMetadata?['full_name'] ??
            user.userMetadata?['username'] ??
            userName;
      }
    } catch (_) {}

    final localStory = StoryData(
      userId: userId,
      file: file,
      type: type,
      timestamp: timestamp,
      userName: userName,
      caption: caption,
      thumbnailPath: thumbnailPath,
      overlayText: overlayText,
      overlayX: overlayX,
      overlayY: overlayY,
      musicName: musicName,
      musicUrl: musicUrl,
      musicCover: musicCover,
      mediaUrl: null, // No URL yet
      userPhoto: userPhoto,
      thumbnailUrl: null, // No URL yet
    );

    _myStories.add(localStory);
    notifyListeners();
    // Save locally immediately so it persists even if upload fails or app closes
    await _saveStoriesToPrefs();
    _startExpiryCheck();

    // Upload to Supabase
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      final rawFileName = file.path.split(Platform.pathSeparator).last;
      // Sanitize filename: remove spaces, special chars
      final fileName = rawFileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

      // Path format: <uid>/<timestamp>_<filename>
      final storagePath =
          '$userId/${timestamp.millisecondsSinceEpoch}_$fileName';

      debugPrint('Starting upload to bucket "stories" at path: $storagePath');

      // Determine content type
      String contentType = 'application/octet-stream';
      final ext = fileName.split('.').last.toLowerCase();

      switch (ext) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        case 'mp4':
          contentType = 'video/mp4';
          break;
        case 'mov':
          contentType = 'video/quicktime';
          break;
        case 'avi':
          contentType = 'video/x-msvideo';
          break;
      }

      // 1. Upload File (Relies on RLS Policy: INSERT/UPDATE for owner)
      await supabase.storage
          .from('stories')
          .upload(
            storagePath,
            file,
            fileOptions: FileOptions(
              cacheControl: '3600',
              upsert: false,
              contentType: contentType,
            ),
          );

      String? remoteThumbnailUrl;
      // Upload thumbnail if available
      if (thumbnailPath != null) {
        try {
          final thumbFile = File(thumbnailPath);
          final thumbName = thumbFile.path.split(Platform.pathSeparator).last;
          final thumbStoragePath =
              '$userId/${timestamp.millisecondsSinceEpoch}_thumb_$thumbName';

          await supabase.storage
              .from('stories')
              .upload(
                thumbStoragePath,
                thumbFile,
                fileOptions: const FileOptions(
                  cacheControl: '3600',
                  upsert: false,
                  contentType: 'image/jpeg',
                ),
              );
          remoteThumbnailUrl = await supabase.storage
              .from('stories')
              .createSignedUrl(thumbStoragePath, 60 * 60 * 24 * 365);
        } catch (e) {
          debugPrint('Error uploading thumbnail: $e');
        }
      }

      debugPrint('Upload successful to: $storagePath');

      // 2. Get Media URL (Relies on Signed URL for Private Buckets)
      // We set a long expiry (1 year) because the DB 'expire_at' controls visibility logic,
      // and we want the link to work as long as the record exists.
      final mediaUrl = await supabase.storage
          .from('stories')
          .createSignedUrl(storagePath, 60 * 60 * 24 * 365);

      // 3. Save Record in Database
      await supabase.from('stories').insert({
        'user_id': userId,
        'user_name': userName,
        'media_url': mediaUrl,
        'media_type': type == StoryMediaType.video ? 'video' : 'image',
        // Use UTC for server consistency
        'created_at': timestamp.toUtc().toIso8601String(),
        // DB controls visibility via expire_at
        'expire_at': timestamp
            .toUtc()
            .add(const Duration(hours: 24))
            .toIso8601String(),
        'user_photo': userPhoto,
        'caption': caption,
        'music_name': musicName,
        'music_url': musicUrl,
        'music_cover': musicCover,
        'overlay_text': overlayText,
        'overlay_x': overlayX,
        'overlay_y': overlayY,
        'thumbnail_url': remoteThumbnailUrl,
      });

      debugPrint('Story record inserted into DB ✅');

      // Update story with the URL
      final index = _myStories.indexOf(localStory);
      if (index != -1) {
        final updatedStory = StoryData(
          userId: localStory.userId,
          file: localStory.file,
          type: localStory.type,
          timestamp: localStory.timestamp,
          userName: localStory.userName,
          caption: localStory.caption,
          thumbnailPath: localStory.thumbnailPath,
          overlayText: localStory.overlayText,
          overlayX: localStory.overlayX,
          overlayY: localStory.overlayY,
          musicName: localStory.musicName,
          musicUrl: localStory.musicUrl,
          musicCover: localStory.musicCover,
          mediaUrl: mediaUrl,
          userPhoto: localStory.userPhoto,
          thumbnailUrl: remoteThumbnailUrl,
        );
        _myStories[index] = updatedStory;
        await _saveStoriesToPrefs();
        notifyListeners();
      }
      // No need to manual fetch if realtime is fast enough, but explicit fetch is safe
      // fetchStories();
    } catch (e) {
      debugPrint('Error uploading to Supabase: $e');
      // If upload fails, we still have the local story which is fine
    }
  }

  Future<List<StoryData>> fetchAllMyStories() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId =
          supabase.auth.currentUser?.id ??
          await PreferenceService.getString('userId') ??
          '';

      if (currentUserId.isEmpty) return [];

      // Fetch all stories for the current user (no expiry filter)
      final response = await supabase
          .from('stories')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      final List<StoryData> allStories = [];

      for (var item in data) {
        try {
          // Regenerate fresh signed URLs so thumbnails always load
          final String? freshMediaUrl = await _refreshSignedUrl(
            supabase,
            item['media_url'],
            'stories',
          );
          final String? freshThumbUrl = await _refreshSignedUrl(
            supabase,
            item['thumbnail_url'],
            'stories',
          );

          final story = StoryData(
            userId: item['user_id'] ?? '',
            userName: item['user_name'] ?? 'Unknown',
            file: null,
            type: item['media_type'] == 'video'
                ? StoryMediaType.video
                : StoryMediaType.image,
            timestamp: DateTime.parse(item['created_at']).toLocal(),
            mediaUrl: freshMediaUrl ?? item['media_url'],
            userPhoto: item['user_photo'],
            caption: item['caption'],
            musicName: item['music_name'],
            musicUrl: item['music_url'],
            musicCover: item['music_cover'],
            overlayText: item['overlay_text'],
            overlayX: item['overlay_x'] != null
                ? (item['overlay_x'] as num).toDouble()
                : null,
            overlayY: item['overlay_y'] != null
                ? (item['overlay_y'] as num).toDouble()
                : null,
            thumbnailUrl: freshThumbUrl ?? item['thumbnail_url'],
          );
          allStories.add(story);
        } catch (e) {
          debugPrint('Error parsing story item: $e');
        }
      }
      return allStories;
    } catch (e) {
      debugPrint('Error fetching all my stories: $e');
      return [];
    }
  }

  /// Extracts the storage path from a Supabase signed URL and generates a fresh one.
  Future<String?> _refreshSignedUrl(
    SupabaseClient supabase,
    dynamic storedUrl,
    String bucket,
  ) async {
    if (storedUrl == null || storedUrl.toString().isEmpty) return null;
    try {
      final uri = Uri.parse(storedUrl.toString());
      // Supabase signed URL path format:
      // /storage/v1/object/sign/<bucket>/<path...>
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(bucket);
      if (bucketIndex == -1 || bucketIndex >= segments.length - 1) {
        return storedUrl.toString();
      }
      final filePath = segments.sublist(bucketIndex + 1).join('/');
      // Generate a fresh 1-year signed URL
      final freshUrl = await supabase.storage
          .from(bucket)
          .createSignedUrl(filePath, 60 * 60 * 24 * 365);
      return freshUrl;
    } catch (e) {
      debugPrint('Could not refresh signed URL: $e');
      return storedUrl.toString(); // Fall back to old URL
    }
  }


  Future<void> fetchStories() async {
    try {
      final supabase = Supabase.instance.client;
      // PRIORITIZE Supabase Auth ID as it matches the DB "user_id" column strictly
      final currentUserId =
          supabase.auth.currentUser?.id ??
          await PreferenceService.getString('userId') ??
          '';

      // 1. Fetch ALL stories first
      final response = await supabase
          .from('stories')
          .select()
          .order('created_at', ascending: true);

      final List<dynamic> data = response;
      debugPrint('-------- DATABASE CONTENT CHECK --------');
      debugPrint('Total Stories Found in Table: ${data.length}');
      for (var item in data) {
        debugPrint(
          'Story: User=${item['user_name']} | Time=${item['created_at']} | Valid? ${DateTime.now().difference(DateTime.parse(item['created_at']).toLocal()).inHours < 25}',
        );
      }
      debugPrint('----------------------------------------');

      final Map<String, List<StoryData>> grouped = {};
      final List<StoryData> serverMyStories = [];
      final now = DateTime.now();

      for (var item in data) {
        try {
          // 2. Parse Data
          final story = StoryData(
            userId: item['user_id'] ?? '',
            userName: item['user_name'] ?? 'Unknown',
            file: null, // Remote story
            type: item['media_type'] == 'video'
                ? StoryMediaType.video
                : StoryMediaType.image,
            timestamp: DateTime.parse(item['created_at']).toLocal(),
            mediaUrl: item['media_url'],
            userPhoto: item['user_photo'],
            caption: item['caption'],
            musicName: item['music_name'],
            musicUrl: item['music_url'],
            musicCover: item['music_cover'],
            overlayText: item['overlay_text'],
            overlayX: item['overlay_x'] != null
                ? (item['overlay_x'] as num).toDouble()
                : null,
            overlayY: item['overlay_y'] != null
                ? (item['overlay_y'] as num).toDouble()
                : null,
            thumbnailUrl: item['thumbnail_url'],
          );

          // 3. Expiry Check (25 hours to be safe against small time drifts)
          if (now.difference(story.timestamp).inHours >= 25) {
            continue;
          }

          // 4. Grouping
          if (story.userId == currentUserId) {
            serverMyStories.add(story);
          } else {
            if (!grouped.containsKey(story.userId)) {
              grouped[story.userId] = [];
            }
            grouped[story.userId]!.add(story);
          }
        } catch (e) {
          debugPrint('Error parsing story item: $e');
          continue; // Skip bad item
        }
      }

      // Sync My Stories (Merge Logic)
      final Set<String> localMediaUrls = _myStories
          .where((s) => s.mediaUrl != null)
          .map((s) => s.mediaUrl!)
          .toSet();

      for (var s in serverMyStories) {
        if (s.mediaUrl != null && !localMediaUrls.contains(s.mediaUrl)) {
          _myStories.add(s);
        }
      }

      // Sort and Deduplicate
      _myStories.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Sort groups by the timestamp of their latest story (Descending)
      final groups = grouped.entries.toList();
      groups.sort((a, b) {
        final aLast = a.value.last.timestamp;
        final bLast = b.value.last.timestamp;
        return bLast.compareTo(aLast);
      });

      _friendStories = groups.map((e) => e.value).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching stories: $e');
    }
  }

  Future<void> deleteStory(StoryData story) async {
    // Delete from Supabase if mediaUrl exists
    if (story.mediaUrl != null && story.mediaUrl!.isNotEmpty) {
      try {
        final supabase = Supabase.instance.client;

        // Extract path from URL
        final uri = Uri.parse(story.mediaUrl!);
        final segments = uri.pathSegments;
        final bucketIndex = segments.indexOf('stories');

        if (bucketIndex != -1 && bucketIndex < segments.length - 1) {
          final filePath = segments.sublist(bucketIndex + 1).join('/');
          await supabase.storage.from('stories').remove([filePath]);
          debugPrint('Deleted $filePath from Supabase Storage ✅');

          try {
            await supabase.from('stories').delete().match({
              'media_url': story.mediaUrl!,
            });
            debugPrint('Deleted from stories table ✅');
          } catch (e) {
            debugPrint('Error deleting from stories table (optional): $e');
          }
        }
      } catch (e) {
        debugPrint('Error deleting from Supabase: $e ❌');
      }
    }

    _myStories.remove(story);
    await _saveStoriesToPrefs();
    _startExpiryCheck();
    notifyListeners();
  }

  Future<void> deleteAllMyStories() async {
    final storiesToDelete = List<StoryData>.from(_myStories);
    for (var story in storiesToDelete) {
      await deleteStory(story);
    }
  }

  Future<void> clearStory() async {
    _myStories.clear();
    _friendStories.clear();
    _storyTimer?.cancel();
    _fetchTimer?.cancel();
    _subscription?.unsubscribe();
    _subscription = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('my_stories');
    await prefs.remove('my_story');
    notifyListeners();
  }

  Future<void> refresh() async {
    _myStories.clear();
    _friendStories.clear();
    notifyListeners();

    await _loadStoriesFromPrefs();
    fetchStories();

    // Re-subscribe
    _subscription?.unsubscribe();
    _subscribeToStories();

    _fetchTimer?.cancel();
    _fetchTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => fetchStories(),
    );
  }

  @override
  void dispose() {
    _storyTimer?.cancel();
    _fetchTimer?.cancel();
    _subscription?.unsubscribe();
    super.dispose();
  }

  Future<bool> _showPermissionExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.photo_library, color: Colors.blue),
                  SizedBox(width: 10),
                  Text('Gallery Access'),
                ],
              ),
              content: const Text(
                'ChatLoop needs access to your gallery to let you choose photos and videos for your stories. This allows you to share moments with your friends!',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'CANCEL',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("OK, LET'S GO"),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}

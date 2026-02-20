import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  Future<void> uploadPost({
    required File file,
    required String caption,
    required bool isVideo,
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

      // 1. Upload File to Storage
      final String fileExt = file.path.split('.').last;
      final String fileName =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      await _supabase.storage
          .from('posts')
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      // 2. Get Public URL
      final String mediaUrl = _supabase.storage
          .from('posts')
          .getPublicUrl(fileName);

      // 3. Insert into Database
      await _supabase.from('posts').insert({
        'user_id': user.id,
        'media_url': mediaUrl,
        'media_type': isVideo ? 'video' : 'image',
        'caption': caption,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      _isUploading = false;
      notifyListeners();
      onSuccess();
    } catch (e) {
      _isUploading = false;
      notifyListeners();
      onError(e.toString());
    }
  }
}

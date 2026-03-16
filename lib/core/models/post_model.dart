class PostModel {
  final int id;
  final String userId;
  final String storagePath; // path inside the bucket (userId/timestamp_file)
  final String mediaType; // 'image' or 'video'
  final String caption;
  final DateTime createdAt;

  // Populated after fetching signed URL
  String? signedUrl;

  // Joined from profiles table (optional) — mutable so the provider
  // can attach profile data when the Supabase join isn't available.
  String? userName;
  String? userAvatarUrl;

  PostModel({
    required this.id,
    required this.userId,
    required this.storagePath,
    required this.mediaType,
    required this.caption,
    required this.createdAt,
    this.signedUrl,
    this.userName,
    this.userAvatarUrl,
  });

  bool get isVideo => mediaType == 'video';

  factory PostModel.fromMap(Map<String, dynamic> map) {
    // Handle joined profile data if present
    final profile = map['profiles'];

    // Support both old 'media_url' column and new 'storage_path' column
    String path = '';
    if (map['storage_path'] != null) {
      path = map['storage_path'] as String;
    } else if (map['media_url'] != null) {
      // Old data: extract the path from the full URL
      // e.g. "https://xxx.supabase.co/storage/v1/object/public/posts/userId/file.jpg"
      // → "userId/file.jpg"
      final fullUrl = map['media_url'] as String;
      final bucketPrefixes = [
        '/object/public/posts/',
        '/object/public/userposts/',
      ];
      for (final prefix in bucketPrefixes) {
        final idx = fullUrl.indexOf(prefix);
        if (idx != -1) {
          path = fullUrl.substring(idx + prefix.length);
          break;
        }
      }
      // If we couldn't extract, use the raw value
      if (path.isEmpty) path = fullUrl;
    }

    return PostModel(
      id: map['id'] is int ? map['id'] as int : int.parse(map['id'].toString()),
      userId: map['user_id'] as String,
      storagePath: path,
      mediaType: map['media_type'] as String? ?? 'image',
      caption: (map['caption'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      userName: profile != null 
          ? ((profile['username'] as String?)?.isNotEmpty == true
              ? profile['username'] as String?
              : profile['full_name'] as String?)
          : null,
      userAvatarUrl: profile != null ? profile['avatar_url'] as String? : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'storage_path': storagePath,
      'media_url': storagePath, // NOT NULL column — store path, not signed URL
      'media_type': mediaType,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

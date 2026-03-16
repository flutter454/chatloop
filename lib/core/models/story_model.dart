import 'dart:io';

enum StoryMediaType { image, video }

class StoryData {
  final String userId;
  final File? file;
  final StoryMediaType type;
  final DateTime timestamp;
  final String userName;
  final String? caption;
  final String? thumbnailPath;
  final String? overlayText;
  final double? overlayX;
  final double? overlayY;
  final String? musicName;
  final String? musicUrl;
  final String? musicCover;
  final String? mediaUrl;
  final String? userPhoto;
  final String? thumbnailUrl;

  StoryData({
    this.userId = '',
    this.file,
    required this.type,
    required this.timestamp,
    required this.userName,
    this.caption,
    this.thumbnailPath,
    this.overlayText,
    this.overlayX,
    this.overlayY,
    this.musicName,
    this.musicUrl,
    this.musicCover,
    this.mediaUrl,
    this.userPhoto,
    this.thumbnailUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'path': file?.path ?? '',
      'type': type.index,
      'timestamp': timestamp.toIso8601String(),
      'userName': userName,
      'caption': caption,
      'thumbnailPath': thumbnailPath,
      'overlayText': overlayText,
      'overlayX': overlayX,
      'overlayY': overlayY,
      'musicName': musicName,
      'musicUrl': musicUrl,
      'musicCover': musicCover,
      'mediaUrl': mediaUrl,
      'userPhoto': userPhoto,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  factory StoryData.fromMap(Map<String, dynamic> map) {
    return StoryData(
      userId: map['userId'] ?? '',
      file: (map['path'] != null && map['path'].isNotEmpty)
          ? File(map['path'])
          : null,
      type: StoryMediaType.values[map['type']],
      timestamp: DateTime.parse(map['timestamp']),
      userName: map['userName'] ?? 'Your Story',
      caption: map['caption'],
      thumbnailPath: map['thumbnailPath'],
      overlayText: map['overlayText'],
      overlayX: map['overlayX'],
      overlayY: map['overlayY'],
      musicName: map['musicName'],
      musicUrl: map['musicUrl'],
      musicCover: map['musicCover'],
      mediaUrl: map['mediaUrl'],
      userPhoto: map['userPhoto'],
      thumbnailUrl: map['thumbnailUrl'],
    );
  }
}

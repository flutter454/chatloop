class HighlightModel {
  final String id;
  final String name;
  final String coverUrl;
  final List<String> mediaUrls;
  final List<String> mediaTypes;     // 'image' or 'video' per entry
  final List<String> thumbnailUrls;  // thumbnail per entry (empty string if none)

  HighlightModel({
    required this.id,
    required this.name,
    required this.coverUrl,
    required this.mediaUrls,
    List<String>? mediaTypes,
    List<String>? thumbnailUrls,
  }) : mediaTypes = mediaTypes ?? List.filled(mediaUrls.length, 'image'),
       thumbnailUrls = thumbnailUrls ?? List.filled(mediaUrls.length, '');

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'coverUrl': coverUrl,
    'mediaUrls': mediaUrls,
    'mediaTypes': mediaTypes,
    'thumbnailUrls': thumbnailUrls,
  };

  factory HighlightModel.fromMap(Map<String, dynamic> map) {
    final urls = List<String>.from(map['mediaUrls'] ?? []);
    return HighlightModel(
      id: map['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: map['name'] ?? 'Highlight',
      coverUrl: map['coverUrl'] ?? '',
      mediaUrls: urls,
      mediaTypes: map['mediaTypes'] != null
          ? List<String>.from(map['mediaTypes'])
          : List.filled(urls.length, 'image'),
      thumbnailUrls: map['thumbnailUrls'] != null
          ? List<String>.from(map['thumbnailUrls'])
          : List.filled(urls.length, ''),
    );
  }
}

import 'package:chatloop/core/models/highlight_model.dart';
import 'package:chatloop/core/models/story_model.dart';
import 'package:chatloop/feature/screens/home/story/story_provider.dart';
import 'package:chatloop/feature/screens/profile/highlights/highlights_service.dart';
import 'package:flutter/material.dart';

class StoryArchiveProvider extends ChangeNotifier {
  final StoryProvider _storyProvider = StoryProvider();

  List<StoryData> _allStories = [];
  bool _isLoading = true;
  String? _error;

  final Set<int> _selectedIndices = {};
  bool _selectionMode = false;

  List<StoryData> get allStories => _allStories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<int> get selectedIndices => _selectedIndices;
  bool get selectionMode => _selectionMode;

  StoryArchiveProvider() {
    fetchStories();
  }

  Future<void> fetchStories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allStories = await _storyProvider.fetchAllMyStories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void enterSelectMode(int flatIndex) {
    _selectionMode = true;
    _selectedIndices.add(flatIndex);
    notifyListeners();
  }

  void toggleSelect(int flatIndex) {
    if (_selectedIndices.contains(flatIndex)) {
      _selectedIndices.remove(flatIndex);
      if (_selectedIndices.isEmpty) _selectionMode = false;
    } else {
      _selectedIndices.add(flatIndex);
    }
    notifyListeners();
  }

  void cancelSelection() {
    _selectedIndices.clear();
    _selectionMode = false;
    notifyListeners();
  }

  Future<bool> createHighlight(String name) async {
    final selected = _selectedIndices.map((i) => _allStories[i]).toList();
    if (selected.isEmpty) return false;

    // Build the cover URL — first selected story's thumbnail/mediaUrl
    final coverStory = selected.first;
    final coverUrl =
        (coverStory.type == StoryMediaType.image
            ? coverStory.mediaUrl
            : (coverStory.thumbnailUrl ?? coverStory.mediaUrl)) ??
        '';

    final mediaUrls = <String>[];
    final mediaTypes = <String>[];
    final thumbnailUrls = <String>[];

    for (final s in selected) {
      if (s.mediaUrl != null && s.mediaUrl!.isNotEmpty) {
        mediaUrls.add(s.mediaUrl!);
        mediaTypes.add(s.type == StoryMediaType.video ? 'video' : 'image');
        thumbnailUrls.add(s.thumbnailUrl ?? '');
      }
    }

    final highlight = HighlightModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      coverUrl: coverUrl,
      mediaUrls: mediaUrls,
      mediaTypes: mediaTypes,
      thumbnailUrls: thumbnailUrls,
    );

    await HighlightsService.add(highlight);

    _selectedIndices.clear();
    _selectionMode = false;
    notifyListeners();

    return true;
  }
}

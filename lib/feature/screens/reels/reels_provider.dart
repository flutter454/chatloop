import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelsProvider extends ChangeNotifier {
  int _currentIndex = 0;
  final Map<String, VideoPlayerController> _controllers = {};
  final Set<String> _initializingIds = {};

  int get currentIndex => _currentIndex;

  VideoPlayerController? getController(String postId) => _controllers[postId];

  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  Future<void> initializeController(String postId, String url) async {
    if (_controllers.containsKey(postId) || _initializingIds.contains(postId)) {
      return;
    }

    _initializingIds.add(postId);
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));

    try {
      await controller.initialize();
      controller.setLooping(true);
      _controllers[postId] = controller;
      _initializingIds.remove(postId);
      notifyListeners();
    } catch (e) {
      debugPrint("Error initializing video $postId: $e");
      _initializingIds.remove(postId);
    }
  }

  void togglePlayPause(String postId) {
    final controller = _controllers[postId];
    if (controller != null) {
      if (controller.value.isPlaying) {
        controller.pause();
      } else {
        controller.play();
      }
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  void reset() {
    _currentIndex = 0;
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _initializingIds.clear();
    notifyListeners();
  }
}

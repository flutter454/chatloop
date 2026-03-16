import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:chatloop/core/models/story_model.dart';

class StoryViewProvider extends ChangeNotifier {
  List<StoryData> _stories = [];
  int _currentIndex = 0;

  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;

  // Progress management
  double _progress = 0.0;
  Timer? _progressTimer;
  Duration _duration = const Duration(seconds: 5);

  bool _isInitialized = false;
  bool _hasError = false;
  bool _isDisposed = false;
  bool _isPaused = false;
  bool _isHighlight = false;

  // Getters
  int get currentIndex => _currentIndex;
  List<StoryData> get stories => _stories;
  StoryData get currentStory => _stories[_currentIndex];
  VideoPlayerController? get videoController => _videoController;
  bool get isInitialized => _isInitialized;
  bool get hasError => _hasError;
  double get progress => _progress;
  bool get isHighlight => _isHighlight;

  void init(List<StoryData> stories, int initialIndex, {bool isHighlight = false}) {
    _stories = stories;
    _currentIndex = initialIndex;
    _isHighlight = isHighlight;
    _loadStory();
  }

  Future<void> _loadStory() async {
    _isInitialized = false;
    _hasError = false;
    _progress = 0.0;
    _cancelTimer();
    // Dispose old controller
    final oldController = _videoController;
    _videoController = null;
    oldController?.dispose();

    _handleMusicStop();

    notifyListeners(); // UI shows loading

    if (_currentIndex >= _stories.length) return;

    final story = _stories[_currentIndex];

    // Handle Music
    await _handleMusic(story);
    if (_isDisposed) return;

    if (story.type == StoryMediaType.video) {
      if (story.mediaUrl != null && story.mediaUrl!.isNotEmpty) {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(story.mediaUrl!),
        );
      } else if (story.file != null) {
        _videoController = VideoPlayerController.file(story.file!);
      }

      if (_videoController != null) {
        try {
          await _videoController!.initialize();
          if (_isDisposed) return;
          _isInitialized = true;

          final videoDuration = _videoController!.value.duration;
          // Cap video stories at 30s
          _duration = videoDuration > const Duration(seconds: 30)
              ? const Duration(seconds: 30)
              : videoDuration;

          if (!_isPaused) {
            _videoController!.play();
            _startProgressTimer();
          }

          notifyListeners();
        } catch (e) {
          if (_isDisposed) return;
          debugPrint("Error initializing video: $e");
          _hasError = true;
          _isInitialized = true;
          notifyListeners();
        }
      } else {
        // Error: No URL or File provided for video
        _hasError = true;
        _isInitialized = true;
        notifyListeners();
      }
    } else {
      // Image
      _isInitialized = true;
      _duration = const Duration(seconds: 5);
      // Original code was 15s
      _duration = const Duration(seconds: 15);

      if (!_isPaused) {
        _startProgressTimer();
      }
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  void _startProgressTimer() {
    _cancelTimer();
    const tick = Duration(milliseconds: 50); // Updates 20 times a second
    // Use microseconds for better precision if needed, but ms is fine
    int totalTicks = _duration.inMilliseconds ~/ tick.inMilliseconds;
    if (totalTicks <= 0) totalTicks = 1;
    int currentTick = 0;

    _progressTimer = Timer.periodic(tick, (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      currentTick++;
      _progress = currentTick / totalTicks;
      if (_progress >= 1.0) {
        _progress = 1.0;
        _cancelTimer();
        _notifyStoryFinished();
      } else {
        notifyListeners();
      }
    });
  }

  void _cancelTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  // Helper to notify specifically that story finished so we can decide what to do
  void _notifyStoryFinished() {
    notifyListeners();
    // Auto advance
    _onStoryComplete();
  }

  Function(bool finished)? onStoryCompleteCallback;

  void _onStoryComplete() {
    if (_currentIndex < _stories.length - 1) {
      _currentIndex++;
      _loadStory();
    } else {
      // Finished all - Increment index to signal Widget to pop
      _currentIndex++;
      notifyListeners();
      onStoryCompleteCallback?.call(true);
    }
  }

  Future<void> _handleMusic(StoryData story) async {
    if (story.musicUrl != null && story.musicUrl!.isNotEmpty) {
      _audioPlayer ??= AudioPlayer();
      try {
        await _audioPlayer!.setUrl(story.musicUrl!);
        await _audioPlayer!.setLoopMode(LoopMode.one);
        if (!_isPaused) {
          await _audioPlayer!.play();
        }
      } catch (e) {
        debugPrint('Error playing story music: $e');
      }
    }
  }

  Future<void> _handleMusicStop() async {
    try {
      await _audioPlayer?.stop();
    } catch (_) {}
  }

  void nextStory(BuildContext context) {
    if (_currentIndex < _stories.length - 1) {
      _currentIndex++;
      _loadStory();
    } else {
      Navigator.pop(context);
    }
  }

  void previousStory() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _loadStory();
    } else {
      _loadStory(); // Restart
    }
  }

  void pause() {
    if (_isDisposed) return;
    _isPaused = true;
    _videoController?.pause();
    _progressTimer?.cancel();
    _audioPlayer?.pause();
  }

  void resume() {
    if (_isDisposed) return;
    _isPaused = false;
    _videoController?.play();
    _audioPlayer?.play();
    if (_progress < 1.0) {
      _startResumeTimer();
    }
  }

  void _startResumeTimer() {
    _cancelTimer();
    // Complex to resume exactly where left off without storing elapsed time properly.
    // But for now, let's keep it simple as the original code didn't have pause/resume explicit logic shown in snippet
    // effectively, just restarting the timer logic based on remaining percentage is tricky with just ticks.
    // Ideally we track elapsed time.

    // Re-calculating remaining ticks
    const tick = Duration(milliseconds: 50);
    int totalTicks = _duration.inMilliseconds ~/ tick.inMilliseconds;
    if (totalTicks <= 0) totalTicks = 1;
    int currentTick = (totalTicks * _progress).toInt();

    _progressTimer = Timer.periodic(tick, (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      currentTick++;
      _progress = currentTick / totalTicks;
      if (_progress >= 1.0) {
        _progress = 1.0;
        _cancelTimer();
        _onStoryComplete();
      } else {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelTimer();
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }
}

import 'dart:io';

import 'package:chatloop/feature/login_main/dashboard/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'music_widgets/music_provider.dart';
import 'music_widgets/music_selection_sheet.dart';
import 'package:chatloop/core/models/story_model.dart';
import 'story_editor_provider.dart';
import 'story_provider.dart';

class StoryEditorScreen extends StatefulWidget {
  final File file;
  final StoryMediaType type;

  const StoryEditorScreen({super.key, required this.file, required this.type});

  @override
  State<StoryEditorScreen> createState() => _StoryEditorScreenState();
}

class _StoryEditorScreenState extends State<StoryEditorScreen> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _overlayTextController = TextEditingController();

  final FocusNode _overlayFocusNode = FocusNode();
  AudioPlayer? _bgMusicPlayer;

  @override
  void initState() {
    super.initState();
    if (widget.type == StoryMediaType.video) {
      // Initialize video via provider
      Future.microtask(() {
        context.read<StoryEditorProvider>().initializeVideo(widget.file);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure status bar and nav bar are black with light icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _overlayTextController.dispose();
    _overlayFocusNode.dispose();
    _bgMusicPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Consumer<StoryEditorProvider>(
                builder: (context, editor, child) {
                  return GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Stack(
                      children: [
                        // Close Button (Top Left)
                        Positioned.fill(
                          child: widget.type == StoryMediaType.image
                              ? Image.file(widget.file, fit: BoxFit.cover)
                              : (editor.isInitialized &&
                                        editor.videoController != null
                                    ? FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width: editor
                                              .videoController!
                                              .value
                                              .size
                                              .width,
                                          height: editor
                                              .videoController!
                                              .value
                                              .size
                                              .height,
                                          child: VideoPlayer(
                                            editor.videoController!,
                                          ),
                                        ),
                                      )
                                    : const Center(
                                        child: CircularProgressIndicator(),
                                      )),
                        ),
                        // Close Button (Top Left)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        // Editor Tools (Top Right)
                        Positioned(
                          top: 20,
                          right: 16,
                          child: Column(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.text_fields,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () {
                                  editor.setShowOverlayInput(true);
                                  // Short delay to allow widget to build then focus
                                  Future.delayed(
                                    const Duration(milliseconds: 100),
                                    () {
                                      _overlayFocusNode.requestFocus();
                                    },
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () {
                                  // TODO: Implement add sticker/photo
                                },
                              ),
                              const SizedBox(height: 16),
                              IconButton(
                                icon: const Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 28,
                                ),

                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (ctx) => FractionallySizedBox(
                                      heightFactor: 0.6,
                                      child: ChangeNotifierProvider(
                                        create: (_) => MusicProvider(),
                                        child: MusicSelectionSheet(
                                          onSongSelected:
                                              (songName, url, coverUrl) async {
                                                Navigator.pop(ctx);
                                                // Update provider
                                                editor.setMusic(
                                                  songName,
                                                  url,
                                                  coverUrl,
                                                );

                                                // Handle Audio Player safely
                                                if (_bgMusicPlayer == null) {
                                                  _bgMusicPlayer =
                                                      AudioPlayer();
                                                } else {
                                                  await _bgMusicPlayer!.stop();
                                                }

                                                if (!mounted) return;

                                                try {
                                                  await _bgMusicPlayer!.setUrl(
                                                    url,
                                                  );
                                                  await _bgMusicPlayer!.play();
                                                  await _bgMusicPlayer!
                                                      .setLoopMode(
                                                        LoopMode.one,
                                                      );
                                                } catch (e) {
                                                  debugPrint(
                                                    'Error playing bg music: $e',
                                                  );
                                                }
                                              },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Draggable Overlay Text
                        if (editor.activeOverlayText.isNotEmpty &&
                            !editor.showOverlayInput)
                          Positioned(
                            left: editor.overlayOffset.dx,
                            top: editor.overlayOffset.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                editor.updateOverlayOffset(details.delta);
                              },
                              onTap: () {
                                // Edit existing text
                                _overlayTextController.text =
                                    editor.activeOverlayText;
                                editor.setShowOverlayInput(true);
                                Future.delayed(
                                  const Duration(milliseconds: 100),
                                  () {
                                    _overlayFocusNode.requestFocus();
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  editor.activeOverlayText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Music Sticker (Top Center)
                        if (editor.selectedMusicName != null)
                          Positioned(
                            top: 100,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (editor.selectedMusicCover != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          editor.selectedMusicCover!,
                                          width: 30,
                                          height: 30,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                                width: 30,
                                                height: 30,
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.music_note,
                                                  size: 20,
                                                  color: Colors.black,
                                                ),
                                              ),
                                        ),
                                      )
                                    else
                                      const Icon(
                                        Icons.music_note,
                                        size: 20,
                                        color: Colors.black,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      editor.selectedMusicName!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Overlay Text Input Dialog/Stack
                        if (editor.showOverlayInput)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: TextField(
                                    controller: _overlayTextController,
                                    focusNode: _overlayFocusNode,
                                    autofocus: true,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Type something...',
                                      hintStyle: TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    onSubmitted: (value) {
                                      editor.setActiveOverlayText(value);
                                      editor.setShowOverlayInput(false);
                                    },
                                    onTapOutside: (_) {
                                      editor.setActiveOverlayText(
                                        _overlayTextController.text,
                                      );
                                      editor.setShowOverlayInput(false);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Fixed Bottom Caption Preview (The "Bubble")
                        Positioned(
                          bottom: 20,
                          left: 10,
                          right: 60,
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _captionController,
                            builder: (context, value, child) {
                              if (value.text.isEmpty)
                                return const SizedBox.shrink();
                              // Safely access DashboardProvider if available, else placeholder
                              ImageProvider bgImage;
                              try {
                                final userData = context
                                    .read<DashboardProvider>();
                                if (userData.userProfile?.photoUrl != null &&
                                    userData.userProfile!.photoUrl.isNotEmpty) {
                                  final url = userData.userProfile!.photoUrl;
                                  if (url.startsWith('http')) {
                                    bgImage = NetworkImage(url);
                                  } else {
                                    bgImage = FileImage(File(url));
                                  }
                                } else {
                                  bgImage = const NetworkImage(
                                    'https://i.pravatar.cc/150?u=me',
                                  );
                                }
                              } catch (_) {
                                bgImage = const NetworkImage(
                                  'https://i.pravatar.cc/150?u=me',
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: bgImage,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                          bottomRight: Radius.circular(16),
                                          bottomLeft: Radius.circular(4),
                                        ),
                                      ),
                                      child: Text(
                                        value.text,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: () {
                      final editor = context.read<StoryEditorProvider>();
                      context.read<StoryProvider>().createStory(
                        widget.file,
                        widget.type,
                        caption: _captionController.text,
                        overlayText: editor.activeOverlayText.isNotEmpty
                            ? editor.activeOverlayText
                            : null,
                        overlayX: editor.activeOverlayText.isNotEmpty
                            ? editor.overlayOffset.dx
                            : null,
                        overlayY: editor.activeOverlayText.isNotEmpty
                            ? editor.overlayOffset.dy
                            : null,
                        musicName: editor.selectedMusicName,
                        musicUrl: editor.selectedMusicUrl,
                        musicCover: editor.selectedMusicCover,
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

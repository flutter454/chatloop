import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../login_main/dashboard/dashboard_provider.dart';
import 'post_provider.dart';

class UploadState extends ChangeNotifier {
  final TextEditingController captionController = TextEditingController();
  VideoPlayerController? videoController;
  bool videoInitialized = false;

  UploadState(File file, bool isVideo) {
    if (isVideo) {
      videoController = VideoPlayerController.file(file)
        ..initialize().then((_) {
          videoInitialized = true;
          notifyListeners();
        });
    }
  }

  @override
  void dispose() {
    captionController.dispose();
    videoController?.dispose();
    super.dispose();
  }
}

class PostUploadScreen extends StatelessWidget {
  final File file;
  final bool isVideo;

  const PostUploadScreen({
    super.key,
    required this.file,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UploadState(file, isVideo),
      child: const _PostUploadScreenBody(),
    );
  }
}

class _PostUploadScreenBody extends StatelessWidget {
  const _PostUploadScreenBody();

  @override
  Widget build(BuildContext context) {
    final uploadState = context.watch<UploadState>();
    final postProvider = context.watch<PostProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New reel',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Caption & Thumbnail Row
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Thumbnail
                              Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 80,
                                      height: 120,
                                      color: Colors.grey[200],
                                      child: uploadState.videoController != null && uploadState.videoInitialized
                                          ? VideoPlayer(uploadState.videoController!)
                                          : Image.file(
                                              context.findAncestorWidgetOfExactType<PostUploadScreen>()?.file 
                                                  ?? File(''),
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                  Container(
                                    width: 80,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Edit cover',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              // Caption Input
                              Expanded(
                                child: TextField(
                                  controller: uploadState.captionController,
                                  maxLines: 5,
                                  decoration: const InputDecoration(
                                    hintText: 'Write a caption and add hashtags...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 1),

                        // Options List
                        _buildOptionTile(Icons.tag, 'Hashtags', isChip: true),
                        _buildOptionTile(Icons.person_outline, 'Tag people'),
                        _buildOptionTile(
                          Icons.location_on_outlined,
                          'Add location',
                        ),
                        _buildOptionTile(
                          Icons.music_note_outlined,
                          'Rename audio',
                          trailingText: 'Original Audio',
                        ),
                        _buildOptionTile(
                          Icons.auto_awesome_outlined,
                          'Add AI label',
                          isSwitch: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Save draft',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: postProvider.isUploading
                              ? null
                              : () {
                                  // Find original widget context to access file and isVideo
                                  final rootWidget = context.findAncestorWidgetOfExactType<PostUploadScreen>();
                                  if (rootWidget == null) return;
                                  
                                  postProvider.uploadPost(
                                    file: rootWidget.file,
                                    caption: uploadState.captionController.text,
                                    isVideo: rootWidget.isVideo,
                                    userName: dashboardProvider.userName,
                                    userAvatarUrl: dashboardProvider.userPhotoUrl,
                                    onSuccess: () {
                                      // Refresh the feed
                                      postProvider.fetchPosts(forceRefresh: true);
                                      // Pop to Home (root) or show success
                                      Navigator.of(
                                        context,
                                      ).popUntil((route) => route.isFirst);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Post uploaded successfully!',
                                          ),
                                        ),
                                      );
                                    },
                                    onError: (error) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $error'),
                                        ),
                                      );
                                    },
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: postProvider.isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Share',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (postProvider.isUploading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String title, {
    bool isChip = false,
    bool isSwitch = false,
    String? trailingText,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: isSwitch
          ? Switch(value: false, onChanged: (v) {})
          : trailingText != null
          ? SizedBox(
              width: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    trailingText,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            )
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}

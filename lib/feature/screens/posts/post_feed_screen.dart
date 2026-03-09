import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/models/post_model.dart';
import 'media_picker_screen.dart';
import 'post_provider.dart';

class PostFeedScreen extends StatefulWidget {
  const PostFeedScreen({super.key});

  @override
  State<PostFeedScreen> createState() => _PostFeedScreenState();
}

class _PostFeedScreenState extends State<PostFeedScreen> {
  @override
  void initState() {
    super.initState();
    // Use cache when navigating back to this screen.
    // Only hits Supabase if posts haven't been loaded yet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Feed',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_box_outlined,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MediaPickerScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<PostProvider>(
        builder: (context, provider, _) {
          // Loading state
          if (provider.isFeedLoading && provider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (provider.feedError != null && provider.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load feed',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.feedError!,
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchPosts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (provider.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to share your first post',
                    style: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                ],
              ),
            );
          }

          // Posts list
          return RefreshIndicator(
            // Pull-to-refresh bypasses cache and loads fresh from Supabase
            onRefresh: () => provider.fetchPosts(forceRefresh: true),
            child: ListView.builder(
              itemCount: provider.posts.length,
              itemBuilder: (context, index) {
                return _PostCard(post: provider.posts[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  POST CARD WIDGET
// ═══════════════════════════════════════════════════════════════
class _PostCard extends StatelessWidget {
  final PostModel post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header (avatar + username) ──────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[300],
                backgroundImage: post.userAvatarUrl != null
                    ? NetworkImage(post.userAvatarUrl!)
                    : null,
                child: post.userAvatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  post.userName ?? 'User',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: () => _showPostOptions(context),
              ),
            ],
          ),
        ),

        // ── Media (image or video) ──────────────────────────────
        if (post.signedUrl != null)
          post.isVideo
              ? _VideoPostWidget(
                  url: post.signedUrl!,
                  postId: post.id.toString(),
                )
              : AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    post.signedUrl!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stack) {
                      return Container(
                        color: Colors.grey[100],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                )
        else
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              color: Colors.grey[100],
              child: const Center(
                child: Icon(
                  Icons.image_not_supported,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

        // ── Action buttons ──────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border, size: 26),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 24),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.send_outlined, size: 24),
                onPressed: () {},
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.bookmark_border, size: 26),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // ── Caption ─────────────────────────────────────────────
        if (post.caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black, fontSize: 14),
                children: [
                  TextSpan(
                    text: '${post.userName ?? 'User'} ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: post.caption),
                ],
              ),
            ),
          ),

        // ── Timestamp ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(
            _timeAgo(post.createdAt),
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ),

        const Divider(height: 1),
      ],
    );
  }

  void _showPostOptions(BuildContext context) {
    final provider = context.read<PostProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentUserId == post.userId)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Post',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(sheetCtx); // close the sheet first
                  try {
                    await provider.deletePost(post);
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete post: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () => Navigator.pop(sheetCtx),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(sheetCtx),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// ═══════════════════════════════════════════════════════════════
//  VIDEO POST WIDGET  –  auto-play / auto-pause on scroll
// ═══════════════════════════════════════════════════════════════
class VideoPostState extends ChangeNotifier {
  final VideoPlayerController controller;
  bool initialized = false;
  bool userPaused = false;

  VideoPostState(String url) : controller = VideoPlayerController.networkUrl(Uri.parse(url)) {
    controller.setLooping(true);
    controller.setVolume(0);
    controller.initialize().then((_) {
      initialized = true;
      notifyListeners();
    }).catchError((e) {
      debugPrint('Video init error: $e');
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void togglePlayPause() {
    if (!initialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
      userPaused = true;
    } else {
      controller.play();
      userPaused = false;
    }
    notifyListeners();
  }

  void toggleMute() {
    if (!initialized) return;
    final isMuted = controller.value.volume == 0.0;
    controller.setVolume(isMuted ? 1.0 : 0.0);
    notifyListeners();
  }

  void onVisibilityChanged(VisibilityInfo info) {
    if (!initialized) return;
    final visibleFraction = info.visibleFraction;

    if (visibleFraction >= 0.5) {
      if (!controller.value.isPlaying && !userPaused) {
        controller.play();
        // Option to notify, though VideoPlayer updates itself on play
      }
    } else {
      if (controller.value.isPlaying) {
        controller.pause();
      }
      userPaused = false;
    }
  }
}

class _VideoPostWidget extends StatelessWidget {
  final String url;
  final String postId;

  const _VideoPostWidget({required this.url, required this.postId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VideoPostState(url),
      child: Consumer<VideoPostState>(
        builder: (context, state, child) {
          if (!state.initialized) {
            return AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: Colors.black,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            );
          }

          return VisibilityDetector(
            key: Key('video_post_$postId'),
            onVisibilityChanged: state.onVisibilityChanged,
            child: GestureDetector(
              onTap: state.togglePlayPause,
              child: AspectRatio(
                aspectRatio: state.controller.value.aspectRatio > 0
                    ? state.controller.value.aspectRatio
                    : 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(state.controller),

                    // ── Mute/unmute button (bottom-right) ────────────
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: state.toggleMute,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            state.controller.value.volume == 0.0
                                ? Icons.volume_off
                                : Icons.volume_up,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // ── Centre pause icon (shown briefly via ValueListenableBuilder)
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: state.controller,
                      builder: (context, value, child) {
                        // Show a play icon only when paused (gives tap feedback)
                        if (value.isPlaying) return const SizedBox.shrink();
                        return Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 36,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

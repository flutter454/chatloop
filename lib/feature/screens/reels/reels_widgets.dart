import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../../core/models/post_model.dart';
import '../../login_main/dashboard/dashboard_provider.dart';
import '../posts/comments_bottom_sheet.dart';
import '../posts/post_provider.dart';

class ReelVideoPlayer extends StatefulWidget {
  final PostModel post;
  final bool isVisible;

  const ReelVideoPlayer({
    super.key,
    required this.post,
    required this.isVisible,
  });

  @override
  State<ReelVideoPlayer> createState() => _ReelVideoPlayerState();
}

class _ReelVideoPlayerState extends State<ReelVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (widget.post.signedUrl == null) return;
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.post.signedUrl!),
    );
    try {
      await _controller!.initialize();
      _controller!.setLooping(true);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isVisible) {
          _controller!.play();
        }
      }
    } catch (e) {
      debugPrint("Reel video error: $e");
    }
  }

  @override
  void didUpdateWidget(ReelVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible != widget.isVisible) {
      if (widget.isVisible) {
        _controller?.play();
      } else {
        _controller?.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final postProvider = context.watch<PostProvider>();
    final dashboard = context.watch<DashboardProvider>();

    final postId = widget.post.id.toString();
    final isLiked = postProvider.isLiked(postId);
    final likeCount = postProvider.getLikers(postId).length;
    final commentCount = postProvider.getComments(postId).length;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Video Player ──────────────────────────────────────────────
        if (_isInitialized && _controller != null)
          GestureDetector(
            onTap: () {
              if (_controller!.value.isPlaying) {
                _controller!.pause();
              } else {
                _controller!.play();
              }
            },
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              ),
            ),
          )
        else
          Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),

        // ── Gradient Overlay for Text Visibility ──────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 300,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // ── Right Side Actions ────────────────────────────────────────
        Positioned(
          right: 16,
          bottom: 100, // Make sure it sits above the bottom nav bar
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Like Action
              _ReelActionItem(
                icon: isLiked ? Icons.favorite : Icons.favorite_border,
                iconColor: isLiked ? Colors.red : Colors.white,
                label: likeCount > 0 ? likeCount.toString() : 'Like',
                onTap: () {
                  final currentUserId =
                      Supabase.instance.client.auth.currentUser?.id ?? 'me';
                  context.read<PostProvider>().toggleLike(
                    postId,
                    currentUserId: currentUserId,
                    userName: dashboard.userName.isNotEmpty
                        ? dashboard.userName
                        : 'Me',
                    avatarUrl: dashboard.userPhotoUrl.isNotEmpty
                        ? dashboard.userPhotoUrl
                        : 'https://i.pravatar.cc/150?u=me',
                  );
                },
              ),
              const SizedBox(height: 16),

              // Comment Action
              _ReelActionItem(
                icon: Icons.chat_bubble_outline,
                iconColor: Colors.white,
                label: commentCount > 0 ? commentCount.toString() : 'Comment',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CommentsBottomSheet(postId: postId),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Share Action
              _ReelActionItem(
                icon: Icons.send_outlined,
                iconColor: Colors.white,
                label: 'Share',
                onTap: () {
                  // TODO: Implement share
                },
              ),
              const SizedBox(height: 16),

              // Save Action
              _ReelActionItem(
                icon: Icons.bookmark_border,
                iconColor: Colors.white,
                label: 'Save',
                onTap: () {
                  // TODO: Implement save
                },
              ),
            ],
          ),
        ),

        // ── Bottom Info ───────────────────────────────────────────────
        Positioned(
          left: 16,
          bottom: 100,
          right: 80, // Prevent overlapping with right actions
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    backgroundImage: widget.post.userAvatarUrl != null
                        ? NetworkImage(widget.post.userAvatarUrl!)
                        : null,
                    child: widget.post.userAvatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (widget.post.userName?.isNotEmpty == true) 
                            ? widget.post.userName! 
                            : 'Unknown User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '@${(widget.post.userName?.isNotEmpty == true ? widget.post.userName! : 'user').toLowerCase().replaceAll(' ', '_')}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Optional follow button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Follow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (widget.post.caption.isNotEmpty)
                Text(
                  widget.post.caption,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReelActionItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ReelActionItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

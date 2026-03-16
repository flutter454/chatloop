import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../login_main/dashboard/dashboard_provider.dart';
import '../home/home_page/home_page_provider.dart';
import 'post_provider.dart';

class CommentsBottomSheet extends StatefulWidget {
  final String postId;
  final bool isMock;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    this.isMock = false,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _controller = TextEditingController();

  String _timeAgo(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'Just now';
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      final diff = DateTime.now().difference(dateTime);
      
      if (diff.inDays > 365) {
        return '${(diff.inDays / 365).floor()}y ago';
      } else if (diff.inDays > 30) {
        return '${(diff.inDays / 30).floor()}mo ago';
      } else if (diff.inDays > 7) {
        return '${(diff.inDays / 7).floor()}w ago';
      } else if (diff.inDays > 0) {
        return '${diff.inDays}d ago';
      } else if (diff.inHours > 0) {
        return '${diff.inHours}h ago';
      } else if (diff.inMinutes > 0) {
        return '${diff.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comments = widget.isMock
        ? context.watch<HomePageProvider>().getComments(widget.postId)
        : context.watch<PostProvider>().getComments(widget.postId);

    final dashboard = context.watch<DashboardProvider>();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? 'me';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              comments.isEmpty ? 'Comments' : 'Comments (${comments.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: comments.isEmpty
                ? Center(
                    child: Text(
                      'No comments yet. Be the first to comment!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.grey[300],
                              backgroundImage:
                                  comment['avatar'] != null &&
                                      comment['avatar'].toString().isNotEmpty
                                  ? NetworkImage(comment['avatar'])
                                  : null,
                              child:
                                  comment['avatar'] == null ||
                                      comment['avatar'].toString().isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        comment['name'] ?? 'User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _timeAgo(comment['timestamp']?.toString()),
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    comment['text'] ?? '',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.favorite_border,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 8,
            ),
            child: SafeArea(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: dashboard.userPhotoUrl.isNotEmpty
                        ? NetworkImage(dashboard.userPhotoUrl)
                        : null,
                    child: dashboard.userPhotoUrl.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;

                      if (widget.isMock) {
                        context.read<HomePageProvider>().addComment(
                          widget.postId,
                          currentUserId: currentUserId,
                          userName: dashboard.userName.isNotEmpty
                              ? dashboard.userName
                              : 'Me',
                          avatarUrl: dashboard.userPhotoUrl.isNotEmpty
                              ? dashboard.userPhotoUrl
                              : 'https://i.pravatar.cc/150?u=me',
                          text: text,
                        );
                      } else {
                        context.read<PostProvider>().addComment(
                          widget.postId,
                          currentUserId: currentUserId,
                          userName: dashboard.userName.isNotEmpty
                              ? dashboard.userName
                              : 'Me',
                          avatarUrl: dashboard.userPhotoUrl.isNotEmpty
                              ? dashboard.userPhotoUrl
                              : 'https://i.pravatar.cc/150?u=me',
                          text: text,
                        );
                      }
                      _controller.clear();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../posts/post_provider.dart';
import 'reels_provider.dart';
import 'reels_widgets.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key});

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<PostProvider>(
        builder: (context, postProvider, child) {
          if (postProvider.isFeedLoading && !postProvider.hasPosts) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (postProvider.feedError != null && !postProvider.hasPosts) {
            return Center(
              child: Text(
                'Error: ${postProvider.feedError}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final videoPosts = postProvider.posts
              .where((p) => p.isVideo && p.signedUrl != null)
              .toList();

          if (videoPosts.isEmpty) {
            return const Center(
              child: Text(
                'No reels available yet.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          return Consumer<ReelsProvider>(
            builder: (context, reelsProvider, child) {
              return PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: videoPosts.length,
                onPageChanged: (index) {
                  reelsProvider.setCurrentIndex(index);
                },
                itemBuilder: (context, index) {
                  final post = videoPosts[index];
                  return ReelVideoPlayer(
                    post: post,
                    isVisible: reelsProvider.currentIndex == index,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

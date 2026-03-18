import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../posts/post_provider.dart';
import '../story/story_provider.dart';
import 'home_page_provider.dart';
import 'home_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch real posts from Supabase when home screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostProvider>().fetchPosts();
      context.read<HomePageProvider>().listenForIncomingCalls(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final homePageProvider = context.watch<HomePageProvider>();
    final postProvider = context.watch<PostProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: HomeWidgets.buildAppBar(context),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<StoryProvider>().refresh();
          await context.read<PostProvider>().fetchPosts();
        },
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            Builder(
              builder: (context) => HomeWidgets.buildStoriesSection(context),
            ),

            // ── Real Supabase Posts ─────────────────────────────
            if (postProvider.isFeedLoading && postProvider.posts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (postProvider.posts.isNotEmpty)
              ...postProvider.posts.map(
                (post) => HomeWidgets.buildSupabasePost(context, post),
              ),

            // ── Placeholder posts (can remove later) ───────────
            const SizedBox(height: 100), // Bottom padding for navigation bar
          ],
        ),
      ),
    );
  }
}

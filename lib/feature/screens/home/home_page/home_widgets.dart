// ignore_for_file: avoid_single_cascade_in_expression_statements

import 'dart:io';

import 'package:chatloop/feature/login_main/dashboard/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../../posts/media_picker_screen.dart';
import '../story/story_provider.dart';
import 'story_view_provider.dart';

class HomeWidgets {
  static Widget buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'ChatLoop',
        style: TextStyle(
          fontFamily: 'Pacifico',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontStyle: FontStyle.italic,
          color: Colors.black,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.add_a_photo, color: Colors.black, size: 28),
        onPressed: () => _handleStoryCreation(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.black,
            size: 28,
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  static Widget buildStoriesSection(BuildContext context) {
    final storyProvider = context.watch<StoryProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          // My Story Item
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                if (storyProvider.myStories.isNotEmpty) {
                  _showStoryView(context, storyProvider.myStories);
                } else {
                  _handleStoryCreation(context);
                }
              },
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: storyProvider.myStory != null
                              ? const LinearGradient(
                                  colors: [Colors.blue, Colors.green],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                )
                              : null,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage: storyProvider.myStory != null
                                ? (storyProvider.myStory!.type ==
                                          StoryMediaType.image
                                      ? (storyProvider.myStory!.file != null
                                            ? FileImage(
                                                storyProvider.myStory!.file!,
                                              )
                                            : NetworkImage(
                                                    storyProvider
                                                        .myStory!
                                                        .mediaUrl!,
                                                  )
                                                  as ImageProvider)
                                      : (storyProvider.myStory!.thumbnailPath !=
                                                null
                                            ? FileImage(
                                                File(
                                                  storyProvider
                                                      .myStory!
                                                      .thumbnailPath!,
                                                ),
                                              )
                                            : (dashboardProvider
                                                      .userPhotoUrl
                                                      .isNotEmpty
                                                  ? (dashboardProvider
                                                            .userPhotoUrl
                                                            .startsWith('http')
                                                        ? NetworkImage(
                                                            dashboardProvider
                                                                .userPhotoUrl,
                                                          )
                                                        : FileImage(
                                                                File(
                                                                  dashboardProvider
                                                                      .userPhotoUrl,
                                                                ),
                                                              )
                                                              as ImageProvider)
                                                  : const NetworkImage(
                                                          'https://i.pravatar.cc/150?u=me',
                                                        )
                                                        as ImageProvider)))
                                : (dashboardProvider.userPhotoUrl.isNotEmpty
                                      ? (dashboardProvider.userPhotoUrl
                                                .startsWith('http')
                                            ? NetworkImage(
                                                dashboardProvider.userPhotoUrl,
                                              )
                                            : FileImage(
                                                    File(
                                                      dashboardProvider
                                                          .userPhotoUrl,
                                                    ),
                                                  )
                                                  as ImageProvider)
                                      : const NetworkImage(
                                          'https://i.pravatar.cc/150?u=me',
                                        )),
                            child:
                                storyProvider.myStory != null &&
                                    storyProvider.myStory!.type ==
                                        StoryMediaType.video
                                ? const Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 30,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,

                        child: GestureDetector(
                          onTap: () => _handleStoryCreation(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your Story',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          // Friend Stories
          ...storyProvider.friendStories.map((stories) {
            final firstStory = stories.first;
            // Use first story to identify user
            // We assume name/avatar is consistent or just use first one
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GestureDetector(
                onTap: () => _showStoryView(context, stories),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.orange, Colors.pink, Colors.purple],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child:
                              (firstStory.userPhoto != null &&
                                  firstStory.userPhoto!.isNotEmpty &&
                                  firstStory.userPhoto!.startsWith('http'))
                              ? Image.network(
                                  firstStory.userPhoto!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.network(
                                      'https://i.pravatar.cc/150?u=${firstStory.userId}',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey.shade300,
                                        alignment: Alignment.center,
                                        child: Text(
                                          firstStory.userName.isNotEmpty
                                              ? firstStory.userName[0]
                                                    .toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Image.network(
                                  'https://i.pravatar.cc/150?u=${firstStory.userId}',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade300,
                                    alignment: Alignment.center,
                                    child: Text(
                                      firstStory.userName.isNotEmpty
                                          ? firstStory.userName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      firstStory.userName.isNotEmpty
                          ? firstStory.userName
                          : 'Friend',
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  static Future<void> _handleStoryCreation(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MediaPickerScreen()),
    );
  }

  static void _showStoryView(
    BuildContext context,
    List<StoryData> stories, {
    int initialIndex = 0,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      useSafeArea: true,
      builder: (context) => ChangeNotifierProvider(
        create: (_) => StoryViewProvider()..init(stories, initialIndex),
        child: const StoryViewer(),
      ),
    );
  }

  static Widget buildPost(Map<String, String> post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(post['avatar']!),
          ),
          title: Text(
            post['user']!,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          trailing: const Icon(Icons.more_horiz),
        ),
        AspectRatio(
          aspectRatio: 1,
          child: Image.network(post['image']!, fit: BoxFit.cover),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.favorite_border_rounded, size: 28),
              const SizedBox(width: 16),
              const Icon(Icons.mode_comment_outlined, size: 26),
              const SizedBox(width: 16),
              const Icon(Icons.send_outlined, size: 26),
              const Spacer(),
              const Icon(Icons.bookmark_border_rounded, size: 28),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Liked by others',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: '${post['user']} ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: post['caption']),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class StoryViewer extends StatelessWidget {
  const StoryViewer({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure status bar and nav bar are black with light icons
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    final provider = context.watch<StoryViewProvider>();
    final userData = context.watch<DashboardProvider>();

    // Handle Closing when finished
    // Ideally this should be a side effect, but in build we can check.
    // However, better to use a listener or check before building?
    // Provider's navigation logic might need a key or callback passed.
    // We'll adding a listener in the provider via a callback setter in `create` is cleaner,
    // but here we can just check if index is out of bounds or some flag.
    // For now, let's assume the provider will handle or we check manually.

    // Actually, calling Navigator.pop in build is bad.
    // Let's use a post-frame callback if we detect "finished".
    if (provider.currentIndex >= provider.stories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }

    final currentStory = provider.currentStory;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPressStart: (_) => provider.pause(),
          onLongPressEnd: (_) => provider.resume(),
          onTapUp: (details) {
            final width = MediaQuery.of(context).size.width;
            if (details.globalPosition.dx < width / 3) {
              provider.previousStory();
            } else {
              provider.nextStory(context);
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Center Content (Image/Video)
              Center(
                child: currentStory.type == StoryMediaType.image
                    ? (currentStory.mediaUrl != null &&
                              currentStory.mediaUrl!.isNotEmpty
                          ? Image.network(
                              currentStory.mediaUrl!,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.black,
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.white,
                                        size: 50,
                                      ),
                                      SizedBox(height: 10),
                                      Text(
                                        "Content unavailable",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : (currentStory.file != null
                                ? Image.file(
                                    currentStory.file!,
                                    fit: BoxFit.contain,
                                  )
                                : const SizedBox.shrink()))
                    : (provider.hasError
                          ? Container(
                              color: Colors.black,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Video unavailable",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            )
                          : (provider.isInitialized &&
                                    provider.videoController != null
                                ? AspectRatio(
                                    aspectRatio: provider
                                        .videoController!
                                        .value
                                        .aspectRatio,
                                    child: VideoPlayer(
                                      provider.videoController!,
                                    ),
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      if (currentStory.thumbnailUrl != null &&
                                          currentStory.thumbnailUrl!.isNotEmpty)
                                        Image.network(
                                          currentStory.thumbnailUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const SizedBox.shrink(),
                                        ),
                                      const CircularProgressIndicator(),
                                    ],
                                  ))),
              ),

              // Segmented Progress Bar
              Positioned(
                top: 4,
                left: 10,
                right: 10,
                child: Row(
                  children: List.generate(provider.stories.length, (index) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: index == provider.currentIndex
                            ? LinearProgressIndicator(
                                value: provider.progress,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                                minHeight: 2,
                              )
                            : LinearProgressIndicator(
                                value: index < provider.currentIndex
                                    ? 1.0
                                    : 0.0,
                                backgroundColor: Colors.white24,
                                valueColor: const AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                                minHeight: 2,
                              ),
                      ),
                    );
                  }),
                ),
              ),

              // Overlay Text
              if (currentStory.overlayText != null &&
                  currentStory.overlayText!.isNotEmpty)
                Positioned(
                  left: currentStory.overlayX ?? 100,
                  top: currentStory.overlayY ?? 300,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currentStory.overlayText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Music Sticker
              if (currentStory.musicName != null)
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
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (currentStory.musicCover != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                currentStory.musicCover!,
                                width: 30,
                                height: 30,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
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
                            currentStory.musicName!,
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

              // Bottom Gradient Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 150,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                        Colors.black,
                      ],
                    ),
                  ),
                ),
              ),

              // Caption
              if (currentStory.caption != null &&
                  currentStory.caption!.isNotEmpty)
                Positioned(
                  bottom: 88,
                  left: 10,
                  right: 60,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[300],
                        child: ClipOval(
                          child:
                              (currentStory.userPhoto != null &&
                                  currentStory.userPhoto!.isNotEmpty)
                              ? Image.network(
                                  currentStory.userPhoto!,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      size: 20,
                                      color: Colors.grey,
                                    );
                                  },
                                )
                              : (userData.userProfile?.photoUrl != null &&
                                    userData.userProfile!.photoUrl.isNotEmpty &&
                                    currentStory.userId ==
                                        Supabase
                                            .instance
                                            .client
                                            .auth
                                            .currentUser
                                            ?.id)
                              ? (userData.userProfile!.photoUrl.startsWith(
                                      'http',
                                    )
                                    ? Image.network(
                                        userData.userProfile!.photoUrl,
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(userData.userProfile!.photoUrl),
                                        width: 32,
                                        height: 32,
                                        fit: BoxFit.cover,
                                      ))
                              : Image.network(
                                  'https://i.pravatar.cc/150?u=me',
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      size: 20,
                                      color: Colors.grey,
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 1,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                                bottomLeft: Radius.circular(1),
                              ),
                            ),
                            child: Text(
                              currentStory.caption!,
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
                      ),
                    ],
                  ),
                ),

              // Share and Menu Options (Bottom Right)
              Positioned(
                bottom: 20,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Share Button
                    IconButton(
                      icon: const Icon(
                        Icons.near_me,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () =>
                          _shareStory(context, provider, currentStory),
                    ),
                    const SizedBox(width: 8),
                    // Three Dots Menu
                    IconButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => _showDeleteOption(context, provider),
                    ),
                  ],
                ),
              ),

              // Top Controls
              Positioned(
                top: 14,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    // User Info
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[300],
                      child: ClipOval(
                        child:
                            (currentStory.userPhoto != null &&
                                currentStory.userPhoto!.isNotEmpty)
                            ? Image.network(
                                currentStory.userPhoto!,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Colors.grey,
                                  );
                                },
                              )
                            : (userData.userProfile?.photoUrl != null &&
                                  userData.userProfile!.photoUrl.isNotEmpty &&
                                  currentStory.userId ==
                                      Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser
                                          ?.id)
                            ? (userData.userProfile!.photoUrl.startsWith('http')
                                  ? Image.network(
                                      userData.userProfile!.photoUrl,
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(userData.userProfile!.photoUrl),
                                      width: 36,
                                      height: 36,
                                      fit: BoxFit.cover,
                                    ))
                            : Image.network(
                                'https://i.pravatar.cc/150?u=me',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    size: 24,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                      ),
                    ),

                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                currentStory.userName.isNotEmpty
                                    ? currentStory.userName
                                    : 'Your Story',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                () {
                                  final diff = DateTime.now().difference(
                                    currentStory.timestamp,
                                  );
                                  if (diff.inMinutes < 60) {
                                    return '${diff.inMinutes}m';
                                  } else {
                                    return '${diff.inHours}h';
                                  }
                                }(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Three Dots Menu - Removed from Top
                    // IconButton(
                    //   icon: const Icon(
                    //     Icons.more_vert,
                    //     color: Colors.white,
                    //     size: 28,
                    //   ),
                    //   onPressed: () => _showDeleteOption(context),
                    // ),
                    // Close Button (Right side, or maybe just swipe down? Most stories have close at top right or swipe)
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareStory(
    BuildContext context,
    StoryViewProvider provider,
    StoryData story,
  ) async {
    debugPrint(
      'Attempting to share story: ${story.mediaUrl ?? story.file?.path}',
    );
    provider.pause();

    try {
      if (story.file != null) {
        final xFile = XFile(story.file!.path);
        await Share.shareXFiles([
          xFile,
        ], text: story.caption ?? 'Check out this story!');
      } else if (story.mediaUrl != null) {
        await Share.share(story.mediaUrl!, subject: story.caption);
      }
      debugPrint('Share action completed');
    } catch (e) {
      debugPrint('Error sharing story: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing: $e')));
      }
    } finally {
      if (context.mounted) provider.resume();
    }
  }

  void _showDeleteOption(BuildContext context, StoryViewProvider provider) {
    provider.pause();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete Story',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () async {
                  final storyToDelete = provider.currentStory;
                  await context.read<StoryProvider>().deleteStory(
                    storyToDelete,
                  );
                  if (context.mounted) Navigator.pop(ctx);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.pop(ctx); // Close sheet
                },
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (context.mounted) {
        provider.resume();
      }
    });
  }
}

import 'package:chatloop/core/models/story_model.dart';
import 'package:chatloop/feature/screens/home/home_page/home_widgets.dart';
import 'package:chatloop/feature/screens/profile/story_archive/story_archive_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StoryArchiveScreen extends StatelessWidget {
  const StoryArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StoryArchiveProvider(),
      child: const _StoryArchiveView(),
    );
  }
}

class _StoryArchiveView extends StatelessWidget {
  const _StoryArchiveView();

  Future<void> _showCreateHighlightDialog(
    BuildContext context,
    StoryArchiveProvider provider,
  ) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Name this highlight'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Vacation, Friends…',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = nameController.text.trim();
              if (text.isNotEmpty) Navigator.pop(ctx, text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null) {
      final success = await provider.createHighlight(name);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$name" added to highlights!'),
            backgroundColor: Colors.black87,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoryArchiveProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: provider.selectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: provider.cancelSelection,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
        title: provider.selectionMode
            ? Text(
                '${provider.selectedIndices.length} selected',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : const Text(
                'Story Archive',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
        actions: provider.selectionMode
            ? [
                TextButton.icon(
                  onPressed: () =>
                      _showCreateHighlightDialog(context, provider),
                  icon: const Icon(Icons.bookmark_add, color: Colors.black),
                  label: const Text(
                    'Highlight',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ]
            : [],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
          ? Center(
              child: Text(
                'Error: ${provider.error}',
                style: const TextStyle(color: Colors.grey),
              ),
            )
          : provider.allStories.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No stories yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _buildArchiveGrid(context, provider),
    );
  }

  Widget _buildArchiveGrid(
    BuildContext context,
    StoryArchiveProvider provider,
  ) {
    final stories = provider.allStories;
    final Map<String, List<({StoryData story, int flatIndex})>> grouped = {};
    for (int i = 0; i < stories.length; i++) {
      final story = stories[i];
      final dateKey = _formatDate(story.timestamp);
      grouped.putIfAbsent(dateKey, () => []).add((story: story, flatIndex: i));
    }

    final dateKeys = grouped.keys.toList();

    return ListView.builder(
      itemCount: dateKeys.length,
      itemBuilder: (context, sectionIndex) {
        final dateKey = dateKeys[sectionIndex];
        final dayEntries = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                dateKey,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 1),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
              ),
              itemCount: dayEntries.length,
              itemBuilder: (context, index) {
                final entry = dayEntries[index];
                final story = entry.story;
                final flatIndex = entry.flatIndex;
                final isSelected = provider.selectedIndices.contains(flatIndex);

                final String? thumbUrl = story.type == StoryMediaType.image
                    ? story.mediaUrl
                    : (story.thumbnailUrl ?? story.mediaUrl);

                return GestureDetector(
                  onLongPress: () => provider.enterSelectMode(flatIndex),
                  onTap: () {
                    if (provider.selectionMode) {
                      provider.toggleSelect(flatIndex);
                    } else {
                      final dayStories = dayEntries
                          .map((e) => e.story)
                          .toList();
                      HomeWidgets.showStoryView(
                        context,
                        dayStories,
                        initialIndex: index,
                      );
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.grey[200]),
                      if (thumbUrl != null && thumbUrl.isNotEmpty)
                        Image.network(
                          thumbUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 28,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: Colors.black87,
                          child: const Center(
                            child: Icon(
                              Icons.videocam,
                              color: Colors.white54,
                              size: 32,
                            ),
                          ),
                        ),
                      if (story.type == StoryMediaType.video)
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black45, Colors.transparent],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      Positioned(
                        bottom: 4,
                        right: 6,
                        child: Text(
                          _formatTime(story.timestamp),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(blurRadius: 6, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                      if (provider.selectionMode)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          color: isSelected
                              ? Colors.black.withOpacity(0.35)
                              : Colors.transparent,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.all(6),
                          child: AnimatedScale(
                            scale: isSelected ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      if (provider.selectionMode && !isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

import 'media_picker_provider.dart';
import 'post_provider.dart';
import 'post_upload_screen.dart';

class MediaPickerScreen extends StatelessWidget {
  const MediaPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MediaPickerProvider(),
      child: const _MediaPickerContent(),
    );
  }
}

class _MediaPickerContent extends StatelessWidget {
  const _MediaPickerContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaPickerProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, provider),
            _buildAlbumSelector(context, provider),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification scroll) {
                  if (scroll.metrics.pixels >=
                      scroll.metrics.maxScrollExtent - 200) {
                    context.read<MediaPickerProvider>().loadMoreAssets();
                    return true;
                  }
                  return false;
                },
                child: provider.assets.isEmpty && !provider.isLoading
                    ? const Center(
                        child: Text(
                          'No media found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 1,
                              mainAxisSpacing: 1,
                            ),
                        // +1 for Camera button
                        itemCount: provider.assets.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () => provider.pickFromCamera(context),
                              child: Container(
                                color: Colors.grey[900],
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            );
                          }

                          final asset = provider.assets[index - 1];
                          final isSelected =
                              asset.id == provider.selectedAsset?.id;

                          return _MediaTile(
                            asset: asset,
                            isSelected: isSelected,
                            onTap: () => provider.selectAsset(asset),
                          );
                        },
                      ),
              ),
            ),
            if (provider.isLoading && provider.assets.isNotEmpty)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(Colors.white),
                minHeight: 2,
              ),
            _buildBottomTabs(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, MediaPickerProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'New reel', // Dynamic based on tab?
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: () async {
              if (provider.selectedAsset != null) {
                final file = await provider.selectedAsset!.file;
                if (file != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider(
                        create: (_) => PostProvider(),
                        child: PostUploadScreen(
                          file: file,
                          isVideo:
                              provider.selectedAsset!.type == AssetType.video,
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Next',
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumSelector(
    BuildContext context,
    MediaPickerProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showAlbumPicker(context),
            child: Row(
              children: [
                Text(
                  provider.currentPath?.name ?? 'Recents',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTabs(BuildContext context, MediaPickerProvider provider) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(provider.tabs.length, (index) {
          final isSelected = index == provider.selectedTabIndex;
          return GestureDetector(
            onTap: () => provider.setTabIndex(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: isSelected
                  ? BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                    )
                  : null,
              child: Text(
                provider.tabs[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void _showAlbumPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        // Use the provider from outer context, but we need to pass it or re-access it properly.
        // Usually modal sheet is a new route, so it might lose access if not passed or using a global/parent provider.
        // Since we created provider in `MediaPickerScreen`, it is up the tree from `_MediaPickerContent`.
        // However, showModalBottomSheet pushes a new route above the current one.
        // Provider might not be available if not wrapped.
        // Solution: Wrap the sheet builder in ChangeNotifierProvider.value
        return ChangeNotifierProvider.value(
          value: context.read<MediaPickerProvider>(),
          child: Consumer<MediaPickerProvider>(
            builder: (context, provider, _) {
              return ListView.builder(
                itemCount: provider.paths.length,
                itemBuilder: (context, index) {
                  final path = provider.paths[index];
                  return ListTile(
                    title: Text(
                      path.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: FutureBuilder<int>(
                      future: path.assetCountAsync,
                      builder: (context, snapshot) {
                        return Text(
                          '${snapshot.data ?? 0}',
                          style: const TextStyle(color: Colors.grey),
                        );
                      },
                    ),
                    onTap: () {
                      provider.setCurrentPath(path);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _MediaTile extends StatelessWidget {
  final AssetEntity asset;
  final bool isSelected;
  final VoidCallback onTap;

  const _MediaTile({
    required this.asset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FutureBuilder<Uint8List?>(
            future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.data != null) {
                return Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  color: isSelected ? Colors.white.withOpacity(0.4) : null,
                  colorBlendMode: isSelected
                      ? BlendMode.lighten
                      : null, // Highlight effect
                );
              }
              return Container(color: Colors.grey[900]);
            },
          ),
          if (asset.type == AssetType.video)
            const Positioned(
              right: 4,
              top: 4,
              child: Icon(
                Icons.play_circle_fill,
                color: Colors.white,
                size: 20,
              ),
            ),
          if (asset.duration > 0)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDuration(asset.duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (isSelected)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 3),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final min = d.inMinutes;
    final sec = d.inSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

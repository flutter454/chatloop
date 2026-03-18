import 'dart:io';

import 'package:chatloop/core/models/highlight_model.dart';
import 'package:chatloop/core/models/story_model.dart';
import 'package:chatloop/feature/login_main/dashboard/dashboard_provider.dart';
import 'package:chatloop/feature/login_main/login/login_screen.dart';
import 'package:chatloop/feature/screens/home/home_page/home_widgets.dart';
import 'package:chatloop/feature/screens/profile/edit_profile/edit_profile_screen.dart';
import 'package:chatloop/feature/screens/profile/highlights/highlights_service.dart';
import 'package:chatloop/feature/screens/profile/profile_provider.dart';
import 'package:chatloop/feature/screens/profile/story_archive/story_archive_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, String> userData;

  const ProfileScreen({super.key, required this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().fetchProfileBio();
    });
  }

  void _showEditBioDialog() {
    final provider = context.read<ProfileProvider>();
    final controller = TextEditingController(text: provider.bio);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Bio',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLength: 150,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Add your bio',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: isSaving
                        ? const Center(child: CircularProgressIndicator(color: Colors.black))
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: () async {
                              setState(() {
                                isSaving = true;
                              });
                              try {
                                await provider.updateBio(controller.text);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Bio updated successfully!')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setState(() {
                                    isSaving = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to update bio')),
                                  );
                                }
                              }
                            },
                            child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
                          ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showMenu(BuildContext context, ProfileProvider profileProvider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.settings_outlined,
                  color: Colors.black,
                ),
                title: const Text('Settings and privacy'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.black),
                title: const Text('Your activity'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_border, color: Colors.black),
                title: const Text('Saved'),
                onTap: () {},
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Log out',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context); // Close sheet
                  try {
                    await profileProvider.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    debugPrint('Logout error: $e');
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.userData;
    final highlightsNotifier = context.watch<HighlightsNotifier>();
    final highlights = highlightsNotifier.highlights;
    final profileProvider = context.read<ProfileProvider>();
    final profileProviderWatch = context.watch<ProfileProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final user = dashboardProvider.userProfile;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.lock_outline, size: 18, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                user?.username ?? userData['username'] ?? 'username',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.black),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_box_outlined, color: Colors.black),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () => _showMenu(context, profileProvider),
            ),
            const SizedBox(width: 10),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header (Pic + Stats)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Profile Picture
                          Container(
                            width: 90,
                            height: 90,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFFBAA47),
                                  Color(0xFFD91A46),
                                  Color(0xFFA60F93),
                                ],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                            ),
                            padding: const EdgeInsets.all(3),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(2),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    (user?.photoUrl != null &&
                                        user!.photoUrl.isNotEmpty)
                                    ? (user.photoUrl.startsWith('http')
                                          ? NetworkImage(user.photoUrl)
                                          : FileImage(File(user.photoUrl))
                                                as ImageProvider)
                                    : (userData['photoUrl'] != null &&
                                              userData['photoUrl']!.startsWith(
                                                'http',
                                              )
                                          ? NetworkImage(userData['photoUrl']!)
                                          : (userData['photoUrl'] != null &&
                                                    userData['photoUrl']!
                                                        .isNotEmpty
                                                ? FileImage(
                                                        File(
                                                          userData['photoUrl']!,
                                                        ),
                                                      )
                                                      as ImageProvider
                                                : null)),
                                child:
                                    (user?.photoUrl == null ||
                                            user!.photoUrl.isEmpty) &&
                                        (userData['photoUrl'] == null ||
                                            userData['photoUrl']!.isEmpty)
                                    ? const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          // Stats
                          const Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _ProfileStat(count: ' ', label: 'Posts'),
                                _ProfileStat(count: ' ', label: 'Followers'),
                                _ProfileStat(count: ' ', label: 'Following'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Name and Bio
                      Text(
                        profileProviderWatch.username.isNotEmpty ? profileProviderWatch.username : (user?.fullName ?? userData['name'] ?? 'Your Name'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      profileProviderWatch.isLoading
                          ? const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              profileProviderWatch.bio.isEmpty ? 'Add your bio' : profileProviderWatch.bio,
                              style: TextStyle(fontSize: 14, color: profileProviderWatch.bio.isEmpty ? Colors.blue : Colors.black),
                            ),
                      const SizedBox(height: 16),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context,
                              'Edit Profile',
                              onTap: () {
                                final currentBio = context.read<ProfileProvider>().bio;
                                final currentUsername = context.read<ProfileProvider>().username;
                                final updatedUserData = Map<String, String>.from(userData);
                                
                                updatedUserData['bio'] = currentBio;
                                if (currentUsername.isNotEmpty) {
                                  updatedUserData['username'] = currentUsername;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        EditProfileScreen(userData: updatedUserData),
                                  ),
                                ).then((_) {
                                  if (context.mounted) {
                                    context.read<ProfileProvider>().fetchProfileBio();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              context,
                              'Edit Bio',
                              onTap: _showEditBioDialog,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_add_outlined,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Highlights
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // "New" button — opens archive
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const StoryArchiveScreen(),
                                  ),
                                );
                                // Reload highlights if one was created
                                if (result == true) {
                                  highlightsNotifier.refresh();
                                }
                              },
                              child: _buildHighlight('New', isAdd: true),
                            ),
                            // Saved highlights
                            ...highlights.map(
                              (h) => GestureDetector(
                                onTap: () {
                                  // Build StoryData list from stored media
                                  final stories = List.generate(
                                    h.mediaUrls.length,
                                    (i) => StoryData(
                                      type:
                                          h.mediaTypes.length > i &&
                                              h.mediaTypes[i] == 'video'
                                          ? StoryMediaType.video
                                          : StoryMediaType.image,
                                      timestamp: DateTime.now(),
                                      userName: 'Me',
                                      mediaUrl: h.mediaUrls[i],
                                      thumbnailUrl: h.thumbnailUrls.length > i
                                          ? (h.thumbnailUrls[i].isNotEmpty
                                                ? h.thumbnailUrls[i]
                                                : null)
                                          : null,
                                    ),
                                  );
                                  if (stories.isNotEmpty) {
                                    HomeWidgets.showStoryView(
                                      context,
                                      stories,
                                      isHighlight: true,
                                    );
                                  }
                                },
                                onLongPress: () async {
                                  final del = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('"${h.name}"'),
                                      content: const Text(
                                        'Delete this highlight?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (del == true) {
                                    highlightsNotifier.delete(h.id);
                                  }
                                },
                                child: _buildHighlightFromModel(h),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    indicatorColor: Colors.black,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    tabs: [
                      Tab(icon: Icon(Icons.grid_on)),
                      Tab(icon: Icon(Icons.movie_outlined)),
                      Tab(icon: Icon(Icons.person_pin_outlined)),
                    ],
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildGridTab(),
              const Center(
                child: Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
              ),
              const Center(
                child: Icon(
                  Icons.person_pin_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildHighlight(String label, {bool isAdd = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                border: isAdd
                    ? Border.all(color: Colors.black, width: 1)
                    : null,
              ),
              child: isAdd
                  ? const Icon(Icons.add, color: Colors.black)
                  : const CircleAvatar(
                      backgroundColor: Colors.transparent,
                      backgroundImage: NetworkImage(
                        'https://picsum.photos/100',
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHighlightFromModel(HighlightModel h) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipOval(
              child: h.coverUrl.isNotEmpty
                  ? Image.network(
                      h.coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.photo, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 64,
            child: Text(
              h.name,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridTab() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: 0,
      itemBuilder: (context, index) {
        return const SizedBox.shrink();
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String count;
  final String label;

  const _ProfileStat({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.white, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

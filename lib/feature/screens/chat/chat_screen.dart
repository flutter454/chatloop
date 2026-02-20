import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatloop/feature/login_main/dashboard/dashboard_provider.dart';
import 'package:chatloop/feature/screens/chat/chat_note_screen/create_note_screen.dart';
import 'package:chatloop/feature/screens/chat/chat_note_screen/note_provider.dart';
import 'package:chatloop/feature/screens/chat/chat_provider.dart';
import 'package:chatloop/feature/screens/chat/messages.dart/message_screen.dart';
import 'package:chatloop/feature/screens/chat/widgets/active_user_item.dart';
import 'package:chatloop/feature/screens/chat/widgets/chat_tab.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: const _ChatScreenContent(),
    );
  }
}

class _ChatScreenContent extends StatelessWidget {
  const _ChatScreenContent();

  String _cleanUrl(String? url) {
    if (url == null || url.isEmpty) return 'https://i.pravatar.cc/150';
    if (url.contains(',')) {
      return url.split(',').first.trim();
    }
    return url;
  }

  Future<void> _refreshUsers(BuildContext context) async {
    await Provider.of<ChatProvider>(context, listen: false).refreshUsers();
  }

  void _openNoteScreen(
    BuildContext context,
    ChatProvider chatProvider,
    String userPhotoUrl,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateNoteScreen(
          initialNote: chatProvider.currentUserNote,
          userPhotoUrl: userPhotoUrl,
          onSave: chatProvider.updateUserNote,
          onSongSelected: chatProvider.updateCurrentSong,
        ),
      ),
    );
  }

  void _showSongDetailsSheet(
    BuildContext context,
    String noteId,
    String userPhotoUrl,
    String fullName,
    String username,
    String note,
    Map<String, String>? song,
  ) {
    // Load reactions for this specific note
    context.read<NoteProvider>().loadReactions(noteId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<NoteProvider>(
          builder: (context, noteProvider, child) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.5,
              width: double.infinity,
              margin: EdgeInsets.zero,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // User Profile and Name at Top
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: CachedNetworkImageProvider(
                          userPhotoUrl,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        fullName.isNotEmpty ? fullName : username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Note
                  if (note.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          note,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Song Info (Conditionally displayed)
                  if (song != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.music_note, color: Colors.purple),
                            const SizedBox(height: 5),
                            Text(
                              "${song['title']} - ${song['artist']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "🎶 Lyrics flow like forward... 🎶",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Comment and Like Section
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[200]!)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (value) {
                              noteProvider.addComment(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            noteProvider.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: noteProvider.isLiked
                                ? Colors.red
                                : Colors.grey,
                            size: 30,
                          ),
                          onPressed: () {
                            noteProvider.toggleLike();
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = Provider.of<DashboardProvider>(context);
    final userProfile = dashboardProvider.userProfile;
    final username = userProfile?.username ?? 'username';
    final userPhotoUrl = userProfile?.photoUrl ?? '';
    final fullName = userProfile?.fullName ?? '';
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    // Watch ChatProvider for changes
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refreshUsers(context),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.menu, size: 28),
                    Row(
                      children: [
                        Text(
                          username.isNotEmpty ? username : 'No UserName Found',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 20),
                      ],
                    ),
                    const Icon(Icons.edit_square, size: 24),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(Icons.search, color: Colors.grey[600], size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Search',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Users Data Content
              Expanded(
                child: _buildBody(
                  context,
                  chatProvider,
                  fullName,
                  username,
                  userPhotoUrl,
                  currentUserId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ChatProvider chatProvider,
    String fullName,
    String username,
    String userPhotoUrl,
    String currentUserId,
  ) {
    if (chatProvider.isLoading && chatProvider.users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatProvider.errorMessage != null && chatProvider.users.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 50,
                color: Colors.orange,
              ),
              const SizedBox(height: 10),
              Text(
                chatProvider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 20),
              const Text(
                "Action Required:\n1. Copy the SQL code provided\n2. Go to Supabase > SQL Editor\n3. Run the script to create the table",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _refreshUsers(context),
                child: const Text("Retry Connection"),
              ),
            ],
          ),
        ),
      );
    }

    final users = chatProvider.users;

    return CustomScrollView(
      slivers: [
        // Horizontal "Active / Notes" List
        SliverToBoxAdapter(
          child: SizedBox(
            height: 111, // Increased height to prevent overflow
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: users.length + 1, // +1 for current user
              itemBuilder: (context, index) {
                if (index == 0) {
                  // Current User Note
                  final userId = currentUserId;
                  final noteData = chatProvider.getNoteForUser(userId);
                  final String noteId = noteData?['id'] ?? '';
                  return ActiveUserItem(
                    name: fullName.isNotEmpty ? fullName : username,
                    imageUrl: userPhotoUrl.isNotEmpty
                        ? userPhotoUrl
                        : 'https://i.pravatar.cc/150?u=0',
                    isCurrentUser: true,
                    note: chatProvider.currentUserNote,
                    currentSong: chatProvider.currentSong,
                    onTap: () {
                      if (noteId.isNotEmpty &&
                          (chatProvider.currentUserNote.isNotEmpty ||
                              chatProvider.currentSong != null)) {
                        _showSongDetailsSheet(
                          context,
                          noteId,
                          userPhotoUrl,
                          fullName,
                          username,
                          chatProvider.currentUserNote,
                          chatProvider.currentSong,
                        );
                      } else {
                        _openNoteScreen(context, chatProvider, userPhotoUrl);
                      }
                    },
                  );
                }
                final user = users[index - 1];
                final userId = user['id'] as String;
                final noteData = chatProvider.getNoteForUser(userId);
                final noteText = noteData?['note_text'] ?? '';
                final String noteId = noteData?['id'] ?? '';
                Map<String, String>? noteSong;
                if (noteData != null && noteData['song_title'] != null) {
                  noteSong = {
                    'title': noteData['song_title'],
                    'artist': noteData['song_artist'] ?? '',
                    'image': noteData['song_url'] ?? '',
                  };
                }

                return ActiveUserItem(
                  name: chatProvider.getUserName(user),
                  imageUrl: chatProvider.getUserAvatar(user),
                  note: noteText,
                  currentSong: noteSong,
                  isCurrentUser: false,
                  onTap: () async {
                    if (noteId.isNotEmpty &&
                        (noteText.isNotEmpty || noteSong != null)) {
                      _showSongDetailsSheet(
                        context,
                        noteId,
                        chatProvider.getUserAvatar(user),
                        chatProvider.getUserName(user),
                        '', // Username not always needed if name is present
                        noteText,
                        noteSong,
                      );
                    } else {
                      // Start Chat if no note
                      final chatId = await chatProvider.startChat(userId);
                      if (chatId != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MessageScreen(
                              chatId: chatId,
                              friendId: userId,
                              friendName: chatProvider.getUserName(user),
                              friendPhoto: chatProvider.getUserAvatar(user),
                            ),
                          ),
                        ).then((_) => _refreshUsers(context));
                      }
                    }
                  },
                );
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 25)), // Added spacing
        // Tabs
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ChatTab(
                  title: 'Primary',
                  isSelected: chatProvider.selectedTabIndex == 0,
                  onTap: () => chatProvider.setTabIndex(0),
                ),
                ChatTab(
                  title: 'Requests',
                  isSelected: chatProvider.selectedTabIndex == 1,
                  onTap: () => chatProvider.setTabIndex(1),
                ),
                ChatTab(
                  title: 'General',
                  isSelected: chatProvider.selectedTabIndex == 2,
                  onTap: () => chatProvider.setTabIndex(2),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // Message List (Conversations)
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final chats = chatProvider.chats;

              if (chats.isEmpty) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text("No chats yet. Tap a user above to start!"),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final chat = chats[index];
              final friendProfile = chat['friend_profile'];
              final lastMessage = chat['last_message'];

              // Fallback if profile missing
              final String friendName = friendProfile != null
                  ? (friendProfile['full_name'] ??
                        friendProfile['username'] ??
                        'User')
                  : 'Unknown User';
              final String friendPhoto = _cleanUrl(
                friendProfile != null
                    ? (friendProfile['avatar_url'] ??
                          friendProfile['photo_url'])
                    : null,
              );
              final String friendId = friendProfile != null
                  ? friendProfile['id']
                  : '';

              String messageText = 'Start chatting';
              String timeText = '';
              bool isSeen = true;

              if (lastMessage != null) {
                messageText = lastMessage['text'] ?? '';
                final created = DateTime.parse(
                  lastMessage['created_at'],
                ).toLocal();
                timeText = DateFormat('h:mm a').format(created);
                isSeen = lastMessage['is_seen'] ?? false;
                if (lastMessage['sender_id'] == currentUserId)
                  isSeen = true; // My messages are always "seen" by me
              }

              return ListTile(
                dense: true, // Compact design
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2, // Reduced height
                ),
                leading: CircleAvatar(
                  radius: 22, // Reduced size (was 28)
                  backgroundImage: CachedNetworkImageProvider(friendPhoto),
                ),
                title: Text(
                  friendName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15, // Slightly smaller font
                  ),
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        messageText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSeen ? Colors.grey : Colors.black,
                          fontWeight: isSeen
                              ? FontWeight.normal
                              : FontWeight.bold,
                          fontSize: 13, // Slightly smaller font
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (timeText.isNotEmpty)
                      Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MessageScreen(
                        chatId: chat['id'],
                        friendId: friendId,
                        friendName: friendName,
                        friendPhoto: friendPhoto,
                      ),
                    ),
                  ).then((_) => _refreshUsers(context)); // Refresh on return
                },
              );
            },
            childCount: chatProvider.chats.isEmpty
                ? 1
                : chatProvider.chats.length,
          ),
        ),
      ],
    );
  }
}

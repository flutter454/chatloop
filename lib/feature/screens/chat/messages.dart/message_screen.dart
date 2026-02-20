import 'package:cached_network_image/cached_network_image.dart';
import 'package:chatloop/feature/screens/chat/messages.dart/message_screen_provider.dart';
import 'package:chatloop/feature/screens/chat/messages.dart/messages_widgets.dart'; // Import widgets
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessageScreen extends StatefulWidget {
  final String chatId;
  final String friendId;
  final String friendName;
  final String friendPhoto;

  const MessageScreen({
    super.key,
    required this.chatId,
    required this.friendId,
    required this.friendName,
    required this.friendPhoto,
  });

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late final String _currentUserId;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentUserId = Supabase.instance.client.auth.currentUser!.id;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: -100, // Allow dragging up to 100px left
      upperBound: 0,
      value: 0,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    // With reverse: true, bottom is offset 0.0
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MessageScreenProvider()..init(widget.chatId),
      child: Consumer<MessageScreenProvider>(
        builder: (context, provider, child) {
          // Scroll to bottom on initial load completion
          if (!provider.isLoading && provider.messages.isNotEmpty) {
            // We only scroll if we haven't scrolled yet? Or rely on user?
            // Simple logic: If newly loaded, scroll.
            // But 'builder' runs on every update.
            // We can check if controller is attached and we are at the end?
            // Or just scroll on new message addition?
            // For now, let's keep it simple: the provider handles data.
            // We can use a post frame callback to scroll if needed,
            // but forcing scroll on every build is bad if user scrolled up.
            // We rely on the fact that when user sends message, we call _scrollToBottom
            // in the sendMessage method (if it was in widget).
            // Since sendMessage is now in provider, we need to trigger scroll from UI.
            // provider.sendMessage is async. We can await it.
          }

          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(
                      cleanUrl(widget.friendPhoto),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.friendName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      // Only allow dragging left (negative values)
                      double newVal = provider.dragOffset + details.delta.dx;
                      newVal = newVal.clamp(-100.0, 0.0);

                      // Update provider
                      provider.updateDragOffset(newVal);

                      // Sync controller value without setState so animation starts from here
                      _animationController.value = newVal;
                    },
                    onHorizontalDragEnd: (details) {
                      // Snap back to 0
                      // We attach a listener solely for this animation to update the provider
                      void listener() {
                        provider.updateDragOffset(_animationController.value);
                      }

                      _animationController.addListener(listener);

                      _animationController
                          .animateTo(
                            0,
                            curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 200),
                          )
                          .then((_) {
                            _animationController.removeListener(listener);
                            provider.updateDragOffset(0);
                          });
                    },
                    child: Builder(
                      builder: (context) {
                        if (provider.isLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (provider.error != null) {
                          return Center(
                            child: Text('Error: ${provider.error}'),
                          );
                        }
                        final allMessages = provider.messages;
                        if (allMessages.isEmpty) {
                          return const Center(
                            child: Text('No messages yet. Say hi! 👋'),
                          );
                        }

                        return ListView.builder(
                          reverse: true, // Start from bottom
                          controller: _scrollController,
                          itemCount: allMessages.length,
                          itemBuilder: (context, index) {
                            final msg = allMessages[index];
                            final isMe =
                                msg['sender_id'] == provider.currentUserId;
                            final time = DateTime.parse(
                              msg['created_at'],
                            ).toLocal();
                            final isOptimistic = msg['is_optimistic'] == true;

                            // Grouping Logic (Reversed List: index-1 is Newer/Below)
                            // We show avatar if the message BELOW (newer) is from a different sender,
                            // or if this is the newest message (index 0).
                            final newerMsg = (index > 0)
                                ? allMessages[index - 1]
                                : null;

                            final bool isLastInGroup =
                                !isMe &&
                                (newerMsg == null ||
                                    newerMsg['sender_id'] != msg['sender_id']);

                            // Margin bottom: If newer message (visually below) is same sender, small margin.
                            final double marginBottom =
                                (newerMsg != null &&
                                    newerMsg['sender_id'] == msg['sender_id'])
                                ? 2
                                : 10;

                            // Use Transform with provider.dragOffset
                            return Transform.translate(
                              offset: Offset(provider.dragOffset, 0),
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.centerRight,
                                children: [
                                  // The Timestamp (Hidden off-screen to the right)
                                  Positioned(
                                    right: -70,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: SizedBox(
                                        width: 60,
                                        child: Text(
                                          DateFormat('h:mm a').format(time),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // The Message Bubble
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: marginBottom,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: isMe
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (!isMe) ...[
                                          const SizedBox(width: 8),
                                          if (isLastInGroup)
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundImage:
                                                  CachedNetworkImageProvider(
                                                    cleanUrl(
                                                      widget.friendPhoto,
                                                    ),
                                                  ),
                                            )
                                          else
                                            const SizedBox(width: 32),
                                          const SizedBox(width: 8),
                                        ],
                                        Flexible(
                                          child: GestureDetector(
                                            onLongPress: () {
                                              showMessageOptions(
                                                context,
                                                msg,
                                                _focusNode,
                                              );
                                            },
                                            child: Container(
                                              constraints: BoxConstraints(
                                                maxWidth:
                                                    MediaQuery.of(
                                                      context,
                                                    ).size.width *
                                                    0.75,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                    horizontal: 16,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isMe
                                                    ? const Color(0xFF6200EE)
                                                    : Colors.grey[200],
                                                borderRadius: BorderRadius.only(
                                                  topLeft:
                                                      const Radius.circular(20),
                                                  topRight:
                                                      const Radius.circular(20),
                                                  bottomLeft: isMe
                                                      ? const Radius.circular(
                                                          20,
                                                        )
                                                      : const Radius.circular(
                                                          4,
                                                        ),
                                                  bottomRight: isMe
                                                      ? const Radius.circular(4)
                                                      : const Radius.circular(
                                                          20,
                                                        ),
                                                ),
                                                boxShadow: isOptimistic
                                                    ? []
                                                    : [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(
                                                                0.05,
                                                              ),
                                                          blurRadius: 2,
                                                          offset: const Offset(
                                                            0,
                                                            1,
                                                          ),
                                                        ),
                                                      ],
                                              ),
                                              child: Opacity(
                                                opacity: isOptimistic
                                                    ? 0.7
                                                    : 1.0,
                                                child: Text(
                                                  msg['text'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: isMe
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (isMe) const SizedBox(width: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  color: Colors.white,
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        // Camera Button
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Text Input Area (Includes Reply Preview)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Reply Preview
                              if (provider.replyToMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border(
                                      left: BorderSide(
                                        color: Colors.blueAccent,
                                        width: 4,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.reply,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              provider.replyToMessage!['sender_id'] ==
                                                      provider.currentUserId
                                                  ? 'You'
                                                  : widget.friendName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.blueAccent,
                                              ),
                                            ),
                                            Text(
                                              provider.replyToMessage!['text'] ??
                                                  '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () {
                                          provider.clearReply();
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                              // Text Field
                              TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                decoration: InputDecoration(
                                  hintText: 'Message...',
                                  hintStyle: TextStyle(color: Colors.grey[600]),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none,
                                  ),
                                  isDense: true,
                                ),
                                minLines: 1,
                                maxLines: 4,
                                onSubmitted: (_) async {
                                  final text = _controller.text;
                                  _controller.clear(); // Clear immediately
                                  await provider.sendMessage(
                                    widget.chatId,
                                    text,
                                  );
                                  _scrollToBottom();
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),
                        // Send Button
                        GestureDetector(
                          onTap: () async {
                            final text = _controller.text;
                            _controller.clear(); // Clear immediately
                            await provider.sendMessage(widget.chatId, text);
                            _scrollToBottom();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.send,
                              color: Colors.blueAccent,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

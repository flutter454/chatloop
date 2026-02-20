import 'package:chatloop/feature/screens/chat/messages.dart/message_screen_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Helper function to show options
void showMessageOptions(
  BuildContext context,
  Map<String, dynamic> msg,
  FocusNode focusNode,
) {
  // We pass context to access Provider
  final provider = Provider.of<MessageScreenProvider>(context, listen: false);
  final String currentUserId = provider.currentUserId;
  final bool isMe = msg['sender_id'] == currentUserId;
  final time = DateTime.parse(msg['created_at']).toLocal();
  final formattedTime = DateFormat('d MMM, h:mm a').format(time);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.pop(context),
        child: Align(
          alignment: Alignment.bottomRight,
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping the menu itself
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                right: 16,
                top: kToolbarHeight + 40,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Super React Section
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Text(
                                'Tap and hold to super react',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  buildReactionEmoji('❤️'),
                                  buildReactionEmoji('😂'),
                                  buildReactionEmoji('😮'),
                                  buildReactionEmoji('😢'),
                                  buildReactionEmoji('😡'),
                                  buildReactionEmoji('👍'),
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[200],
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Divider(height: 1),

                        // 2. Menu Options
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedTime,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              buildMenuOption(
                                icon: Icons.reply,
                                label: 'Reply',
                                onTap: () {
                                  Navigator.pop(context);
                                  provider.setReplyTo(msg);
                                  focusNode.requestFocus();
                                },
                              ),
                              buildMenuOption(
                                icon: Icons.emoji_emotions_outlined,
                                label: 'Add sticker',
                                onTap: () => Navigator.pop(context),
                              ),
                              buildMenuOption(
                                icon: Icons.forward,
                                label: 'Forward',
                                onTap: () => Navigator.pop(context),
                              ),
                              buildMenuOption(
                                icon: Icons.copy,
                                label: 'Copy',
                                onTap: () async {
                                  final text = msg['text'] as String?;
                                  if (text != null && text.isNotEmpty) {
                                    await Clipboard.setData(
                                      ClipboardData(text: text),
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Message copied to clipboard',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Cannot copy empty message',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                              buildMenuOption(
                                icon: Icons.image_outlined,
                                label: 'Make AI image',
                                onTap: () => Navigator.pop(context),
                              ),
                              if (isMe)
                                buildMenuOption(
                                  icon: Icons.undo,
                                  label: 'Unsend',
                                  textColor: Colors.red,
                                  iconColor: Colors.red,
                                  onTap: () {
                                    Navigator.pop(context);
                                    provider.unsendMessage(msg['id']);
                                  },
                                ),
                              buildMenuOption(
                                label: 'More',
                                onTap: () => Navigator.pop(context),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

Widget buildReactionEmoji(String emoji) {
  return Text(emoji, style: const TextStyle(fontSize: 28));
}

Widget buildMenuOption({
  IconData? icon,
  required String label,
  required VoidCallback onTap,
  Color textColor = const Color(0xFF1F1F1F),
  Color iconColor = const Color(0xFF1F1F1F),
  bool isLast = false,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12.0,
      ), // increased vertical padding
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 16),
          ] else
            const SizedBox(width: 38), // Indent for text-only items like "More"

          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    ),
  );
}

String cleanUrl(String? url) {
  if (url == null || url.isEmpty) return 'https://i.pravatar.cc/150';
  if (url.contains(',')) {
    return url.split(',').first.trim();
  }
  return url;
}

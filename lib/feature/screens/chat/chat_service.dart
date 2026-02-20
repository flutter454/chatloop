import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 1. Get or Create Chat (Prevents duplicates)
  // Checks for existing chat between current user and friend.
  // We enforce an ordering of IDs to ensure uniqueness: a single chat for (A, B) regardless of who initiated.
  // Alternatively, we check both (A,B) and (B,A) existence.
  Future<String> getOrCreateChat(String currentUserId, String friendId) async {
    // Determine user1 and user2 based on sorting to ensure consistency if we used a unique constraint (u1 < u2).
    // However, the prompt asks to check both directions.
    // Let's try to find an existing chat first.

    final response = await _supabase
        .from('chats')
        .select()
        .or(
          'and(user1_id.eq.$currentUserId,user2_id.eq.$friendId),and(user1_id.eq.$friendId,user2_id.eq.$currentUserId)',
        )
        .maybeSingle();

    if (response != null) {
      return response['id'] as String;
    }

    // No chat exists, create a new one.
    // We can just insert. Trigger or RLS will handle the rest.
    final newChat = await _supabase
        .from('chats')
        .insert({
          'user1_id': currentUserId,
          'user2_id': friendId,
          // 'created_at': now(), // Default
          // 'last_message_at': now(), // Default from trigger/table definition
        })
        .select()
        .single();

    return newChat['id'] as String;
  }

  // 2. Send Message
  Future<Map<String, dynamic>> sendMessage(
    String chatId,
    String currentUserId,
    String text,
  ) async {
    return await _supabase
        .from('messages')
        .insert({
          'chat_id': chatId,
          'sender_id': currentUserId,
          'text': text,
          // 'created_at' is default
          // 'is_seen' is false default
        })
        .select()
        .single();
  }

  // 3. Stream Messages (Realtime)
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    // We stream all messages for the chat, ordered by creation time.
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .limit(100);
  }

  // 4. Mark Messages as Seen
  Future<void> markMessagesAsSeen(String chatId, String currentUserId) async {
    // Update all messages in this chat where the sender is NOT the current user
    // and is_seen is false.
    await _supabase
        .from('messages')
        .update({'is_seen': true})
        .eq('chat_id', chatId)
        .neq('sender_id', currentUserId)
        .eq('is_seen', false);
  }

  // 5. Get My Chats Stream (List with Last Message)
  Stream<List<Map<String, dynamic>>> getChatsStream(String currentUserId) {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .map((chats) {
          // Client-side filter because stream modifiers are limited for OR conditions across columns in some versions
          // But actually we can try to rely on the fact that if we just stream 'chats', we get all public updates?
          // No, we need to filter.
          // Supabase Realtime Postgres Changes supports simple filters.
          // OR filters in stream() might be tricky.
          // If we cannot easily filter 'OR' in stream, we might stream ALL chats (bad for scale) or rely on RLS.
          // If RLS is set up properly (Policy: Users can only select their own chats), then `.stream(primaryKey: ['id'])` will strictly return ONLY the user's chats.
          // ASSUMPTION: RLS is set up.
          return chats;
        });
  }

  // Helper to enrich chat data (Profiles + Last Message)
  Future<List<Map<String, dynamic>>> enrichChats(
    List<Map<String, dynamic>> chats,
    String currentUserId,
  ) async {
    if (chats.isEmpty) return [];

    try {
      // 2. Collect unique friend IDs
      final Set<String> friendIds = {};
      for (var chat in chats) {
        String u1 = chat['user1_id'];
        String u2 = chat['user2_id'];
        if (u1 != currentUserId) friendIds.add(u1);
        if (u2 != currentUserId) friendIds.add(u2);
      }

      if (friendIds.isEmpty) return chats;

      // 3. Fetch Profiles for friends
      final profilesResponse = await _supabase
          .from('profiles')
          .select()
          .filter('id', 'in', '(${friendIds.join(',')})');

      final Map<String, Map<String, dynamic>> profilesMap = {
        for (var p in profilesResponse) p['id'] as String: p,
      };

      // 4. Merge Data & Fetch Last Message
      final List<Map<String, dynamic>> enrichedChats = [];

      for (var chat in chats) {
        // Create a mutable copy
        final chatConfigured = Map<String, dynamic>.from(chat);

        String u1 = chatConfigured['user1_id'];
        String u2 = chatConfigured['user2_id'];
        String friendId = (u1 == currentUserId) ? u2 : u1;

        chatConfigured['friend_profile'] = profilesMap[friendId];

        // Fetch last message content
        // Optimization: create database index on (chat_id, created_at)
        final msgResponse = await _supabase
            .from('messages')
            .select('text, created_at, is_seen, sender_id')
            .eq('chat_id', chatConfigured['id'])
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (msgResponse != null) {
          chatConfigured['last_message'] = msgResponse;
        }
        enrichedChats.add(chatConfigured);
      }
      return enrichedChats;
    } catch (e) {
      debugPrint('Error enriching chats: $e');
      return chats;
    }
  }

  // Deprecated: used for one-time fetch, better to use stream
  Future<List<Map<String, dynamic>>> getMyChats(String currentUserId) async {
    // ... existing implementation remains as fallback or initial load ...
    // Reuse enrichChats logic to avoid duplication if we wanted to refactor fully.
    // For now keeping simpler to avoid breaking too much.
    final response = await _supabase
        .from('chats')
        .select()
        .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
        .order('last_message_at', ascending: false);

    return enrichChats(
      List<Map<String, dynamic>>.from(response),
      currentUserId,
    );
  }

  // 6. Delete Message
  Future<void> removeMessage(String messageId) async {
    debugPrint('Deleting message: $messageId');
    await _supabase.from('messages').delete().eq('id', messageId);
  }
}

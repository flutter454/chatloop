import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://fjrmnhrhgqixwnhgspts.supabase.co',
    anonKey: 'sb_publishable_o9gLRtu8nOqRyWrMyHc0BQ_V8lKW3QU',
  );
  
  final client = Supabase.instance.client;
  final posts = await client.from('usersposts').select('*, profiles(full_name, username, avatar_url)').order('created_at', ascending: false);
  
  print('==== POSTS ====');
  for (var p in posts) {
    print('User ID: ${p['user_id']}');
    print('Caption: ${p['caption']}');
    print('Profile: ${p['profiles']}');
    print('----------------');
  }
}

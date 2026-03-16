import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://fjrmnhrhgqixwnhgspts.supabase.co',
    'sb_publishable_o9gLRtu8nOqRyWrMyHc0BQ_V8lKW3QU',
  );

  try {
    final response = await supabase.from('profiles').select('id, full_name, avatar_url').limit(5);
    print('PROFILES (full_name, avatar_url):');
    print(response);
  } catch (e) {
    print('Failed to get profiles: $e');
  }
}

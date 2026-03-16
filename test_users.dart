import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://fjrmnhrhgqixwnhgspts.supabase.co',
    'sb_publishable_o9gLRtu8nOqRyWrMyHc0BQ_V8lKW3QU',
  );

  try {
    final response = await supabase.from('users').select('*').limit(1);
    print('USERS table exists.');
  } catch (e) {
    print('USERS table failed: $e');
  }
}

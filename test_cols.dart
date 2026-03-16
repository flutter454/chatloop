import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://fjrmnhrhgqixwnhgspts.supabase.co',
    'sb_publishable_o9gLRtu8nOqRyWrMyHc0BQ_V8lKW3QU',
  );

  try {
    final response = await supabase.from('usersposts').select('*').limit(1);
    print('Columns:');
    print((response as List).first.keys.toList());
  } catch (e) {
    print('Failed: $e');
  }
}

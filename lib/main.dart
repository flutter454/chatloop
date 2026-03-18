import 'package:chatloop/core/services/sharedpreference.dart';
import 'package:chatloop/feature/login_main/dashboard/dashboard_provider.dart';
import 'package:chatloop/feature/login_main/splash/splash_screen.dart';
import 'package:chatloop/feature/screens/home/home_page/home_page_provider.dart';
import 'package:chatloop/feature/screens/home/story/story_provider.dart';
import 'package:chatloop/feature/screens/posts/post_provider.dart';
import 'package:chatloop/feature/screens/profile/highlights/highlights_service.dart';
import 'package:chatloop/feature/screens/profile/profile_provider.dart';
import 'package:chatloop/feature/screens/reels/reels_provider.dart';
import 'package:chatloop/feature/screens/chat/chat_provider.dart';
import 'package:chatloop/feature/screens/chat/chat_note_screen/note_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

late Size mediaQuery;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenceService.init();

  await Supabase.initialize(
    url: 'https://fjrmnhrhgqixwnhgspts.supabase.co',
    anonKey: 'sb_publishable_o9gLRtu8nOqRyWrMyHc0BQ_V8lKW3QU',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoryProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => HomePageProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        ChangeNotifierProvider(create: (_) => ReelsProvider()),
        ChangeNotifierProvider(create: (_) => HighlightsNotifier()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}

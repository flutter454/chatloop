import 'package:chatloop/core/models/userdata_profile.dart';
import 'package:chatloop/feature/screens/chat/chat_screen.dart';
import 'package:chatloop/feature/screens/home/home_page/home_screen.dart';
import 'package:chatloop/feature/screens/home/search/search_screen.dart';
import 'package:chatloop/feature/screens/reels/reels_screen.dart';
import 'package:chatloop/feature/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'dashboard_provider.dart';
import 'dashboard_widgets.dart';

class Dashboard extends StatefulWidget {
  final Map<String, String> userData;
  const Dashboard({super.key, required this.userData});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().setUserProfile(
        UserProfile.fromMap(widget.userData),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreen(),
      const SearchScreen(),
      const ReelsScreen(),
      const ChatScreen(),
      ProfileScreen(userData: widget.userData),
    ];

    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          extendBody: true,
          body: Container(
            color: Colors.white,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: pages[provider.selectedIndex],
            ),
          ),
          bottomNavigationBar: CustomBottomBar(provider: provider),
        );
      },
    );
  }
}

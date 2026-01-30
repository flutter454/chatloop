// ignore_for_file: deprecated_member_use

import 'package:chatloop/feature/login/login_screen.dart';
import 'package:chatloop/feature/userdetails.dart/userdetails.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Wait for 3 seconds for the splash effect
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    debugPrint('SplashScreen: Checking login status... result: $isLoggedIn');

    if (!mounted) return;

    if (isLoggedIn) {
      // Load stored data to pass to UserDetails
      final Map<String, String> userData = {
        'fullName': prefs.getString('fullName') ?? '',
        'username': prefs.getString('username') ?? '',
        'email': prefs.getString('email') ?? '',
        'photoUrl': prefs.getString('photoUrl') ?? '',
        'dob': prefs.getString('dob') ?? '',
        'gender': prefs.getString('gender') ?? '',
        'instagram': prefs.getString('instagram') ?? '',
        'youtube': prefs.getString('youtube') ?? '',
      };

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserDetails(userData: userData),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8338EC), // Vibrant Purple
              Color(0xFFFF006E), // Vibrant Pink
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Heart Logo for Love Line
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
              child: Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFF006E),
                    size: 60,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // App Name - Love Line with stylistic font
            // const Text(
            //   "Love Line",
            //   style: TextStyle(
            //     fontSize: 56,
            //     fontWeight: FontWeight.w800,
            //     color: Colors.white,
            //     letterSpacing: -1.0,
            //     shadows: [
            //       Shadow(
            //         color: Colors.black26,
            //         offset: Offset(0, 4),
            //         blurRadius: 10,
            //       ),
            //     ],
            //   ),
            // ),
            //screen
            const SizedBox(height: 8),

            // Subtitle
            Text(
              "Find your perfect loop",
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 18,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

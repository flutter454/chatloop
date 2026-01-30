// ignore_for_file: deprecated_member_use

import 'package:chatloop/feature/userdetails.dart/userdetails.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page_widgets.dart';
import 'login_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn && mounted) {
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
        MaterialPageRoute(builder: (_) => UserDetails(userData: userData)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginProvider(),
      child: Consumer<LoginProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            primary: false,

            backgroundColor: const Color(0xFFFFEBF2),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 40.0,
                ),
                child: Form(
                  key: provider.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Complete Your Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4A4A4A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Join the Love Line community',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8E8E8E),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SlideToActionButton(
                        text: 'Slide to Sign In with Google',
                        icon: Image.network(
                          'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                          width: 24,
                          height: 24,
                        ),
                        actionColor: Colors.white,
                        baseColor: const Color(0xFFF5F5F5),
                        onAction: () async {
                          final userData = await provider.signInWithGoogle();
                          if (userData != null && mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserDetails(userData: userData),
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Sign-In failed. Please check your internet or Firebase console settings (SHA-1).',
                                ),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.withOpacity(0.3),
                              thickness: 1,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Color(0xFF8E8E8E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.withOpacity(0.3),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      ProfileTextField(
                        controller: provider.fullNameController,
                        hintText: 'Full Name',
                        prefixIcon: Icons.person_outline,
                        validator: provider.validateFullName,
                      ),
                      const SizedBox(height: 16),

                      ProfileTextField(
                        controller: provider.usernameController,
                        hintText: 'Username',
                        prefixIcon: Icons.alternate_email,
                        validator: provider.validateUsername,
                      ),
                      const SizedBox(height: 16),

                      ProfileTextField(
                        controller: provider.dobController,
                        hintText: 'Date of Birth',
                        prefixIcon: Icons.cake_outlined,
                        readOnly: true,
                        onTap: () => provider.selectDate(context),
                        validator: provider.validateDOB,
                      ),
                      const SizedBox(height: 16),

                      ProfileDropdownField(
                        value: provider.selectedGender,
                        hintText: 'Gender',
                        prefixIcon: Icons.people_outline,
                        items: provider.genderOptions,
                        onChanged: provider.setGender,
                        validator: (v) =>
                            v == null ? 'Please select gender' : null,
                      ),
                      const SizedBox(height: 16),

                      ProfileTextField(
                        controller: provider.instagramController,
                        hintText: 'Instagram Username',
                        prefixIcon: Icons.camera_alt_outlined,
                        validator: provider.validateInstagram,
                      ),
                      const SizedBox(height: 16),

                      ProfileTextField(
                        controller: provider.youtubeController,
                        hintText: 'YouTube Channel Username',
                        prefixIcon: Icons.video_library_outlined,
                        validator: provider.validateYoutube,
                      ),
                      const SizedBox(height: 48),

                      SlideToActionButton(
                        text: 'Slide to Finish',
                        enabled: provider.isFormValid,
                        icon: const Icon(Icons.check, color: Colors.white),
                        onAction: () async {
                          if (!provider.isFormValid) return;

                          bool success = await provider.login();

                          if (success && mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserDetails(
                                  userData: {
                                    'fullName':
                                        provider.fullNameController.text,
                                    'username':
                                        provider.usernameController.text,
                                    'dob': provider.dobController.text,
                                    'gender': provider.selectedGender ?? '',
                                    'instagram':
                                        provider.instagramController.text,
                                    'youtube': provider.youtubeController.text,
                                  },
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
//data
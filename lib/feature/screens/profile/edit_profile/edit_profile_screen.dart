import 'package:chatloop/feature/login_main/dashboard/dashboard_provider.dart';
import 'package:chatloop/feature/screens/profile/edit_profile/edit_profile_provider.dart';
import 'package:chatloop/feature/screens/profile/edit_profile/edit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, String> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.userData['fullName'] ?? widget.userData['name'],
    );
    _usernameController = TextEditingController(
      text: widget.userData['username'] ?? '',
    );
    _bioController = TextEditingController(text: widget.userData['bio'] ?? '');
    _emailController.text = widget.userData['email'] ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EditProfileProvider(),
      child: Consumer<EditProfileProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: const Text('Edit Profile'),
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
              titleTextStyle: const TextStyle(
                color: Color(0xFF4A4A4A),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              actions: [
                if (provider.isUploading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(right: 16.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFFF4081),
                        ),
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.check, color: Color(0xFFFF4081)),
                    onPressed: () async {
                      final success = await provider.saveProfile(
                        context: context,
                        fullName: _fullNameController.text,
                        username: _usernameController.text,
                        bio: _bioController.text,
                        userData: widget.userData,
                      );
                      if (success && context.mounted) {
                        context.read<DashboardProvider>().refreshUserProfile();
                        Navigator.pop(context, true);
                      }
                    },
                  ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  ProfileImagePicker(
                    isUploading: provider.isUploading,
                    imageFile: provider.imageFile,
                    photoUrl: widget.userData['photoUrl'],
                    email: widget.userData['email'],
                    onPickImage: () => provider.pickImage(),
                  ),
                  const SizedBox(height: 32),
                  EditTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  EditTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 20),
                  EditTextField(
                    controller: _bioController,
                    label: 'Bio',
                    icon: Icons.info_outline,
                  ),
                  const SizedBox(height: 20),
                  EditTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    readOnly: true,
                  ),
                  const SizedBox(height: 40),
                  EditSaveButton(
                    isUploading: provider.isUploading,
                    onPressed: () async {
                      final success = await provider.saveProfile(
                        context: context,
                        fullName: _fullNameController.text,
                        username: _usernameController.text,
                        bio: _bioController.text,
                        userData: widget.userData,
                      );
                      if (success && context.mounted) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

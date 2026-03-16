import 'dart:io';

import 'package:chatloop/feature/login_main/dashboard/dashboard_provider.dart';
import 'package:chatloop/feature/screens/profile/edit_profile/edit_profile_provider.dart';
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
      text: widget.userData['username'],
    );
    _bioController = TextEditingController(
      text: widget.userData['bio'],
    );
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
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF4081),
                            width: 2,
                          ),
                        ),
                        child: provider.isUploading
                            ? const CircularProgressIndicator(
                                color: Color(0xFFFF4081),
                              )
                            : ClipOval(
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  color: const Color(0xFFFFEBF2),
                                  child: provider.imageFile != null
                                      ? Image.file(
                                          provider.imageFile!,
                                          fit: BoxFit.cover,
                                        )
                                      : (widget.userData['photoUrl'] != null &&
                                                widget
                                                    .userData['photoUrl']!
                                                    .isNotEmpty
                                            ? (widget.userData['photoUrl']!
                                                      .startsWith('http')
                                                  ? Image.network(
                                                      widget
                                                          .userData['photoUrl']!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        // Fallback to initial if network error
                                                        return Center(
                                                          child: Text(
                                                            widget.userData['email'] !=
                                                                    null
                                                                ? widget
                                                                      .userData['email']![0]
                                                                      .toUpperCase()
                                                                : '?',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 40,
                                                                  color: Color(
                                                                    0xFFFF4081,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Image.file(
                                                      File(
                                                        widget
                                                            .userData['photoUrl']!,
                                                      ),
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Center(
                                                          child: Text(
                                                            widget.userData['email'] !=
                                                                    null
                                                                ? widget
                                                                      .userData['email']![0]
                                                                      .toUpperCase()
                                                                : '?',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 40,
                                                                  color: Color(
                                                                    0xFFFF4081,
                                                                  ),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                    ))
                                            : Center(
                                                child: Text(
                                                  widget.userData['email'] !=
                                                          null
                                                      ? widget
                                                            .userData['email']![0]
                                                            .toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    fontSize: 40,
                                                    color: Color(0xFFFF4081),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )),
                                ),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => provider.pickImage(),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF4081),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.alternate_email,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _bioController,
                    label: 'Bio',
                    icon: Icons.info_outline,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    readOnly: true,
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: provider.isUploading
                        ? null
                        : () async {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4081),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFFFF4081).withOpacity(0.4),
                    ),
                    child: provider.isUploading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey[100] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D2D2D),
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFFFF4081)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

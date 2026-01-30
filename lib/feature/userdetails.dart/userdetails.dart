import 'package:chatloop/feature/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserDetails extends StatelessWidget {
  final Map<String, String> userData;
  ////

  const UserDetails({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFFFF4081),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFFFF4081),
              backgroundImage:
                  userData['photoUrl'] != null &&
                      userData['photoUrl']!.isNotEmpty
                  ? NetworkImage(userData['photoUrl']!)
                  : null,
              child:
                  userData['photoUrl'] == null || userData['photoUrl']!.isEmpty
                  ? const Icon(Icons.person, size: 60, color: Colors.white)
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              userData['fullName'] ?? 'User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '@${userData['username']}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: [
                  if (userData.containsKey('email') &&
                      userData['email']!.isNotEmpty)
                    _infoTile(
                      Icons.email_outlined,
                      'Email',
                      userData['email']!,
                    ),
                  _infoTile(Icons.cake, 'Date of Birth', userData['dob']!),
                  _infoTile(
                    Icons.person_outline,
                    'Gender',
                    userData['gender']!,
                  ),
                  _infoTile(
                    Icons.camera_alt_outlined,
                    'Instagram',
                    userData['instagram']!,
                  ),
                  _infoTile(
                    Icons.video_library_outlined,
                    'YouTube',
                    userData['youtube']!,
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', false);
                // Clear user data as well for privacy
                await prefs.clear();

                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4081),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFFF4081)),
        title: Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

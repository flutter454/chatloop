import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginProvider extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController youtubeController = TextEditingController();

  DateTime? selectedDate;
  String? selectedGender;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  LoginProvider() {
    fullNameController.addListener(_onFieldChanged);
    usernameController.addListener(_onFieldChanged);
    dobController.addListener(_onFieldChanged);
    instagramController.addListener(_onFieldChanged);
    youtubeController.addListener(_onFieldChanged);
  }

  final List<String> genderOptions = ['Male', 'Female', 'Other'];

  void _onFieldChanged() {
    notifyListeners();
  }

  void setGender(String? gender) {
    selectedGender = gender;
    notifyListeners();
  }

  //
  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 13)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF4081),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      selectedDate = picked;
      dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      notifyListeners();
    }
  }

  // Validators
  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) return 'Full Name cannot be null';
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Username cannot be null';
    if (value.length < 3) return 'Username must be at least 3 characters';
    return null;
  }

  String? validateDOB(String? value) {
    if (value == null || value.isEmpty) return 'Date of Birth is required';
    if (selectedDate != null) {
      final now = DateTime.now();
      int age = now.year - selectedDate!.year;
      if (now.month < selectedDate!.month ||
          (now.month == selectedDate!.month && now.day < selectedDate!.day)) {
        age--;
      }
      if (age < 13) return 'You must be 13 years or older';
    }
    return null;
  }

  String? validateInstagram(String? value) {
    if (value == null || value.isEmpty) {
      return 'Instagram Username cannot be null';
    }
    return null;
  }

  String? validateYoutube(String? value) {
    if (value == null || value.isEmpty) return 'Youtube channel cannot be null';
    return null;
  }

  Future<bool> login() async {
    if (formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('fullName', fullNameController.text);
      await prefs.setString('username', usernameController.text);
      await prefs.setString('dob', dobController.text);
      await prefs.setString('gender', selectedGender ?? '');
      await prefs.setString('instagram', instagramController.text);
      await prefs.setString('youtube', youtubeController.text);
      return true;
    }
    return false;
  }

  Future<Map<String, String>?> signInWithGoogle() async {
    try {
      debugPrint('Starting Google Sign-In...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('Google Sign-In was cancelled by the user.');
        return null;
      }

      debugPrint('Sign-In successful: ${googleUser.email}');

      final prefs = await SharedPreferences.getInstance();

      // Save all details
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('fullName', googleUser.displayName ?? '');
      await prefs.setString('email', googleUser.email);
      await prefs.setString('photoUrl', googleUser.photoUrl ?? '');
      await prefs.setString('username', googleUser.email.split('@')[0]);
      await prefs.setString('dob', 'Not provided');
      await prefs.setString('gender', 'Not provided');
      await prefs.setString('instagram', 'Not provided');
      await prefs.setString('youtube', 'Not provided');

      return {
        'fullName': googleUser.displayName ?? '',
        'email': googleUser.email,
        'photoUrl': googleUser.photoUrl ?? '',
        'username': googleUser.email.split('@')[0],
        'dob': 'Not provided',
        'gender': 'Not provided',
        'instagram': 'Not provided',
        'youtube': 'Not provided',
      };
    } catch (error) {
      debugPrint('CRITICAL: Google Sign-In Error: $error');
      return null;
    }
  }

  bool get isFormValid {
    return fullNameController.text.trim().isNotEmpty &&
        usernameController.text.trim().isNotEmpty &&
        dobController.text.trim().isNotEmpty &&
        selectedGender != null &&
        instagramController.text.trim().isNotEmpty &&
        youtubeController.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    dobController.dispose();
    instagramController.dispose();
    youtubeController.dispose();
    super.dispose();
  }
}

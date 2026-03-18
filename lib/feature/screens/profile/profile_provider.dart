// ignore_for_file: avoid_print

import 'package:chatloop/core/services/sharedpreference.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileProvider extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Match the Web Client ID used in LoginProvider
    serverClientId:
        '895215285404-s5lj8gc43cjl51neu23vgekh8cb9jbti.apps.googleusercontent.com',
  );

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _bio = '';
  String get bio => _bio;

  String _username = '';
  String get username => _username;

  Future<void> fetchProfileBio() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('profilesbio')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _bio = response['bio'] ?? '';
        _username = response['username'] ?? '';

        await PreferenceService.saveString('bio', _bio);
        await PreferenceService.saveString('username', _username);
      }
    } catch (e) {
      debugPrint('Error fetching profile bio: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBio(String newBio) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    _isLoading = true;
    notifyListeners();

    try {
      await Supabase.instance.client.from('profilesbio').upsert({
        'id': user.id,
        'username': _username.isEmpty ? (user.userMetadata?['name'] ?? user.email?.split('@')[0] ?? 'user') : _username,
        'bio': newBio,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _bio = newBio;
      await PreferenceService.saveString('bio', newBio);
    } catch (e) {
      debugPrint('Error updating bio: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await Supabase.instance.client.auth.signOut();

      await PreferenceService.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error signing out: $e');
      // Even if one fails, clear prefs to force login screen
      await PreferenceService.clear();
      notifyListeners();
    }
  }
}

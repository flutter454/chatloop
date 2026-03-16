import 'package:chatloop/core/models/userdata_profile.dart';
import 'package:chatloop/core/services/sharedpreference.dart';
import 'package:flutter/material.dart';

class DashboardProvider extends ChangeNotifier {
  int _selectedIndex = 0;
  UserProfile? _userProfile;

  int get selectedIndex => _selectedIndex;
  UserProfile? get userProfile => _userProfile;
  String get userEmail => _userProfile?.email ?? '';
  String get userPhotoUrl => _userProfile?.photoUrl ?? '';
  String get userName =>
      (_userProfile?.fullName != null && _userProfile!.fullName.isNotEmpty)
          ? _userProfile!.fullName
          : (_userProfile?.username ?? '');
  String get userBio => _userProfile?.bio ?? '';

  Future<void> setSelectedIndex(int index) async {
    if (_selectedIndex != index) {
      _selectedIndex = index;
      notifyListeners();
      await PreferenceService.saveInt('dashboard_index', index);
    }
  }

  void setUserProfile(UserProfile profile) {
    _userProfile = profile;
    notifyListeners();
  }

  Future<void> refreshUserProfile() async {
    final fullName = PreferenceService.getString('fullName') ?? '';
    final username = PreferenceService.getString('username') ?? '';
    final photoUrl = PreferenceService.getString('photoUrl') ?? '';
    final email = PreferenceService.getString('email') ?? '';
    final bio = PreferenceService.getString('bio') ?? '';

    // Preserve existing fields if available, else load from prefs or default
    final dob = _userProfile?.dob ?? PreferenceService.getString('dob') ?? '';
    final gender =
        _userProfile?.gender ?? PreferenceService.getString('gender') ?? '';
    final instagram =
        _userProfile?.instagram ??
        PreferenceService.getString('instagram') ??
        '';
    final youtube =
        _userProfile?.youtube ?? PreferenceService.getString('youtube') ?? '';

    _userProfile = UserProfile(
      fullName: fullName,
      username: username,
      email: email,
      photoUrl: photoUrl,
      dob: dob,
      gender: gender,
      instagram: instagram,
      youtube: youtube,
      bio: bio,
    );
    notifyListeners();
  }
}

class UserProfile {
  final String fullName;
  final String username;
  final String email;
  final String photoUrl;
  final String dob;
  final String gender;
  final String instagram;
  final String youtube;
  final String bio;

  UserProfile({
    required this.fullName,
    required this.username,
    required this.email,
    required this.photoUrl,
    required this.dob,
    required this.gender,
    required this.instagram,
    required this.youtube,
    required this.bio,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      fullName: map['fullName'] ?? map['full_name'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? map['avatar_url'] ?? '',
      dob: map['dob'] ?? '',
      gender: map['gender'] ?? '',
      instagram: map['instagram'] ?? '',
      youtube: map['youtube'] ?? '',
      bio: map['bio'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'username': username,
      'email': email,
      'photoUrl': photoUrl,
      'dob': dob,
      'gender': gender,
      'instagram': instagram,
      'youtube': youtube,
      'bio': bio,
    };
  }
}

class AuthResponse {
  final String accessToken;
  final UserModel user;
  final bool mustChangePassword;

  // Flag Onboarding (Nullable atau Default Aman)
  final bool profileCompleted;
  final bool faceEnrolled;
  final bool deviceRegistered;
  final bool assignedToRombel;
  final bool canAttend;

  AuthResponse({
    required this.accessToken,
    required this.user,
    required this.mustChangePassword,
    required this.profileCompleted,
    required this.faceEnrolled,
    required this.deviceRegistered,
    required this.assignedToRombel,
    required this.canAttend,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Kita baca role dari object user untuk menentukan fallback
    final role = json['user'] != null ? json['user']['role'] ?? 'mahasiswa' : 'mahasiswa';
    final isDosen = role == 'dosen';

    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
      mustChangePassword: json['must_change_password'] ?? false,

      // PERBAIKAN AKAR MASALAH:
      // Jika field tidak ada dari backend (seperti kasus Dosen),
      // kita berikan default 'true' agar aplikasi menganggap onboarding selesai/di-bypass.
      profileCompleted: json['profile_completed'] ?? isDosen,
      faceEnrolled: json['face_enrolled'] ?? isDosen,
      deviceRegistered: json['device_registered'] ?? isDosen,
      assignedToRombel: json['assigned_to_rombel'] ?? isDosen,
      canAttend: json['can_attend'] ?? isDosen,
    );
  }
}

class UserModel {
  final int id;
  final String email;
  final String role;
  final String namaLengkap;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.namaLengkap,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? 'mahasiswa',
      namaLengkap: json['nama_lengkap'] ?? 'User',
    );
  }
}
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

    // PENTING: backend asli (AuthController::login / registerMahasiswa)
    // membungkus SEMUA flag onboarding di dalam object "onboarding",
    // BUKAN rata di level atas seperti contoh di API_CONTRACT2.md.
    // Dosen tidak punya object ini sama sekali ("onboarding" => null),
    // makanya fallback ke isDosen tetap dipertahankan.
    final onboarding = json['onboarding'] as Map<String, dynamic>? ?? {};

    return AuthResponse(
      accessToken: json['access_token'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
      mustChangePassword: onboarding['must_change_password'] ?? json['user']?['must_change_password'] ?? false,

      profileCompleted: onboarding['profile_completed'] ?? isDosen,
      faceEnrolled: onboarding['face_enrolled'] ?? isDosen,
      deviceRegistered: onboarding['device_registered'] ?? isDosen,
      assignedToRombel: onboarding['assigned_to_rombel'] ?? isDosen,
      canAttend: onboarding['can_attend'] ?? isDosen,
    );
  }
}

class UserModel {
  // Sebelumnya "int id" -- salah, karena Postman mock ngirim angka (1, 10)
  // tapi backend asli pakai UUID string buat semua ID (sama kayak
  // jadwal_id, ruangan_id, dst di seluruh kontrak). Ini penyebab error
  // "type 'String' is not a subtype of type 'int'" pas hookup ke backend
  // asli.
  final String id;
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
    // PENTING: User model di backend TIDAK punya kolom nama_lengkap
    // sendiri -- datanya ada di relasi terpisah "profil_mahasiswa" atau
    // "profil_dosen" (lihat User.php: profilMahasiswa()/profilDosen()).
    // Laravel otomatis nge-nest relasi itu di JSON pakai key snake_case
    // sesuai nama method-nya.
    final profilMahasiswa = json['profil_mahasiswa'] as Map<String, dynamic>?;
    final profilDosen = json['profil_dosen'] as Map<String, dynamic>?;
    final namaDariRelasi = profilMahasiswa?['nama_lengkap'] ?? profilDosen?['nama_lengkap'];

    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'mahasiswa',
      namaLengkap: namaDariRelasi ?? json['nama_lengkap'] ?? 'User',
    );
  }
}
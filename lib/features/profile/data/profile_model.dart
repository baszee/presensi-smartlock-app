class UserProfile {
  final String namaLengkap;
  final String nim;
  final String email;
  final String programStudi;
  final String role;
  final String angkatan; // Tambahan baru

  UserProfile({
    required this.namaLengkap,
    required this.nim,
    required this.email,
    required this.programStudi,
    required this.role,
    required this.angkatan,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      namaLengkap: json['nama_lengkap'] ?? 'Tanpa Nama',
      nim: json['nim'] ?? '-',
      email: json['email'] ?? '-',
      programStudi: json['program_studi'] ?? '-',
      role: json['role'] ?? 'mahasiswa',
      angkatan: json['angkatan']?.toString() ?? '-', // Ambil data angkatan
    );
  }
}
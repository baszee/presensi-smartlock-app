class UserProfile {
  final String namaLengkap;
  final String nim;
  final String email;
  final String programStudi;
  final String role;

  UserProfile({
    required this.namaLengkap,
    required this.nim,
    required this.email,
    required this.programStudi,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      namaLengkap: json['nama_lengkap'] ?? 'Tanpa Nama',
      nim: json['nim'] ?? '-',
      email: json['email'] ?? '-',
      programStudi: json['program_studi'] ?? '-',
      // Kita tebak role dari email jika backend tidak mengirim role
      role: json['role'] ?? (json['email'].toString().contains('dosen') ? 'dosen' : 'mahasiswa'),
    );
  }
}
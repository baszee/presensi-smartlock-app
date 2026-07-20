class UserProfile {
  final String namaLengkap;
  final String email;
  final String role;

  // Field khusus mahasiswa -- '-' default kalau dosen (tidak relevan).
  final String nim;
  final String programStudi;
  final String angkatan;

  // Field khusus dosen -- null default kalau mahasiswa (tidak relevan).
  final String? nidn;
  final String? kodeDosen;
  final String? gelarDepan;
  final String? gelarBelakang;

  UserProfile({
    required this.namaLengkap,
    required this.email,
    required this.role,
    required this.nim,
    required this.programStudi,
    required this.angkatan,
    this.nidn,
    this.kodeDosen,
    this.gelarDepan,
    this.gelarBelakang,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      namaLengkap: json['nama_lengkap'] ?? 'Tanpa Nama',
      email: json['email'] ?? '-',
      role: json['role'] ?? 'mahasiswa',
      nim: json['nim'] ?? '-',
      programStudi: json['program_studi'] ?? '-',
      angkatan: json['angkatan']?.toString() ?? '-',
      nidn: json['nidn'],
      kodeDosen: json['kode_dosen'],
      gelarDepan: json['gelar_depan'],
      gelarBelakang: json['gelar_belakang'],
    );
  }

  bool get isDosen => role == 'dosen';

  /// Nama lengkap dosen dengan gelar depan/belakang dirangkai, dipakai
  /// di header profil. Untuk mahasiswa cukup namaLengkap apa adanya.
  String get namaDenganGelar {
    if (!isDosen) return namaLengkap;
    final depan = (gelarDepan != null && gelarDepan!.trim().isNotEmpty) ? '${gelarDepan!.trim()} ' : '';
    final belakang = (gelarBelakang != null && gelarBelakang!.trim().isNotEmpty) ? ', ${gelarBelakang!.trim()}' : '';
    return '$depan$namaLengkap$belakang';
  }
}
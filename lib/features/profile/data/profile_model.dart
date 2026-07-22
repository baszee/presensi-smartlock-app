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
    // PENTING: backend asli (ProfileController::show) nge-nest data
    // akademik di dalam relasi terpisah -- "profil_mahasiswa" untuk
    // mahasiswa, "profil_dosen" untuk dosen -- BUKAN rata di level atas.
    // Cuma "role" dan "email" yang beneran kolom langsung di User.
    final profilMahasiswa = json['profil_mahasiswa'] as Map<String, dynamic>?;
    final profilDosen = json['profil_dosen'] as Map<String, dynamic>?;

    final namaDariRelasi = profilMahasiswa?['nama_lengkap'] ?? profilDosen?['nama_lengkap'];

    return UserProfile(
      namaLengkap: namaDariRelasi ?? json['nama_lengkap'] ?? 'Tanpa Nama',
      email: json['email'] ?? '-',
      role: json['role'] ?? 'mahasiswa',
      nim: profilMahasiswa?['nim'] ?? '-',
      programStudi: profilMahasiswa?['program_studi'] ?? '-',
      angkatan: profilMahasiswa?['angkatan']?.toString() ?? '-',
      nidn: profilDosen?['nidn'],
      kodeDosen: profilDosen?['kode_dosen'],
      gelarDepan: profilDosen?['gelar_depan'],
      gelarBelakang: profilDosen?['gelar_belakang'],
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
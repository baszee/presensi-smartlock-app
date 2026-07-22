class RiwayatPresensiItem {
  final String id;
  final String sesiKelasId; // dipakai buat cross-reference ke Sesi (lihat
  // sesi_provider.dart) karena backend TIDAK menghitung "sudah_presensi"/
  // "waktu_presensi" per sesi -- kita derive sendiri di mobile dari
  // daftar riwayat ini.
  final String tanggal;
  final String status; // isinya: hadir/telat/ditolak
  final String? waktuPresensi;
  final String namaRombel; // sebelumnya "mataKuliah" -- lihat jadwal_model.dart

  RiwayatPresensiItem({
    required this.id,
    required this.sesiKelasId,
    required this.tanggal,
    required this.status,
    this.waktuPresensi,
    required this.namaRombel,
  });

  factory RiwayatPresensiItem.fromJson(Map<String, dynamic> json) {
    // PENTING (dari audit source code backend, LogAksesPresensi model +
    // MobileMahasiswaController::riwayatPresensi):
    // - Kolom aslinya "waktu" (datetime lengkap tanggal+jam), BUKAN
    //   "tanggal" terpisah dari "waktu_presensi" -- itu satu kolom yang
    //   sama, dipakai untuk kedua tampilan di sini.
    // - "status" aslinya "status_presensi" (isinya: hadir/telat/ditolak).
    // - Tidak ada kolom "mata_kuliah" di manapun -- sistem berbasis
    //   Rombel, jadi kita ambil "nama_rombel" dari relasi bersarang
    //   sesi_kelas.jadwal.rombel (eager-loaded backend: 'sesiKelas.jadwal.rombel').
    final sesiKelas = json['sesi_kelas'] as Map<String, dynamic>?;
    final jadwal = sesiKelas?['jadwal'] as Map<String, dynamic>?;
    final rombel = jadwal?['rombel'] as Map<String, dynamic>?;

    return RiwayatPresensiItem(
      id: json['id']?.toString() ?? '',
      sesiKelasId: json['sesi_kelas_id']?.toString() ?? '',
      tanggal: json['waktu']?.toString() ?? '-',
      status: json['status_presensi'] ?? json['status'] ?? 'hadir',
      waktuPresensi: json['waktu']?.toString(),
      namaRombel: rombel?['nama_rombel'] ?? json['mata_kuliah'] ?? '-',
    );
  }
}

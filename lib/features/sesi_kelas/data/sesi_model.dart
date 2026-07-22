class Sesi {
  final String id;
  final String jadwalId;
  final String tanggal;
  final String status;
  final bool sudahPresensi;
  final String? waktuPresensi; // Bisa null kalau belum presensi
  final String ruanganId;
  final String namaRuangan;

  Sesi({
    required this.id,
    required this.jadwalId,
    required this.tanggal,
    required this.status,
    required this.sudahPresensi,
    this.waktuPresensi,
    required this.ruanganId,
    required this.namaRuangan,
  });

  factory Sesi.fromJson(Map<String, dynamic> json) {
    // PENTING -- ini yang paling krusial dari seluruh audit backend:
    //
    // 1. STATUS: kolom "status" di database CUMA nyimpen 'dijadwalkan'
    //    atau 'batal' (state hasil reschedule/cancel manual dosen).
    //    "berjalan" itu BUKAN kolom database -- itu dihitung REAL-TIME
    //    oleh ClassSessionTimingService berdasarkan jam sekarang vs jam
    //    mulai/selesai sesi, dan dikirim lewat field terpisah bernama
    //    "status_aktual". Field "status" mentah TIDAK PERNAH berubah
    //    jadi "berjalan" walau sesi lagi jalan -- makanya sebelum ini
    //    tombol "Buka Pintu" / kartu "Sesi Berjalan" nggak pernah nyala
    //    walau waktunya udah pas.
    //
    // 2. RUANGAN: tidak ada key "ruangan" langsung di objek sesi. Yang
    //    ada "ruangan_efektif" (ruangan asli ATAU ruangan pengganti kalau
    //    sesi ini di-reschedule ke ruangan lain) -- ini juga dihitung
    //    oleh backend, bukan disimpan mentah.
    final ruanganEfektif = json['ruangan_efektif'] as Map<String, dynamic>?;

    return Sesi(
      id: json['id']?.toString() ?? '',
      jadwalId: json['jadwal_id']?.toString() ?? '',
      tanggal: json['tanggal'] ?? '',
      status: json['status_aktual'] ?? json['status'] ?? 'tidak_diketahui',
      // CATATAN: backend belum punya field ini sama sekali (tidak dihitung
      // di mana pun) -- selalu default false/null dari backend asli.
      // Perlu ditanyakan ke tim backend apa mau ditambahkan, atau app
      // ambil dari GET /riwayat-presensi secara terpisah untuk cek ini.
      sudahPresensi: json['sudah_presensi'] ?? false,
      waktuPresensi: json['waktu_presensi'],
      ruanganId: ruanganEfektif?['id']?.toString() ?? '',
      namaRuangan: ruanganEfektif?['nama_ruangan'] ?? '-',
    );
  }

  /// Dipakai sesiHariIniDenganPresensiProvider (sesi_provider.dart) buat
  /// "menimpa" sudahPresensi/waktuPresensi hasil cross-reference ke
  /// riwayat-presensi, tanpa perlu re-parse dari JSON dari awal.
  Sesi copyWith({bool? sudahPresensi, String? waktuPresensi}) {
    return Sesi(
      id: id,
      jadwalId: jadwalId,
      tanggal: tanggal,
      status: status,
      sudahPresensi: sudahPresensi ?? this.sudahPresensi,
      waktuPresensi: waktuPresensi ?? this.waktuPresensi,
      ruanganId: ruanganId,
      namaRuangan: namaRuangan,
    );
  }
}
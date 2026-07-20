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
    return Sesi(
      id: json['id']?.toString() ?? '',
      jadwalId: json['jadwal_id']?.toString() ?? '',
      tanggal: json['tanggal'] ?? '',
      status: json['status'] ?? 'tidak_diketahui',
      sudahPresensi: json['sudah_presensi'] ?? false,
      waktuPresensi: json['waktu_presensi'],
      // Ambil id + nama ruangan dari dalam nested object
      ruanganId: json['ruangan']?['id']?.toString() ?? '',
      namaRuangan: json['ruangan']?['nama_ruangan'] ?? '-',
    );
  }
}
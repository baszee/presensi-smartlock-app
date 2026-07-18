class RiwayatPresensiItem {
  final String id;
  final String tanggal;
  final String status; // contoh: "hadir"
  final String? waktuPresensi;
  final String mataKuliah;

  RiwayatPresensiItem({
    required this.id,
    required this.tanggal,
    required this.status,
    this.waktuPresensi,
    required this.mataKuliah,
  });

  factory RiwayatPresensiItem.fromJson(Map<String, dynamic> json) {
    return RiwayatPresensiItem(
      id: json['id']?.toString() ?? '',
      tanggal: json['tanggal'] ?? '-',
      status: json['status'] ?? 'hadir',
      waktuPresensi: json['waktu_presensi'],
      // Coba beberapa kemungkinan lokasi field, karena bentuk response
      // riwayat-presensi belum dikonfirmasi 100% dari backend.
      mataKuliah: json['mata_kuliah'] ??
          json['jadwal']?['mata_kuliah'] ??
          json['sesi']?['jadwal']?['mata_kuliah'] ??
          '-',
    );
  }
}
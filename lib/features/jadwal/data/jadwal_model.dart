class Jadwal {
  final String id; // 1. Ubah jadi String karena Postman mengirim "jadwal-uuid-..."
  final String mataKuliah;
  final String jamMulai;
  final String jamSelesai;
  final String ruanganId;
  final String namaRuangan;
  final String namaDosen;
  final int hari;

  Jadwal({
    required this.id,
    required this.mataKuliah,
    required this.jamMulai,
    required this.jamSelesai,
    required this.ruanganId,
    required this.namaRuangan,
    required this.namaDosen,
    required this.hari,
  });

  factory Jadwal.fromJson(Map<String, dynamic> json) {
    // 2. Logika konversi teks "Senin" menjadi angka 1, "Selasa" jadi 2, dst.
    // Supaya filter tab harimu di UI tetap berjalan normal.
    int parsedHari = DateTime.now().weekday;
    if (json['hari'] != null) {
      final hariString = json['hari'].toString().toLowerCase();
      if (hariString == 'senin') {
        parsedHari = 1;
      } else if (hariString == 'selasa') {
        parsedHari = 2;
      } else if (hariString == 'rabu') {
        parsedHari = 3;
      } else if (hariString == 'kamis') {
        parsedHari = 4;
      } else if (hariString == 'jumat') {
        parsedHari = 5;
      }
    }

    return Jadwal(
      // Parsing aman untuk String id
      id: json['id']?.toString() ?? '',

      // Jika backend tidak mengirim mata kuliah, kita kasih nilai default
      mataKuliah: json['mata_kuliah'] ?? 'Mata Kuliah (Data Kosong)',

      jamMulai: json['jam_mulai'] ?? '-',
      jamSelesai: json['jam_selesai'] ?? '-',

      // 3. Mengambil nama_ruangan dari dalam objek "ruangan"
      ruanganId: json['ruangan']?['id']?.toString() ?? '',
      namaRuangan: json['ruangan']?['nama_ruangan'] ?? '-',

      namaDosen: json['nama_dosen'] ?? 'Dosen Belum Ditentukan',

      hari: parsedHari,
    );
  }
}
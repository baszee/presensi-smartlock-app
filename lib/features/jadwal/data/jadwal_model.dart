class Jadwal {
  final String id; // 1. Ubah jadi String karena Postman mengirim "jadwal-uuid-..."
  final String namaRombel; // sebelumnya "mataKuliah" -- lihat catatan di fromJson
  final String jamMulai;
  final String jamSelesai;
  final String ruanganId;
  final String namaRuangan;
  final String namaDosen;
  final int hari;

  Jadwal({
    required this.id,
    required this.namaRombel,
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

      // PENTING (dari audit source code backend, Jadwal model + migration
      // rombel): tidak ada kolom/konsep "mata_kuliah" sama sekali di
      // manapun -- sistem ini didesain seputar "Rombel" (rombongan
      // belajar). Nama-nya ada di relasi "rombel.nama_rombel", bukan rata
      // di jadwal itu sendiri.
      namaRombel: json['rombel']?['nama_rombel'] ?? 'Rombel (Data Kosong)',

      jamMulai: json['jam_mulai'] ?? '-',
      jamSelesai: json['jam_selesai'] ?? '-',

      // 3. Mengambil nama_ruangan dari dalam objek "ruangan"
      ruanganId: json['ruangan']?['id']?.toString() ?? '',
      namaRuangan: json['ruangan']?['nama_ruangan'] ?? '-',

      // PENTING: endpoint GET /mobile/mahasiswa/jadwal (lihat
      // MobileMahasiswaController::jadwal) HANYA eager-load relasi
      // "rombel" & "ruangan" -- TIDAK ada "dosenPic" sama sekali, dan
      // rombel itu sendiri cuma expose "id"+"nama_rombel" (dosen_pic_id
      // memang ada tapi raw FK, tanpa nama). Jadi field ini SELALU
      // fallback ke default di bawah untuk saat ini -- backend belum
      // menyediakan nama dosen di endpoint ini. Perlu diminta ke backend
      // dev untuk nambahin eager-load 'rombel.dosenPic' kalau nama dosen
      // memang mau ditampilkan di layar jadwal mahasiswa.
      namaDosen: json['nama_dosen'] ?? json['rombel']?['dosen_pic']?['profil_dosen']?['nama_lengkap'] ?? 'Dosen Belum Ditentukan',

      hari: parsedHari,
    );
  }
}
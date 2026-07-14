import 'jadwal_model.dart';
import 'jadwal_repository.dart';

/// Implementasi sementara dari JadwalRepository.
/// Mengembalikan data palsu (dummy), dipakai selama backend/API
/// belum tersedia. Nanti tinggal diganti ke ApiJadwalRepository
/// tanpa mengubah kode UI sama sekali.
class DummyJadwalRepository implements JadwalRepository {
  @override
  Future<List<Jadwal>> getJadwalHariIni() async {
    // Simulasi delay seperti kalau lagi manggil API asli
    await Future.delayed(const Duration(milliseconds: 500));

    return const [
      Jadwal(
        id: '1',
        mataKuliah: 'Pemrograman Mobile',
        namaRuangan: 'Ruang A101',
        namaDosen: 'Dr. Budi Santoso',
        jamMulai: '08:00',
        jamSelesai: '10:30',
        hari: 4, // Kamis
      ),
      Jadwal(
        id: '2',
        mataKuliah: 'Basis Data',
        namaRuangan: 'Ruang B203',
        namaDosen: 'Dr. Siti Aminah',
        jamMulai: '13:00',
        jamSelesai: '15:30',
        hari: 4,
      ),
    ];
  }

  @override
  Future<List<Jadwal>> getSemuaJadwal() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return getJadwalHariIni(); // sementara sama aja datanya
  }
}
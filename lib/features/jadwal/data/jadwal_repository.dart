import 'jadwal_model.dart';

/// Ini adalah "kontrak" — aturan bahwa siapa pun yang mau jadi
/// sumber data Jadwal (dummy, API asli, dll) HARUS punya fungsi ini.
/// UI (JadwalScreen) nanti hanya bicara dengan kontrak ini,
/// tidak peduli implementasi aslinya dari mana.
abstract class JadwalRepository {
  /// Mengambil daftar jadwal hari ini untuk user yang sedang login.
  Future<List<Jadwal>> getJadwalHariIni();

  /// Mengambil semua jadwal (tidak difilter per hari).
  Future<List<Jadwal>> getSemuaJadwal();
}
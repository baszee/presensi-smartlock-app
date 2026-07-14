import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/jadwal_model.dart';
import '../data/jadwal_repository.dart';
import '../data/dummy_jadwal_repository.dart';

final jadwalRepositoryProvider = Provider<JadwalRepository>((ref) {
  return DummyJadwalRepository();
});

/// Provider ini menyimpan hari mana yang lagi dipilih di tab.
/// 1 = Senin, 2 = Selasa, ... 7 = Minggu (sesuai ERD: hari int)
/// Default-nya kita isi hari ini (disesuaikan biar match angka ERD).
final selectedHariProvider = StateProvider<int>((ref) {
  final today = DateTime.now().weekday; // 1 = Senin ... 7 = Minggu
  return today;
});

/// Provider untuk mengambil SEMUA jadwal (dipakai di Jadwal screen,
/// nanti difilter per hari di UI).
final semuaJadwalProvider = FutureProvider<List<Jadwal>>((ref) async {
  final repository = ref.watch(jadwalRepositoryProvider);
  return repository.getSemuaJadwal();
});

/// Provider khusus Home screen: jadwal hari ini saja.
final jadwalHariIniProvider = FutureProvider<List<Jadwal>>((ref) async {
  final repository = ref.watch(jadwalRepositoryProvider);
  return repository.getJadwalHariIni();
});
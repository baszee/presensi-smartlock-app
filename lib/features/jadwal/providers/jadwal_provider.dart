import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/jadwal_model.dart';
import '../data/jadwal_repository.dart';

// 1. Provider untuk menyimpan status hari apa yang di-klik user (Default: Hari ini)
final selectedHariProvider = StateProvider<int>((ref) {
  int hariIni = DateTime.now().weekday;
  // Karena tab UI cuma Senin(1) - Jumat(5), kalau Sabtu/Minggu, paksa ke Senin
  if (hariIni > 5) hariIni = 1;
  return hariIni;
});

// 2. Provider untuk mengambil SEMUA JADWAL dari API
final semuaJadwalProvider = FutureProvider<List<Jadwal>>((ref) async {
  final repository = ref.watch(jadwalRepositoryProvider);
  return repository.getJadwal();
});

// 3. Provider KHUSUS untuk HOME SCREEN (hanya menampilkan jadwal hari ini)
final jadwalHariIniProvider = FutureProvider<List<Jadwal>>((ref) async {
  final semuaJadwal = await ref.watch(semuaJadwalProvider.future);
  final hariIni = DateTime.now().weekday;

  // Filter cuma yang harinya sama dengan hari ini
  return semuaJadwal.where((jadwal) => jadwal.hari == hariIni).toList();
});
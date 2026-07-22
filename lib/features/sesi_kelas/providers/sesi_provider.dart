import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../../riwayat_presensi/providers/riwayat_provider.dart';
import '../data/sesi_model.dart';

// 1. Provider untuk mengontrol header Postman (Default: Belum Presensi)
final mockSesiHeaderProvider = StateProvider<String>((ref) {
  return 'Sesi Aktif - Belum Presensi';
});

// 2. Provider untuk mengambil data Sesi dari API
final sesiHariIniProvider = FutureProvider<List<Sesi>>((ref) async {
  final dio = ref.watch(dioClientProvider);
  final headerName = ref.watch(mockSesiHeaderProvider); // Ambil nama header saat ini

  try {
    final response = await dio.get(
      '/mobile/mahasiswa/sesi',
      options: Options(
        headers: {
          // Trik andalanmu masuk di sini! (cuma aktif kalau mock nyala)
          if (AppConfig.useMockBackend) 'x-mock-response-name': headerName,
        },
      ),
    );

    // Bedah JSON-nya
    List<dynamic> rawData = [];
    if (response.data is List) {
      rawData = response.data;
    } else if (response.data is Map && response.data['data'] != null) {
      rawData = response.data['data'];
    }

    return rawData.map((json) => Sesi.fromJson(json)).toList();

  } catch (e) {
    appLogger.e('❌ ERROR FETCH SESI: $e');
    throw 'Gagal memuat sesi kelas.';
  }
});

/// PENTING: backend TIDAK menghitung "sudah_presensi"/"waktu_presensi" per
/// sesi sama sekali (dicek langsung ke source code -- tidak ada field ini
/// di GET /mobile/mahasiswa/sesi maupun service manapun). Provider ini
/// menghitungnya sendiri di mobile: ambil daftar sesi + daftar riwayat
/// presensi, lalu cocokkan lewat "sesi_kelas_id" -- kalau ada log dengan
/// status "hadir"/"telat" untuk sesi itu, berarti sudah presensi.
///
/// home_screen.dart pakai provider INI, bukan sesiHariIniProvider mentah.
final sesiHariIniDenganPresensiProvider = FutureProvider<List<Sesi>>((ref) async {
  final sesiList = await ref.watch(sesiHariIniProvider.future);
  final riwayatList = await ref.watch(riwayatPresensiProvider.future);

  return sesiList.map((sesi) {
    final logPresensi = riwayatList.where(
          (r) => r.sesiKelasId == sesi.id && (r.status == 'hadir' || r.status == 'telat'),
    );

    if (logPresensi.isEmpty) return sesi;

    final log = logPresensi.first;
    return sesi.copyWith(sudahPresensi: true, waktuPresensi: log.waktuPresensi);
  }).toList();
});
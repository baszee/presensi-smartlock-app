import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/app_logger.dart';
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
          // Trik andalanmu masuk di sini!
          'x-mock-response-name': headerName,
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
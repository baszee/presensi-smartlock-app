import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/app_logger.dart'; // Tambahkan logger
import 'jadwal_model.dart';

class JadwalRepository {
  final Dio _dio;

  JadwalRepository(this._dio);

  Future<List<Jadwal>> getJadwal() async {
    try {
      final response = await _dio.get('/mobile/mahasiswa/jadwal');

      // 1. KITA PRINT DULU ISI ASLINYA
      appLogger.w('📦 ISI RESPONSE JADWAL POSTMAN: ${response.data}');

      // 2. SAFE CHECK (Mencegah layar merah kalau response null)
      if (response.data == null) {
        throw 'Data dari server kosong (null)';
      }

      // 3. LOGIKA PARSING AMAN
      List<dynamic> rawData = [];

      if (response.data is Map<String, dynamic>) {
        // Kalau bentuknya { "data": [...] }
        rawData = response.data['data'] ?? [];
      } else if (response.data is List) {
        // Kalau bentuknya langsung [...]
        rawData = response.data;
      }

      // Ubah JSON menjadi object Jadwal
      return rawData.map((json) => Jadwal.fromJson(json)).toList();

    } catch (e, stacktrace) {
      // Print error spesifiknya ke console biar ketahuan salahnya di mana
      appLogger.e('❌ ERROR PARSING JADWAL: $e\n$stacktrace');
      throw 'Gagal memuat jadwal. Cek Console!';
    }
  }
}

final jadwalRepositoryProvider = Provider<JadwalRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return JadwalRepository(dio);
});
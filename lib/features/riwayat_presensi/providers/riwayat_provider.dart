import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../data/riwayat_model.dart';

final riwayatPresensiProvider = FutureProvider.autoDispose<List<RiwayatPresensiItem>>((ref) async {
  final dio = ref.watch(dioClientProvider);

  try {
    final response = await dio.get('/mobile/mahasiswa/riwayat-presensi');
    final responseData = response.data;

    List<dynamic> rawData = [];
    if (responseData is List) {
      rawData = responseData;
    } else if (responseData is Map && responseData['data'] != null) {
      rawData = responseData['data'];
    }

    return rawData.map((json) => RiwayatPresensiItem.fromJson(json)).toList();
  } catch (e) {
    appLogger.e('❌ ERROR FETCH RIWAYAT PRESENSI: $e');
    // Kalau gagal/kosong, jangan bikin error total di UI — anggap kosong saja.
    return [];
  }
});
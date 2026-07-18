import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/app_logger.dart';
// Sesuaikan jika nama file dart-nya berbeda, tapi biasanya ini benar:
import '../data/sesi_model.dart';

// Provider ini khusus memanggil API GET /mobile/dosen/sesi
final sesiDosenProvider = FutureProvider.autoDispose<List<Sesi>>((ref) async {
  final dio = ref.watch(dioClientProvider);

  try {
    final response = await dio.get(
      '/mobile/dosen/sesi',
      options: Options(
        headers: {
          'x-mock-response-name': 'Sesi Dosen',
        },
      ),
    );

    appLogger.i('📦 JSON Sesi Dosen: ${response.data}');

    final responseData = response.data;
    List<dynamic> dataList = [];

    if (responseData is List) {
      dataList = responseData; // Jika Postman mengirim Array [...]
    } else if (responseData is Map) {
      if (responseData.containsKey('data')) {
        dataList = responseData['data']; // Jika ada bungkus { "data": [...] }
      } else {
        // PERBAIKANNYA DI SINI:
        // Jika Postman mengirim Objek langsung {...}, kita bungkus jadi Array
        dataList = [responseData];
      }
    }

    // Mapping dari JSON ke Sesi (SESUAI DENGAN CLASS MILIKMU)
    return dataList.map((json) => Sesi.fromJson(json)).toList();

  } on DioException catch (e) {
    appLogger.e('Gagal memuat sesi dosen', error: e);
    throw e.response?.data['message'] ?? 'Koneksi ke server gagal.';
  } catch (e) {
    appLogger.e('Terjadi kesalahan parsing', error: e);
    throw 'Terjadi kesalahan sistem.';
  }
});
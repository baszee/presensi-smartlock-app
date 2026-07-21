import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/dio_provider.dart';
import '../data/jadwal_model.dart';

// 1. Provider untuk menyimpan status Hari yang sedang dipilih (Default: Selasa)
final selectedHariDosenProvider = StateProvider.autoDispose<String>((ref) => 'Selasa');

// 2. Provider untuk mengambil JSON Jadwal Dosen dari Postman
final jadwalDosenProvider = FutureProvider.autoDispose<List<Jadwal>>((ref) async {
  final dio = ref.watch(dioClientProvider);

  try {
    final response = await dio.get(
      '/mobile/dosen/jadwal', // Pastikan endpoint di Postman-mu seperti ini
      options: Options(
        headers: {
          if (AppConfig.useMockBackend) 'x-mock-response-name': 'Jadwal Dosen', // Harus sama persis dengan nama Example
        },
      ),
    );

    final responseData = response.data;
    List<dynamic> dataList = [];

    // Logika kebal (Safe Check) seperti yang kita pakai di Sesi
    if (responseData is List) {
      dataList = responseData;
    } else if (responseData is Map) {
      if (responseData.containsKey('data')) {
        dataList = responseData['data'];
      } else {
        dataList = [responseData];
      }
    }

    // Ubah JSON menjadi List of object Jadwal
    return dataList.map((json) => Jadwal.fromJson(json)).toList();

  } catch (e) {
    throw 'Gagal memuat jadwal dosen: $e';
  }
});
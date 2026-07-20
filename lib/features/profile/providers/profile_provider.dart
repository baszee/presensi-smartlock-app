import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../data/profile_model.dart';

/// Provider ini dipakai BERSAMA oleh mahasiswa dan dosen (satu endpoint
/// GET /user untuk semua role). Bedanya cuma header mock yang dikirim,
/// supaya Postman tau harus balikin Example mana.
final profileProvider = FutureProvider<UserProfile>((ref) async {
  final dio = ref.watch(dioClientProvider);

  try {
    const storage = FlutterSecureStorage();
    final role = await storage.read(key: 'user_role');

    final response = await dio.get(
      '/user',
      options: Options(
        headers: {
          // Perlu Example baru di Postman bernama persis "Profile Aktif Dosen"
          // untuk GET /user, isinya data dosen (nidn, kode_dosen, gelar, dst).
          if (role == 'dosen') 'x-mock-response-name': 'Profile Aktif Dosen',
        },
      ),
    );

    final data = response.data['data'] ?? response.data;
    if (data == null) throw 'Data profil kosong';

    return UserProfile.fromJson(data);
  } catch (e) {
    appLogger.e('❌ ERROR FETCH PROFILE: $e');
    throw 'Gagal memuat profil.';
  }
});
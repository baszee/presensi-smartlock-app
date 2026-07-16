import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/utils/app_logger.dart';
import '../data/profile_model.dart';

final profileProvider = FutureProvider<UserProfile>((ref) async {
  final dio = ref.watch(dioClientProvider);

  try {
    final response = await dio.get('/user');

    // Safe check seperti di jadwal
    final data = response.data['data'] ?? response.data;

    if (data == null) throw 'Data profil kosong';

    return UserProfile.fromJson(data);
  } catch (e) {
    appLogger.e('❌ ERROR FETCH PROFILE: $e');
    throw 'Gagal memuat profil.';
  }
});
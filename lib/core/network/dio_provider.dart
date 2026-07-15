import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dio_client.dart';

// Provider untuk Secure Storage agar bersifat singleton (hanya dibuat 1 kali)
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Provider utama untuk Dio yang akan dipakai di seluruh repository
final dioClientProvider = Provider<Dio>((ref) {
  // Ambil instance secure storage dari provider di atas
  final secureStorage = ref.watch(secureStorageProvider);

  // Masukkan ke dalam DioClient, lalu kembalikan objek dio-nya
  return DioClient(secureStorage).dio;
});
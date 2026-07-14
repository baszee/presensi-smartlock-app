import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dio_client.dart';

/// Provider ini menyediakan satu instance DioClient yang sama
/// untuk dipakai di seluruh aplikasi.
/// Cara pakai nanti: `ref.watch(dioClientProvider)`
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});
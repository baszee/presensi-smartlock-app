import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_role.dart';

/// SEMENTARA: role di-hardcode di sini dulu, karena Login belum dibuat.
/// Nanti setelah Login jadi, provider ini akan membaca role dari hasil
/// login user yang sebenarnya (misal dari token/response API),
/// bukan nilai tetap seperti sekarang.
///
/// Ganti nilai di bawah ini secara manual untuk mencoba tampilan
/// Dosen vs Mahasiswa selama development.
final currentUserRoleProvider = Provider<UserRole>((ref) {
  return UserRole.mahasiswa; // ganti ke UserRole.dosen untuk coba tampilan Dosen
});